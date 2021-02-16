internal class HAWebSocketRequestInvocation: Equatable, Hashable {
    private let uniqueID = UUID()
    let request: HAWebSocketRequest
    var requestIdentifier: HAWebSocketRequestIdentifier?

    private var completion: HAWebSocket.RequestCompletion?

    init(
        request: HAWebSocketRequest,
        completion: @escaping HAWebSocket.RequestCompletion
    ) {
        self.request = request
        self.completion = completion
    }

    func cancel() {
        completion = nil
    }

    func resolve(_ result: Result<HAWebSocketData, HAWebSocketError>) {
        // we need to make it impossible to call the completion handler more than once
        completion?(result)
        completion = nil
    }

    static func == (lhs: HAWebSocketRequestInvocation, rhs: HAWebSocketRequestInvocation) -> Bool {
        lhs.uniqueID == rhs.uniqueID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueID)
    }
}
