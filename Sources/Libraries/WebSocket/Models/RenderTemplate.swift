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
            self.all = value["all"] as? Bool ?? false
            self.time = value["time"] as? Bool ?? false
            self.entities = value["entities"] as? [String] ?? []
            self.domains = value["domains"] as? [String] ?? []
        }
    }

    public init?(data: HAWebSocketData) {
        guard let result = data["result"] else { return nil }

        self.result = result
        self.listeners = Listeners(value: data["listeners"] as? [String: Any] ?? [:])
    }

    public init(result: Any, listeners: Listeners) {
        self.result = result
        self.listeners = listeners
    }
}
