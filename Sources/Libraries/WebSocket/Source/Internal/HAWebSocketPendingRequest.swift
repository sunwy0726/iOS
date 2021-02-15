internal class HAWebSocketPendingRequest {
    internal let request: HAWebSocketRequest
    internal let completion: HAWebSocketDataHandler
    internal var requestIdentifier: HAWebSocketRequestIdentifier?

    init(request: HAWebSocketRequest, completion: @escaping HAWebSocketDataHandler) {
        self.request = request
        self.completion = completion
    }

    internal func resolve(_ data: HAWebSocketData) {
        completion(.success(data))
    }

    internal func resolve(_ result: Result<HAWebSocketData, HAWebSocketError>) {
        completion(result)
    }
}
