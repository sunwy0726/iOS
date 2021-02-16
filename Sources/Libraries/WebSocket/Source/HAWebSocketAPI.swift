import Starscream

public enum HAWebSocketGlobalConfig {
    public static var log: (String) -> Void = { print($0) }
}

class HARequestTokenImpl: HARequestToken {
    var handler: (() -> Void)?

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    func cancel() {
        handler?()
        handler = nil
    }
}

public class HAWebSocketAPI: HAWebSocket {
    public weak var delegate: HAWebSocketDelegate?
    public var configuration: HAWebSocketConfiguration

    public var callbackQueue: DispatchQueue = .main
    public var state: HAWebSocketState = .connecting

    private var connection: WebSocket? {
        didSet {
            connection?.delegate = responseController
        }
    }
    private let requestController = HAWebSocketRequestController()
    private let responseController = HAWebSocketResponseController()

    public required init(configuration: HAWebSocketConfiguration) {
        self.configuration = configuration
        requestController.delegate = self
        responseController.delegate = self
    }

    public func connect() {
        let connectionInfo = configuration.connectionInfo()
        let request = URLRequest(url: connectionInfo.url)

        let createdConnection: WebSocket

        if let connection = connection {
            createdConnection = connection
        } else {
            createdConnection = WebSocket(request: request)
        }

        if createdConnection.request.url != request.url {
            createdConnection.request = request
        }

        createdConnection.connect()
    }

    public func disconnect() {
        connection?.delegate = nil
        connection?.disconnect(closeCode: CloseCode.goingAway.rawValue)
        connection = nil
    }

    public func disconnectTemporarily() {
        disconnect()
    }

    public func send(_ request: HAWebSocketRequest, completion: @escaping RequestCompletion) -> HARequestToken {
        let invocation = HAWebSocketRequestInvocation(request: request, completion: completion)
        requestController.add(invocation)
        return HARequestTokenImpl { [requestController] in
            requestController.cancel(invocation)
        }
    }

    public func subscribe(to request: HAWebSocketRequest, handler: @escaping SubscriptionHandler) -> HARequestToken {
        let subscription = HAWebSocketSubscription(request: request, handler: handler)
        requestController.add(subscription)
        return HARequestTokenImpl { [requestController] in
            requestController.cancel(subscription)
        }
    }

    public func subscribe(
        to event: HAWebSocketEventType,
        handler: @escaping EventSubscriptionHandler
    ) -> HARequestToken {
        let request = HAWebSocketRequest(type: .subscribeEvents, data: {
            if let type = event.rawValue {
                return ["event_type": type]
            } else {
                return [:]
            }
        }())

        return subscribe(to: request) { token, data in
            if case let .dictionary(value) = data {
                handler(token, HAWebSocketEvent(dictionary: value))
            }
        }
    }
}

extension HAWebSocketAPI {
    private func sendRaw(_ dictionary: [String: Any], completion: @escaping (Result<Void, HAWebSocketError>) -> Void) {
        guard let connection = connection else {
            preconditionFailure("cannot send commands without a connection")
            return
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            connection.write(string: String(data: data, encoding: .utf8) ?? "", completion: {
                completion(.success(()))
            })
        } catch {

            completion(.failure(.init(type: .internal(debugDescription: error.localizedDescription))))
        }
    }
}

extension HAWebSocketAPI: HAWebSocketResponseControllerDelegate {
    func responseController(_ responseController: HAWebSocketResponseController, didReceive response: HAWebSocketResponse) {
        switch response {
        case let .auth(authState):
            switch authState {
            case .required:
                configuration.fetchAuthToken { [self] result in
                    switch result {
                    case .success(let token):
                        sendRaw([
                            "type": "auth",
                            "access_token": token,
                        ], completion: { result in
                            switch result {
                            case .success: HAWebSocketGlobalConfig.log("auth token sent")
                            case let .failure(error):
                                HAWebSocketGlobalConfig.log("couldn't send auth token, disconnecting")
                                disconnectTemporarily()
                            }
                        })
                    case .failure(let error):
                        HAWebSocketGlobalConfig.log("delegate failed to provide access token, bailing")
                        disconnectTemporarily()
                    }
                }
            case .invalid: break
            case .ok: break
            }
        case let .event(identifier: identifier, data: data):
            if let subscription = requestController.subscription(for: identifier) {
                callbackQueue.async { [self] in
                    subscription.fire(token: HARequestTokenImpl { [requestController] in
                        requestController.cancel(subscription)
                    }, event: data)
                }
            } else {
                HAWebSocketGlobalConfig.log("unable to find registration for event identifier \(identifier)")
                // TODO: send unsubscribe
            }
        case let .result(identifier: identifier, result: result):
            if let request = requestController.request(for: identifier) {
                callbackQueue.async {
                    request.resolve(result)
                }
            } else {
                HAWebSocketGlobalConfig.log("unable to find request for identifier \(identifier)")
            }
        }
    }

    func responseController(_ responseController: HAWebSocketResponseController, didTransitionTo phase: HAWebSocketResponseController.Phase) {
        switch phase {
        case .disconnected: requestController.resetActive()
        case .auth: break
        case .command: requestController.prepare()
        }
    }
}

extension HAWebSocketAPI: HAWebSocketRequestControllerDelegate {
    func requestController(
        _ requestController: HAWebSocketRequestController,
        didPrepareRequest request: HAWebSocketRequest,
        with identifier: HAWebSocketRequestIdentifier
    ) {
        var data = request.data
        data["id"] = identifier.rawValue
        data["type"] = request.type.rawValue

        sendRaw(data) { result in

        }
    }
}
