/// The command to issue via the WebSocket
public struct HAWebSocketRequestType: RawRepresentable, Hashable {
    public var rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static var subscribeEvents: Self = .init(rawValue: "subscribe_events")
    public static var unsubscribeEvents: Self = .init(rawValue: "unsubscribe_events")
    public static var callService: Self = .init(rawValue: "call_service")
    public static var getStates: Self = .init(rawValue: "get_states")
    public static var getConfig: Self = .init(rawValue: "get_config")
    public static var getServices: Self = .init(rawValue: "get_services")
    public static var getPanels: Self = .init(rawValue: "get_panels")
    public static var currentUser: Self = .init(rawValue: "auth/current_user")
    public static var renderTemplate: Self = .init(rawValue: "render_template")
}

/// A request, with data, to be issued
public struct HAWebSocketRequest {
    /// Create a request
    /// - Parameters:
    ///   - type: The type of the request to issue
    ///   - data: The data to accompany with the request, at the top level
    ///   - shouldRetry: Whether to retry the request when a connection change occurs
    public init(type: HAWebSocketRequestType, data: [String : Any], shouldRetry: Bool = true) {
        self.type = type
        self.data = data
        self.shouldRetry = shouldRetry
    }

    /// The type of the request to be issued
    public var type: HAWebSocketRequestType
    /// Additional top-level data to include in the request
    public var data: [String: Any]
    /// Whether the request should be retried if the connection closes and reopens
    public var shouldRetry: Bool
}

// TODO: can I somehow get Void to work with the type system? it can't conform to decodable itself
public struct HAResponseVoid: HAWebSocketResponseDecodable {
    public init(data: HAWebSocketData) throws {}
}

/// A response value which can be decoded by our data representation
///
/// - Note: This differs from `Decodable` intentionally; `Decodable` does not support `Any` types or JSON well
///         and given our heavy reliance on JSON for the communication format, we cannot reasonably offer Decodable support.
public protocol HAWebSocketResponseDecodable {
    // one day, if Decodable can handle 'Any' types well, this can be init(decoder:)
    init(data: HAWebSocketData) throws
}

/// A request which has a strongly-typed response format
public struct HAWebSocketTypedRequest<ResponseType: HAWebSocketResponseDecodable> {
    /// Create a typed request
    /// - Parameter request: The request to be issued
    public init(request: HAWebSocketRequest) {
        self.request = request
    }

    /// The request to be issued
    public var request: HAWebSocketRequest
}

/// A subscription request which has a strongly-typed handler
public struct HAWebSocketTypedSubscription<ResponseType: HAWebSocketResponseDecodable> {
    /// Create a typed subscription
    /// - Parameter request: The request to be issued to start the subscription
    public init(request: HAWebSocketRequest) {
        self.request = request
    }

    /// The request to be issued
    public var request: HAWebSocketRequest
}
