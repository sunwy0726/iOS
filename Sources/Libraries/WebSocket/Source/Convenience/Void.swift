// TODO: can I somehow get Void to work with the type system? it can't conform to decodable itself
public struct HAResponseVoid: HADataDecodable {
    public init(data: HAData) throws {}
}
