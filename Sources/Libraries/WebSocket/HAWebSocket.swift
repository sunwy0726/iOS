import Foundation

public struct HAWebSocketConnectionInfo {
    public var url: URL
}

public protocol HAWebSocketConnectionDelegate: AnyObject {
    func connectionInfoForWebSocket(_ webSocket: HAWebSocket) -> HAWebSocketConnectionInfo
    func webSocket(_ webSocket: HAWebSocket, connectionTransitionedTo state: HAWebSocketState)
}

public protocol HAWebSocketAuthDelegate: AnyObject {
    func webSocket(_ webSocket: HAWebSocket, fetchAccessToken completion: @escaping (Result<String, Error>) -> Void)
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

public protocol HAWebSocket {
    typealias RequestCompletion = (Result<HAWebSocketData, HAWebSocketError>) -> Void
    typealias SubscriptionHandler = (HARequestToken, HAWebSocketData) -> Void
    typealias EventSubscriptionHandler = (HARequestToken, HAWebSocketEvent) -> Void

    var connectionDelegate: HAWebSocketConnectionDelegate? { get set }
    var authDelegate: HAWebSocketAuthDelegate? { get set }

    var state: HAWebSocketState { get }

    var callbackQueue: DispatchQueue { get set }

    func connect()
    func disconnect()

    // completion is invoked exactly once
    func send(_ request: HAWebSocketRequest, completion: @escaping RequestCompletion) -> HARequestToken

    // handler is invoked many times, until subscription is cancelled
    func subscribe(to request: HAWebSocketRequest, handler: @escaping SubscriptionHandler) -> HARequestToken
    func subscribe(to event: HAWebSocketEventType, handler: @escaping EventSubscriptionHandler) -> HARequestToken
}

public struct HAWebSocketError: Error {
    public struct ExternalError {
        public var code: Int
        public var message: String
    }

    public enum ErrorType {
        case `internal`(debugDescription: String)
        case external(ExternalError)
    }

    public var type: ErrorType
    public var originalRequest: HAWebSocketRequest?
}
