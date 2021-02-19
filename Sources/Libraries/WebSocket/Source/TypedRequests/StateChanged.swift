//public extension HAWebSocketTypedSubscription {
//    static func stateChanged() -> HAWebSocketTypedSubscription<HAResponseEventStateChanged> {
//        return .init(request: .init(type: .subscribeEvents, data: [
//            "event_type": HAWebSocketEventType.stateChanged.rawValue!
//        ]))
//    }
//}
//
//public final class HAResponseEventStateChanged: HAResponseEvent {
////    public let entityId: String
////    public let oldState: Void
////    public let newState: Void
//
//    public required init?(data: HAWebSocketData) {
//        super.init(data: data)
//
//
//    }
//}
