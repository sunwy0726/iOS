public extension HATypedSubscription {
    static func renderTemplate(
        _ template: String,
        variables: [String: Any] = [:],
        timeout: Measurement<UnitDuration>? = nil
    ) -> HATypedSubscription<HAResponseRenderTemplate> {
        var data: [String: Any] = [:]
        data["template"] = template
        data["variables"] = variables

        if let timeout = timeout {
            data["timeout"] = timeout.converted(to: .seconds).value
        }

        return .init(request: .init(type: .renderTemplate, data: data))
    }
}

public struct HAResponseRenderTemplate: HADataDecodable {
    public var result: Any
    public var listeners: Listeners

    public struct Listeners {
        public var all: Bool
        public var time: Bool
        public var entities: [String]
        public var domains: [String]

        public init(data: HAData) throws {
            self.init(
                all: data.decode("all", fallback: false),
                time: data.decode("time", fallback: false),
                entities: data.decode("entities", fallback: []),
                domains: data.decode("domains", fallback: [])
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

    public init(data: HAData) throws {
        self.init(
            result: try data.decode("result"),
            listeners: try data.decode("listeners", transform: Listeners.init(data:))
        )
    }

    public init(result: Any, listeners: Listeners) {
        self.result = result
        self.listeners = listeners
    }
}
