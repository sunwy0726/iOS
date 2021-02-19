public extension HAWebSocketTypedSubscription {
    static func renderTemplate(
        _ template: String,
        variables: [String: Any] = [:],
        timeout: Measurement<UnitDuration>? = nil
    ) -> HAWebSocketTypedSubscription<HAResponseRenderTemplate> {
        var data: [String: Any] = [:]
        data["template"] = template
        data["variables"] = variables

        if let timeout = timeout {
            data["timeout"] = timeout.converted(to: .seconds).value
        }

        return .init(request: .init(type: .renderTemplate, data: data))
    }
}

public struct HAResponseRenderTemplate: HAWebSocketResponseDecodable {
    public var result: Any
    public var listeners: Listeners

    public struct Listeners {
        public var all: Bool
        public var time: Bool
        public var entities: [String]
        public var domains: [String]

        public init(data: HAWebSocketData) throws {
            self.init(
                all: data.get("all", fallback: false),
                time: data.get("time", fallback: false),
                entities: data.get("entities", fallback: []),
                domains: data.get("domains", fallback: [])
            )
        }

        public init(
            all: Bool,
            time: Bool,
            entities: [String],
            domains: [String]
        ) {
            self.all = all
            self.time = time
            self.entities = entities
            self.domains = domains
        }
    }

    public init(data: HAWebSocketData) throws {
        self.init(
            result: try data.get("result"),
            listeners: try data.get("listeners", transform: Listeners.init(data:))
        )
    }

    public init(result: Any, listeners: Listeners) {
        self.result = result
        self.listeners = listeners
    }
}
