internal class HAWebSocketRequestInvocationSubscription: HAWebSocketRequestInvocation {
    private var handler: HAWebSocketProtocol.SubscriptionHandler?
    private var initiated: HAWebSocketProtocol.SubscriptionInitiatedHandler?

    init(
        request: HAWebSocketRequest,
        initiated: HAWebSocketProtocol.SubscriptionInitiatedHandler?,
        handler: @escaping HAWebSocketProtocol.SubscriptionHandler
    ) {
        self.initiated = initiated
        self.handler = handler
        super.init(request: request)
    }

    override func cancel() {
        super.cancel()
        handler = nil
        initiated = nil
    }

    override var needsAssignment: Bool {
        super.needsAssignment && handler != nil
    }

    override func cancelRequest() -> HAWebSocketTypedRequest<HAResponseVoid>? {
        if let identifier = identifier {
            return .unsubscribe(identifier)
        } else {
            return nil
        }
    }

    func resolve(_ result: Result<HAWebSocketData, HAWebSocketError>) {
        initiated?(result)
    }

    func invoke(token: HARequestTokenImpl, event: HAWebSocketData) {
        handler?(token, event)
    }
}
