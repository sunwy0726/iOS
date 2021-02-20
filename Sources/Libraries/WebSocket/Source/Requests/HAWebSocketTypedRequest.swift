/// A request which has a strongly-typed response format
public struct HAWebSocketTypedRequest<ResponseType: HAWebSocketDataDecodable> {
    /// Create a typed request
    /// - Parameter request: The request to be issued
    public init(request: HAWebSocketRequest) {
        self.request = request
    }

    /// The request to be issued
    public var request: HAWebSocketRequest
}
