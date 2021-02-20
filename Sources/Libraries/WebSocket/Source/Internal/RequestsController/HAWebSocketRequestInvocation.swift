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

    func cancelRequest() -> HAWebSocketTypedRequest<HAResponseVoid>? {
        // most requests do not need another request to be sent to be cancelled
        nil
    }

    func cancel() {
        // for subclasses
    }
}
