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
    public weak var connectionDelegate: HAWebSocketConnectionDelegate?
    public weak var authDelegate: HAWebSocketAuthDelegate?

    public var callbackQueue: DispatchQueue = .main
    public var state: HAWebSocketState = .connecting

    private var connection: WebSocket? {
        didSet {
            connection?.delegate = responseController
        }
    }
    private let requestController = HAWebSocketRequestController()
    private let responseController = HAWebSocketResponseController()

    public init() {
        responseController.delegate = self
    }

    public func connect() {

    }

    public func disconnect() {
        //
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

extension HAWebSocketAPI: HAWebSocketResponseControllerDelegate {
    func connection(_ connection: HAWebSocketResponseController, didReceive response: HAWebSocketResponse) {
        switch response {
        case let .auth(authState):
            switch authState {
            case .invalid: break
            case .required: break
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

    func connection(_ connection: HAWebSocketResponseController, didTransitionTo phase: HAWebSocketResponseController.Phase) {

    }
}
