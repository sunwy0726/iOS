import Foundation
import Starscream

public enum HAWebSocketGlobalConfig {
    public static var log: (String) -> Void = { print($0) }
}

public protocol HAWebSocketDelegate: AnyObject {
    func webSocket(_ webSocket: HAWebSocket, fetchAccessTokenCalling completionHandler: (Result<String, Error>) -> Void)
}

public enum HAWebSocketError: Error {
    public enum ResponseError: Error {
        case parseError(Error?)
        case unknownType(String)
        case response(error: (Int, String)?)
    }

    case parseError(Error)
    case responseError(ResponseError)
}

public typealias HAWebSocketDataHandler = (Result<HAWebSocketData, HAWebSocketError>) -> Void
internal class HAWebSocketDataHandlerContainer {
    private var handler: HAWebSocketDataHandler?
    init(handler: @escaping HAWebSocketDataHandler) {
        self.handler = handler
    }

    func resolve(_ result: Result<HAWebSocketData, HAWebSocketError>) {
        if let handler = handler {
            handler(result)
        }

        handler = nil
    }
}

public class HAWebSocket: WebSocketDelegate {
    internal var callbackQueue: DispatchQueue = .main
    internal let connection: WebSocket

    public weak var delegate: HAWebSocketDelegate?

    enum Phase {
        case disconnected
        case auth
        case command
    }

    enum PhaseTransitionError: Error {
        case disconnected
    }

    private var phase: Phase = .disconnected {
        didSet {
            HAWebSocketGlobalConfig.log("phase transition to \(phase)")

            switch phase {
            case .auth:
                break
            case .disconnected:
                discardActiveItems()
            case .command:
                applyPendingItems()
            }
        }
    }

    init(delegate: HAWebSocketDelegate) {
        self.dataQueue = DispatchQueue(label: "websocket-api-data")

        self.delegate = delegate
        self.connection = WebSocket(request: URLRequest(url: URL(string: "http://127.0.0.1:8123/api/websocket")!))
        connection.delegate = self
        connection.callbackQueue = dataQueue

        // xxx test
        _ = subscribe(to: nil) { registration, event in
            print("*** \(registration) received \(event)")
        }

        send(.init(type: .getConfig, data: [:])) { result in
            print("*** get_config: \(result)")
        }
        // xxx test

        connection.connect()
    }

    public func send(_ request: HAWebSocketRequest, completion: @escaping HAWebSocketDataHandler) {
        HAWebSocketGlobalConfig.log("enqueue request \(request)")
        dataQueue.async { [self] in
            pendingRequests.append(.init(request: request, completion: completion))
        }
    }

    public func subscribe(
        to event: HAWebSocketEventType?,
        handler: @escaping HAWebSocketEventHandler
    ) -> HAWebSocketEventRegistration {
        HAWebSocketGlobalConfig.log("subscribe to \(event?.rawValue ?? "(all)")")

        let registration = HAWebSocketEventRegistration(
            type: event,
            handler: handler
        )

        dataQueue.async { [self] in
            eventRegistrations.append(registration)
        }

        return registration
    }

    public func unsubscribe(
        _ registration: HAWebSocketEventRegistration
    ) {
        HAWebSocketGlobalConfig.log("unsubscribe \(registration)")

        dataQueue.async { [self] in
            if let identifier = registration.subscriptionIdentifier {
                eventRegistrations.removeAll(where: { $0 == registration })
                activeEventRegistrations[identifier] = nil
                registration.subscriptionIdentifier = nil

                sendInternal(request: .init(type: .unsubscribeEvents, data: [
                    "subscription": identifier.rawValue,
                ])) { result in
                    HAWebSocketGlobalConfig.log("end \(registration): \(result)")
                }
            } else {
                eventRegistrations.removeAll(where: { $0 == registration })
                HAWebSocketGlobalConfig.log("ended non-pending \(registration)")
            }
        }
    }

    private func sendInternal(
        forcedIdentifier: HAWebSocketRequestIdentifier? = nil,
        request: HAWebSocketRequest,
        completion: @escaping HAWebSocketDataHandler
    ) {
        dispatchPrecondition(condition: .onQueue(dataQueue))

        HAWebSocketGlobalConfig.log("send \(request)")

        let identifier = forcedIdentifier ?? identifiers.next()
        let container = HAWebSocketDataHandlerContainer(handler: completion)
        activeRequests[identifier] = container

        var data = request.data
        data["id"] = identifier.rawValue
        data["type"] = request.type.rawValue

        sendRaw(data) { result in
            switch result {
            case .success: break
            case let .failure(error): container.resolve(.failure(error))
            }
        }
    }

    private func sendRaw(_ dictionary: [String: Any], completion: @escaping (Result<Void, HAWebSocketError>) -> Void) {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            connection.write(string: String(data: data, encoding: .utf8) ?? "", completion: {
                completion(.success(()))
            })
        } catch {
            completion(.failure(.parseError(error)))
        }
    }

    private func discardActiveItems() {
        for registration in eventRegistrations {
            registration.subscriptionIdentifier = nil
        }
        for request in pendingRequests {
            request.requestIdentifier = nil
        }
        activeEventRegistrations.removeAll()
        activeRequests.removeAll()
    }

    private func applyPendingItems() {
        dispatchPrecondition(condition: .onQueue(dataQueue))

        guard phase == .command else {
            HAWebSocketGlobalConfig.log("not applying pending items because phase is \(phase)")
            return
        }

        for registration in eventRegistrations where registration.subscriptionIdentifier == nil {
            var data: [String: Any] = [:]

            if let type = registration.type {
                data["event_type"] = type.rawValue
            }

            let identifier = identifiers.next()
            registration.subscriptionIdentifier = identifier

            HAWebSocketGlobalConfig.log("reconnecting \(registration)")

            sendInternal(
                forcedIdentifier: identifier,
                request: .init(type: .subscribeEvents, data: data),
                completion: { [self] result in
                dataQueue.async { [self] in
                    switch result {
                    case .success: activeEventRegistrations[identifier] = registration
                    case let .failure(error):
                        HAWebSocketGlobalConfig.log("failed to subscribe \(registration): \(error)")
                        registration.subscriptionIdentifier = nil
                    }
                }
            })
        }

        for request in pendingRequests where request.requestIdentifier == nil {
            let identifier = identifiers.next()
            request.requestIdentifier = identifier

            HAWebSocketGlobalConfig.log("sending request \(request)")

            sendInternal(forcedIdentifier: identifier, request: request.request) { result in
                request.resolve(result)
            }
        }
    }

    private enum HandleError: Error {
        case missingKey(String)
        case responseErrorUnknown
        case responseError(code: Int, message: String)
    }

    private func handle(response: [String: Any]) throws {
        HAWebSocketGlobalConfig.log("received \(response)")

        switch try HAWebSocketResponse(dictionary: response) {
        case let .result(identifier: identifier, data: result):
            if let resolver = activeRequests[identifier] {
                activeRequests[identifier] = nil
                callbackQueue.async {
                    resolver.resolve(result)
                }
            } else {
                HAWebSocketGlobalConfig.log("no resolver for response \(identifier)")
            }
        case let .event(identifier: identifier, event: event):
            if let registration = activeEventRegistrations[identifier] {
                callbackQueue.async {
                    registration.fire(event)
                }
            } else {
                HAWebSocketGlobalConfig.log("no handler for event \(event)")
            }
        case let .auth(authState):
            switch authState {
            case .required, .invalid:
                delegate?.webSocket(self, fetchAccessTokenCalling: { [self] result in
                    switch result {
                    case let .success(token):
                        sendRaw([
                            "type": "auth",
                            "access_token": token,
                        ], completion: { result in
                            switch result {
                            case .success: HAWebSocketGlobalConfig.log("auth token sent")
                            case let .failure(error):
                                HAWebSocketGlobalConfig.log("couldn't send auth token, disconnecting")
                                connection.disconnect(closeCode: CloseCode.goingAway.rawValue)
                            }
                        })
                    case let .failure(error):
                        HAWebSocketGlobalConfig.log("couldn't retrieve auth token, disconnecting")
                        connection.disconnect(closeCode: CloseCode.goingAway.rawValue)
                    }
                })
            case .ok:
                phase = .command
            }
        }
    }

    private struct IdentifierGenerator {
        private var lastIdentifierInteger = 0

        mutating func next() -> HAWebSocketRequestIdentifier {
            lastIdentifierInteger += 1
            return .init(rawValue: lastIdentifierInteger)
        }
    }

    private var identifiers = IdentifierGenerator() {
        willSet {
            dispatchPrecondition(condition: .onQueue(dataQueue))
        }
    }

    private var pendingRequests = [HAWebSocketPendingRequest]() {
        willSet {
            dispatchPrecondition(condition: .onQueue(dataQueue))
        }
        didSet {
            applyPendingItems()
        }
    }

    private var eventRegistrations = [HAWebSocketEventRegistration]() {
        willSet {
            dispatchPrecondition(condition: .onQueue(dataQueue))
        }
        didSet {
            applyPendingItems()
        }
    }

    private var activeRequests = [HAWebSocketRequestIdentifier: HAWebSocketDataHandlerContainer]() {
        willSet {
            dispatchPrecondition(condition: .onQueue(dataQueue))
        }
    }

    private var activeEventRegistrations = [HAWebSocketRequestIdentifier: HAWebSocketEventRegistration]() {
        willSet {
            dispatchPrecondition(condition: .onQueue(dataQueue))
        }
    }

    private let dataQueue: DispatchQueue

    public func didReceive(event: Starscream.WebSocketEvent, client: WebSocket) {
        switch event {
        case let .connected(headers):
            HAWebSocketGlobalConfig.log("connected with headers: \(headers)")
            phase = .auth
        case let .disconnected(reason, code):
            HAWebSocketGlobalConfig.log("disconnected: \(reason) with code: \(code)")
            phase = .disconnected
        case let .text(string):
            print("Received text: \(string)")
            if let data = string.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                _ = try? handle(response: json)
            }
        case let .binary(data):
            print("Received binary data: \(data.count)")
        case .ping, .pong:
            break
        case .reconnectSuggested:
            break
        case .viabilityChanged:
            break
        case .cancelled:
            phase = .disconnected
        case let .error(error):
            HAWebSocketGlobalConfig.log("connection error: \(String(describing: error))")
            phase = .disconnected
        }
    }
}
