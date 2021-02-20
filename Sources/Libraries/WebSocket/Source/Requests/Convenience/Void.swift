// TODO: can I somehow get Void to work with the type system? it can't conform to decodable itself
public struct HAResponseVoid: HAWebSocketDataDecodable {
    public init(data: HAWebSocketData) throws {}
}
