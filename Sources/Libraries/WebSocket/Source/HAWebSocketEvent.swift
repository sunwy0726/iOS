public struct HAWebSocketEventType: RawRepresentable, Hashable {
    public let rawValue: String?
    public init(rawValue: String?) {
        self.rawValue = rawValue
    }

    public static var all: Self = .init(rawValue: nil)
    public static var callService: Self = .init(rawValue: "call_service")
    public static var componentLoaded: Self = .init(rawValue: "component_loaded")
    public static var coreConfigUpdated: Self = .init(rawValue: "core_config_updated")
    public static var homeassistantClose: Self = .init(rawValue: "homeassistant_close")
    public static var homeassistantStart: Self = .init(rawValue: "homeassistant_start")
    public static var homeassistantStarted: Self = .init(rawValue: "homeassistant_started")
    public static var homeassistantStop: Self = .init(rawValue: "homeassistant_stop")
    public static var homeassistantFinalWrite: Self = .init(rawValue: "homeassistant_final_write")
    public static var logbookEntry: Self = .init(rawValue: "logbook_entry")
    public static var platformDiscovered: Self = .init(rawValue: "platform_discovered")
    public static var serviceRegistered: Self = .init(rawValue: "service_registered")
    public static var serviceRemoved: Self = .init(rawValue: "service_removed")
    public static var stateChanged: Self = .init(rawValue: "state_changed")
    public static var themesUpdated: Self = .init(rawValue: "themes_updated")
    public static var timerOutOfSync: Self = .init(rawValue: "timer_out_of_sync")
    public static var timeChanged: Self = .init(rawValue: "time_changed")
}

public struct HAWebSocketEvent {
    public var eventType: HAWebSocketEventType
    public var firedAt: Date
    public var data: HAWebSocketData

    public enum Origin: String, Codable {
        case local = "LOCAL"
        case remote = "REMOTE"
    }

    public var origin: Origin

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case firedAt = "time_fired"
        case data
        case origin
    }

    init(dictionary: [String: Any]) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        let firedAt = dictionary["time_fired"].flatMap { $0 as? String }.flatMap { formatter.date(from: $0) } ?? Date()
        let origin = (dictionary["origin"] as? String).flatMap { Origin(rawValue: $0) } ?? .local

        self.eventType = .init(rawValue: dictionary["event_type"] as? String)
        self.firedAt = firedAt
        self.origin = origin
        self.data = HAWebSocketData(value: dictionary["data"])
    }
}
