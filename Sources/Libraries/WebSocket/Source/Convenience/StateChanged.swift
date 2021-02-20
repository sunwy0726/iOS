public extension HATypedSubscription {
    static func stateChanged() -> HATypedSubscription<HAResponseEventStateChanged> {
        .init(request: .init(type: .subscribeEvents, data: [
            "event_type": HAEventType.stateChanged.rawValue!,
        ]))
    }
}

public struct HAResponseEntity {
    var entityId: String
    var state: String
    var lastChanged: Date
    var lastUpdated: Date
    var attributes: [String: Any]
    var context: [String: Any] // todo as strongly typed

    public init(data: HAData) throws {
        self.init(
            entityId: try data.decode("entity_id"),
            state: try data.decode("state"),
            lastChanged: try data.decode("last_changed"),
            lastUpdated: try data.decode("last_updated"),
            attributes: try data.decode("attributes"),
            context: try data.decode("context")
        )
    }

    public init(
        entityId: String,
        state: String,
        lastChanged: Date,
        lastUpdated: Date,
        attributes: [String: Any],
        context: [String: Any]
    ) {
        self.entityId = entityId
        self.state = state
        self.lastChanged = lastChanged
        self.lastUpdated = lastUpdated
        self.attributes = attributes
        self.context = context
    }
}

// TODO: inheritence to HAResponseEvent?
public struct HAResponseEventStateChanged: HADataDecodable {
    public var event: HAResponseEvent
    public var entityId: String
    public var oldState: HAResponseEntity?
    public var newState: HAResponseEntity?

    public init(data: HAData) throws {
        let event = try HAResponseEvent(data: data)
        let eventData = HAData.dictionary(event.data)

        self.init(
            event: event,
            entityId: try eventData.decode("entity_id"),
            oldState: try? eventData.decode("old_state", transform: HAResponseEntity.init(data:)),
            newState: try? eventData.decode("new_state", transform: HAResponseEntity.init(data:))
        )
    }

    public init(
        event: HAResponseEvent,
        entityId: String,
        oldState: HAResponseEntity?,
        newState: HAResponseEntity?
    ) {
        self.event = event
        self.entityId = entityId
        self.oldState = oldState
        self.newState = newState
    }
}
