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
    public static var timeChanged: Self = .init(rawValue: "time_changed")
    public static var timerOutOfSync: Self = .init(rawValue: "timer_out_of_sync")}

public struct HAResponseEvent: HAWebSocketResponseDecodable {
    public var type: HAWebSocketEventType
    public var timeFired: Date
    public var data: [String: Any]
    public var origin: Origin
    public var context: Context

    public enum Origin: String {
        case local = "LOCAL"
        case remote = "REMOTE"
    }

    public struct Context {
        public var id: String
        public var userId: String?
        public var parentId: String?

        public init?(value: [String: Any]) {
            guard let id = value["id"] as? String else {
                return nil
            }

            self.init(
                id: id,
                userId: value["user_id"] as? String,
                parentId: value["parent_id"] as? String
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

    public init?(data: HAWebSocketData) {
        guard let eventType = data["event_type"] as? String,
              let timeFired = (data["time_fired"] as? String).flatMap(Self.formatter.date(from:)),
              let origin = (data["origin"] as? String).flatMap(Origin.init(rawValue:)),
              let context = (data["context"] as? [String: Any]).flatMap(Context.init(value:))
        else {
            return nil
        }

        self.init(
            type: .init(rawValue: eventType),
            timeFired: timeFired,
            data: data["data"] as? [String: Any] ?? [:],
            origin: origin,
            context: context
        )
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
