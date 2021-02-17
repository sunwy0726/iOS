public extension HAWebSocketTypedRequest {
    static func currentUser() -> HAWebSocketTypedRequest<HAResponseCurrentUser> {
        return .init(request: .init(type: .currentUser, data: [:]))
    }
}

public struct HAResponseCurrentUser: HAWebSocketResponseDecodable {
    public var id: String
    public var name: String?
    public var isOwner: Bool
    public var isAdmin: Bool
    public var credentials: [Credential]
    public var mfaModules: [MFAModule]

    public struct Credential {
        public var type: String
        public var id: String?

        public init?(value: [String: Any]) {
            guard let type = value["auth_provider_type"] as? String else { return nil }
            self.type = type
            self.id = value["auth_provider_id"] as? String
        }
    }

    public struct MFAModule {
        public var id: String
        public var name: String
        public var isEnabled: Bool

        public init?(value: [String: Any]) {
            guard let id = value["id"] as? String,
                  let name = value["name"] as? String,
                  let isEnabled = value["enabled"] as? Bool
            else {
                return nil
            }

            self.id = id
            self.name = name
            self.isEnabled = isEnabled
        }
    }

    public init?(data: HAWebSocketData) {
        guard let id = data["id"] as? String
        else {
            return nil
        }

        self.id = id
        self.name = data["name"] as? String
        self.isOwner = data["is_owner"] as? Bool ?? false
        self.isAdmin = data["is_admin"] as? Bool ?? false
        self.credentials = (data["credentials"] as? [[String: Any]])?.compactMap(Credential.init(value:)) ?? []
        self.mfaModules = (data["mfa_modules"] as? [[String: Any]])?.compactMap(MFAModule.init(value:)) ?? []
    }
}
