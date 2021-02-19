public extension HAWebSocketTypedSubscription {
    static func events(
        _ type: HAWebSocketEventType
    ) -> HAWebSocketTypedSubscription<HAResponseEvent> {
        var data: [String: Any] = [:]

        if let rawType = type.rawValue {
            data["event_type"] = rawType
        }

        return .init(request: .init(type: .subscribeEvents, data: data))
    }
}

public struct HAWebSocketEventType: RawRepresentable, Hashable {
    public let rawValue: String?
    public init(rawValue: String?) {
        self.rawValue = rawValue
    }

    public static var all: Self = .init(rawValue: nil)

    // rule of thumb: any event available in `core` is valid for this list
    public static var callService: Self = .init(rawValue: "call_service")
    public static var componentLoaded: Self = .init(rawValue: "component_loaded")
    public static var coreConfigUpdated: Self = .init(rawValue: "core_config_updated")
    public static var homeassistantClose: Self = .init(rawValue: "homeassistant_close")
    public static var homeassistantFinalWrite: Self = .init(rawValue: "homeassistant_final_write")
    public static var homeassistantStart: Self = .init(rawValue: "homeassistant_start")
    public static var homeassistantStarted: Self = .init(rawValue: "homeassistant_started")
    public static var homeassistantStop: Self = .init(rawValue: "homeassistant_stop")
    public static var logbookEntry: Self = .init(rawValue: "logbook_entry")
    public static var platformDiscovered: Self = .init(rawValue: "platform_discovered")
    public static var serviceRegistered: Self = .init(rawValue: "service_registered")
    public static var serviceRemoved: Self = .init(rawValue: "service_removed")
    public static var shoppingListUpdated: Self = .init(rawValue: "shopping_list_updated")
    public static var stateChanged: Self = .init(rawValue: "state_changed")
    public static var themesUpdated: Self = .init(rawValue: "themes_updated")
    public static var timerOutOfSync: Self = .init(rawValue: "timer_out_of_sync")
}

public struct HAResponseEvent: HAWebSocketResponseDecodable {
    public let type: HAWebSocketEventType
    public let timeFired: Date
    public let data: [String: Any]
    public let origin: Origin
    public let context: Context

    public enum Origin: String {
        case local = "LOCAL"
        case remote = "REMOTE"
    }

    public struct Context {
        public var id: String
        public var userId: String?
        public var parentId: String?

        public init(data: HAWebSocketData) throws {
            self.init(
                id: try data.get("id"),
                userId: data.get("user_id", fallback: nil),
                parentId: data.get("parent_id", fallback: nil)
            )
        }

        public init(
            id: String,
            userId: String?,
            parentId: String?
        ) {
            self.id = id
            self.userId = userId
            self.parentId = parentId
        }
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()

    public init(data: HAWebSocketData) throws {
        self.type = .init(rawValue: try data.get("event_type"))
        self.timeFired = try data.get("time_fired", transform: Self.formatter.date(from:))
        self.data = data.get("data", fallback: [:])
        self.origin = try data.get("origin", transform: Origin.init(rawValue:))
        self.context = try data.get("context", transform: Context.init(data:))
    }

    public init(
        type: HAWebSocketEventType,
        timeFired: Date,
        data: [String: Any],
        origin: Origin,
        context: Context
    ) {
        self.type = type
        self.timeFired = timeFired
        self.data = data
        self.origin = origin
        self.context = context
    }
}
