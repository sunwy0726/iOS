import Foundation

public struct HAWebSocketConnectionInfo {
    public init(url: URL) {
        self.url = url
    }

    public var url: URL
}

public struct HAWebSocketConfiguration {
    public init(
        connectionInfo: @escaping () -> HAWebSocketConnectionInfo,
        fetchAuthToken: @escaping ((Result<String, Error>) -> Void) -> Void
    ) {
        self.connectionInfo = connectionInfo
        self.fetchAuthToken = fetchAuthToken
    }

    public var connectionInfo: () -> HAWebSocketConnectionInfo
    public var fetchAuthToken: (_ completion: (Result<String, Error>) -> Void) -> Void
}

public protocol HAWebSocketDelegate: AnyObject {
    func webSocket(_ webSocket: HAWebSocket, connectionTransitionedTo state: HAWebSocketState)
}

public enum HAWebSocketState {
    public enum DisconnectReason {
        case initial
        case error(HAWebSocketError)
        case waitingToReconnect(atLatest: Date, retryCount: Int)
    }

    case disconnected(reason: DisconnectReason)
    case connecting
    case ready(version: String)
}

public protocol HARequestToken {
    func cancel()
}

public enum HAWebSocket {
    public static var API: HAWebSocketProtocol.Type { HAWebSocketAPI.self }
    public static func api(configuration: HAWebSocketConfiguration) -> HAWebSocketProtocol {
        HAWebSocketAPI(configuration: configuration)
    }
}

public protocol HAWebSocketProtocol: AnyObject {
    typealias RequestCompletion = (Result<HAWebSocketData, HAWebSocketError>) -> Void
    typealias SubscriptionHandler = (HARequestToken, HAWebSocketData) -> Void
    typealias EventSubscriptionHandler = (HARequestToken, HAWebSocketEvent) -> Void

    var delegate: HAWebSocketDelegate? { get set }

    init(configuration: HAWebSocketConfiguration)
    var configuration: HAWebSocketConfiguration { get set }

    var state: HAWebSocketState { get }

    // defaults to the main queue
    var callbackQueue: DispatchQueue { get set }

    func connect()
    func disconnect()

    // completion is invoked exactly once
    func send(_ request: HAWebSocketRequest, completion: @escaping RequestCompletion) -> HARequestToken

    // handler is invoked many times, until subscription is cancelled
    @discardableResult
    func subscribe(to request: HAWebSocketRequest, handler: @escaping SubscriptionHandler) -> HARequestToken
    @discardableResult
    func subscribe(to event: HAWebSocketEventType, handler: @escaping EventSubscriptionHandler) -> HARequestToken
}

public enum HAWebSocketError: Error {
    case `internal`(debugDescription: String)
    case external(ExternalError)

    public struct ExternalError {
        public var code: Int
        public var message: String

        init(_ errorValue: Any) {
            if let error = errorValue as? [String: Any],
               let code = error["code"] as? Int,
               let message = error["message"] as? String {
                self.code = code
                self.message = message
            } else {
                self.code = -1
                self.message = "unable to parse error response"
            }
        }
    }
}
