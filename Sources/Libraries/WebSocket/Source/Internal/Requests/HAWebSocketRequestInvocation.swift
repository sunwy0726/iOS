internal struct HAWebSocketRequestIdentifier: RawRepresentable, Hashable {
    let rawValue: Int
}

internal class HAWebSocketRequestInvocation: Equatable, Hashable {
    private let uniqueID = UUID()
    let request: HAWebSocketRequest
    var identifier: HAWebSocketRequestIdentifier?

    init(request: HAWebSocketRequest) {
        self.request = request
    }

    static func == (lhs: HAWebSocketRequestInvocation, rhs: HAWebSocketRequestInvocation) -> Bool {
        lhs.uniqueID == rhs.uniqueID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueID)
    }

    var needsAssignment: Bool {
        // for subclasses, too
        identifier == nil
    }

    func cancel() {
        // for subclasses
    }
}

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

internal class HAWebSocketRequestInvocationSubscription: HAWebSocketRequestInvocation {
    private var handler: HAWebSocketProtocol.SubscriptionHandler?

    init(
        request: HAWebSocketRequest,
        handler: @escaping HAWebSocketProtocol.SubscriptionHandler
    ) {
        self.handler = handler
        super.init(request: request)
    }

    override func cancel() {
        super.cancel()
        handler = nil
    }

    override var needsAssignment: Bool {
        super.needsAssignment && handler != nil
    }

    internal func invoke(token: HARequestTokenImpl, event: HAWebSocketData) {
        handler?(token, event)
    }
}
