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

        public init(value: [String: Any]) {
            self.init(
                all: value["all"] as? Bool ?? false,
                time: value["time"] as? Bool ?? false,
                entities: value["entities"] as? [String] ?? [],
                domains: value["domains"] as? [String] ?? []
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

    public init?(data: HAWebSocketData) {
        guard let result = data["result"] else { return nil }

        self.init(
            result: result,
            listeners: Listeners(value: data["listeners"] as? [String: Any] ?? [:])
        )
    }

    public init(result: Any, listeners: Listeners) {
        self.result = result
        self.listeners = listeners
    }
}
