import Foundation

/// Information for connecting to the server
public struct HAWebSocketConnectionInfo {
    public init(url: URL) {
        self.url = url
    }

    public var url: URL
}

/// Configuration of the WebSocket connection
public struct HAWebSocketConfiguration {
    /// Create a new configuration
    /// - Parameters:
    ///   - connectionInfo: Block which provides the connection info on demand
    ///   - fetchAuthToken: Block which invokes a closure asynchronously to provide authentication access tokens
    public init(
        connectionInfo: @escaping () -> HAWebSocketConnectionInfo,
        fetchAuthToken: @escaping ((Result<String, Error>) -> Void) -> Void
    ) {
        self.connectionInfo = connectionInfo
        self.fetchAuthToken = fetchAuthToken
    }

    /// The connection info provider block
    public var connectionInfo: () -> HAWebSocketConnectionInfo
    /// The auth token provider block
    public var fetchAuthToken: (_ completion: (Result<String, Error>) -> Void) -> Void
}

/// Delegate of the WebSocket connection
public protocol HAWebSocketDelegate: AnyObject {
    /// The WebSocket state has changed
    /// - Parameters:
    ///   - webSocket: The WebSocket invoking this function
    ///   - state: The new state of the WebSocket being transitioned to
    func webSocket(_ webSocket: HAWebSocket, connectionTransitionedTo state: HAWebSocketState)
}

/// State of the WebSocket connection
public enum HAWebSocketState {
    /// Reason for disconnection state
    public enum DisconnectReason {
        case initial
        case error(HAWebSocketError)
        case waitingToReconnect(atLatest: Date, retryCount: Int)
    }

    /// Not connected
    /// - SeeAlso: `DisconnectReason`
    case disconnected(reason: DisconnectReason)
    /// Connection is actively being attempted
    case connecting
    /// The connection has been made and can process commands
    case ready(version: String)
}

/// A token representing an individual request or subscription
///
/// You do not need to strongly retain this value. Requests are only cancelled explicitly.
public protocol HARequestToken {
    func cancel()
}

/// Namespace for creating a new WebSocket connection
public enum HAWebSocket {
    /// The type which represents an API connection
    public static var API: HAWebSocketProtocol.Type = { HAWebSocketAPI.self }()
    /// Create a new WebSocket connection
    /// - Parameter configuration: The configuration for the connection
    /// - Returns: The connection itself
    public static func api(configuration: HAWebSocketConfiguration) -> HAWebSocketProtocol {
        Self.API(configuration: configuration)
    }
}

/// The interface for the WebSocket API itself
public protocol HAWebSocketProtocol: AnyObject {
    /// Handler invoked when a request completes
    typealias RequestCompletion = (Result<HAWebSocketData, HAWebSocketError>) -> Void
    /// Handler invoked when the initial request to start a subscription completes
    typealias SubscriptionInitiatedHandler = (Result<HAWebSocketData, HAWebSocketError>) -> Void
    /// Handler invoked when a subscription receives a new event
    typealias SubscriptionHandler = (HARequestToken, HAWebSocketData) -> Void

    /// The delegate of the connection
    var delegate: HAWebSocketDelegate? { get set }

    /// Create a new connection
    ///
    /// - SeeAlso: `HAWebSocket` for the public interface to create connections
    /// - Parameter configuration: The configuration to create
    init(configuration: HAWebSocketConfiguration)
    /// The current configuration for the connection
    var configuration: HAWebSocketConfiguration { get set }

    /// The current state of the connection
    var state: HAWebSocketState { get }

    /// The queue to invoke all handlers on
    /// This defaults to `DispatchQueue.main`
    var callbackQueue: DispatchQueue { get set }

    /// Attempt to connect to the server
    /// This will attempt immediately and then make retry attempts based on timing and/or reachability and/or application state
    func connect()
    /// Disconnect from the server or end reconnection attempts
    func disconnect()

    /// Send a request
    ///
    /// If the connection is currently disconnected, or this request fails to be responded to, this will be reissued in the future until it individually fails or is cancelled.
    ///
    /// - Parameters:
    ///   - request: The request to send; invoked at most once
    ///   - completion: The handler to invoke on completion
    /// - Returns: A token which can be used to cancel the request
    @discardableResult
    func send(
        _ request: HAWebSocketRequest,
        completion: @escaping RequestCompletion
    ) -> HARequestToken
    /// Send a request with a concrete response type
    ///
    /// If the connection is currently disconnected, or this request fails to be responded to, this will be reissued in the future until it individually fails or is cancelled.
    ///
    /// - SeeAlso: `HAWebSocketTypedRequest` extensions which create instances of it
    /// - Parameters:
    ///   - request: The request to send; invoked at most once
    ///   - completion: The handler to invoke on completion
    /// - Returns: A token which can be used to cancel the request
    @discardableResult
    func send<T>(
        _ request: HAWebSocketTypedRequest<T>,
        completion: @escaping (Result<T, HAWebSocketError>) -> Void
    ) -> HARequestToken

    /// Start a subscription to a request
    ///
    /// Subscriptions will automatically be restarted if the current connection to the server disconnects and then
    /// reconnects.
    ///
    /// - Parameters:
    ///   - request: The request to send to start the subscription
    ///   - handler: The handler to invoke when new events are received for the subscription; invoked many times
    /// - Returns: A token which can be used to cancel the subscription
    @discardableResult
    func subscribe(
        to request: HAWebSocketRequest,
        handler: @escaping SubscriptionHandler
    ) -> HARequestToken
    /// Start a subscription and be notified about its start state
    ///
    /// Subscriptions will automatically be restarted if the current connection to the server disconnects and then
    /// reconnects. When each restart event occurs, the `initiated` handler will be invoked again.
    ///
    /// - Parameters:
    ///   - request: The request to send to start the subscription
    ///   - initiated: The handler to invoke when the subscription's initial request succeeds or fails; invoked once
    ///                per underlying WebSocket connection
    ///   - handler: The handler to invoke when new events are received for the subscription; invoked many times
    @discardableResult
    func subscribe(
        to request: HAWebSocketRequest,
        initiated: @escaping SubscriptionInitiatedHandler,
        handler: @escaping SubscriptionHandler
    ) -> HARequestToken

    /// Start a subscription to a request with a concrete event type
    ///
    /// Subscriptions will automatically be restarted if the current connection to the server disconnects and then
    /// reconnects.
    ///
    /// - Parameters:
    ///   - request: The request to send to start the subscription
    ///   - handler: The handler to invoke when new events are received for the subscription; invoked many times
    /// - Returns: A token which can be used to cancel the subscription
    /// - SeeAlso: `HAWebSocketTypedSubscription` extensions which create instances of it
    @discardableResult
    func subscribe<T>(
        to request: HAWebSocketTypedSubscription<T>,
        handler: @escaping (HARequestToken, T) -> Void
    ) -> HARequestToken
    /// Start a subscription to a request with a concrete event type
    ///
    /// Subscriptions will automatically be restarted if the current connection to the server disconnects and then
    /// reconnects. When each restart event occurs, the `initiated` handler will be invoked again.
    ///
    /// - Parameters:
    ///   - request: The request to send to start the subscription
    ///   - initiated: The handler to invoke when the subscription's initial request succeeds or fails; invoked once
    ///                per underlying WebSocket connection
    ///   - handler: The handler to invoke when new events are received for the subscription; invoked many times
    /// - Returns: A token which can be used to cancel the subscription
    /// - SeeAlso: `HAWebSocketTypedSubscription` extensions which create instances of it
    @discardableResult
    func subscribe<T>(
        to request: HAWebSocketTypedSubscription<T>,
        initiated: @escaping SubscriptionInitiatedHandler,
        handler: @escaping (HARequestToken, T) -> Void
    ) -> HARequestToken
}

/// Overall error wrapper for the library
public enum HAWebSocketError: Error {
    /// An error occurred in parsing or other internal handling
    case `internal`(debugDescription: String)
    /// An error response from the server indicating a request problem
    case external(ExternalError)

    /// Description of a server-delivered error
    public struct ExternalError {
        /// The code provided with the error
        public var code: Int
        /// The message provided with the error
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
