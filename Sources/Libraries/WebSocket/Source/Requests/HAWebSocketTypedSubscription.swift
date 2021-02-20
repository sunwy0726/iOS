/// A subscription request which has a strongly-typed handler
public struct HAWebSocketTypedSubscription<ResponseType: HAWebSocketDataDecodable> {
    /// Create a typed subscription
    /// - Parameter request: The request to be issued to start the subscription
    public init(request: HAWebSocketRequest) {
        self.request = request
    }

    /// The request to be issued
    public var request: HAWebSocketRequest
}
