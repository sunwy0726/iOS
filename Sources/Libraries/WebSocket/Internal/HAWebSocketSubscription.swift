internal class HAWebSocketSubscription: Equatable, Hashable {
    internal let request: HAWebSocketRequest
    internal var subscriptionIdentifier: HAWebSocketRequestIdentifier?
    private var handler: HAWebSocket.SubscriptionHandler?
    private let uniqueID = UUID()

    internal init(request: HAWebSocketRequest, handler: @escaping HAWebSocket.SubscriptionHandler) {
        self.request = request
        self.handler = handler
    }

    func cancel() {
        handler = nil
    }

    internal func fire(token: HARequestTokenImpl, event: HAWebSocketData) {
        handler?(token, event)
    }

    static func == (lhs: HAWebSocketSubscription, rhs: HAWebSocketSubscription) -> Bool {
        lhs.uniqueID == rhs.uniqueID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueID)
    }
}
