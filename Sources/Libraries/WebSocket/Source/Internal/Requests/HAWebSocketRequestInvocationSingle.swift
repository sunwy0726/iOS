internal class HAWebSocketRequestInvocationSingle: HAWebSocketRequestInvocation {
    private var completion: HAWebSocketProtocol.RequestCompletion?

    init(
        request: HAWebSocketRequest,
        completion: @escaping HAWebSocketProtocol.RequestCompletion
    ) {
        self.completion = completion
        super.init(request: request)
    }

    override func cancel() {
        super.cancel()
        completion = nil
    }

    override var needsAssignment: Bool {
        super.needsAssignment && completion != nil
    }

    func resolve(_ result: Result<HAWebSocketData, HAWebSocketError>) {
        // we need to make it impossible to call the completion handler more than once
        completion?(result)
        completion = nil
    }
}
