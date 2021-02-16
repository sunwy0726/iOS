public struct HAWebSocketRequestType: RawRepresentable, Hashable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static var subscribeEvents: Self = .init(rawValue: "subscribe_events")
    public static var unsubscribeEvents: Self = .init(rawValue: "unsubscribe_events")
    public static var callService: Self = .init(rawValue: "call_service")
    public static var getStates: Self = .init(rawValue: "get_states")
    public static var getConfig: Self = .init(rawValue: "get_config")
    public static var getServices: Self = .init(rawValue: "get_services")
    public static var getPanels: Self = .init(rawValue: "get_panels")
    public static var currentUser: Self = .init(rawValue: "auth/current_user")
    public static var renderTemplate: Self = .init(rawValue: "render_template")
    public static var ping: Self = .init(rawValue: "ping")
}

public struct HAWebSocketRequest {
    public init(type: HAWebSocketRequestType, data: [String : Any]) {
        self.type = type
        self.data = data
    }

    public var type: HAWebSocketRequestType
    public var data: [String: Any] // top-level
}
