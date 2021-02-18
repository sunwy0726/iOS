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
            self.init(
                type: type,
                id: value["auth_provider_id"] as? String
            )
        }

        public init(type: String, id: String?) {
            self.type = type
            self.id = id
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

            self.init(
                id: id,
                name: name,
                isEnabled: isEnabled
            )
        }

        public init(id: String, name: String, isEnabled: Bool) {
            self.id = id
            self.name = name
            self.isEnabled = isEnabled
        }
    }

    public init?(data: HAWebSocketData) {
        guard let id = data["id"] as? String else {
            return nil
        }

        self.init(
            id: id,
            name: data["name"] as? String,
            isOwner: data["is_owner"] as? Bool ?? false,
            isAdmin: data["is_admin"] as? Bool ?? false,
            credentials: (data["credentials"] as? [[String: Any]])?.compactMap(Credential.init(value:)) ?? [],
            mfaModules: (data["mfa_modules"] as? [[String: Any]])?.compactMap(MFAModule.init(value:)) ?? []
        )
    }

    public init(
        id: String,
        name: String?,
        isOwner: Bool,
        isAdmin: Bool,
        credentials: [Credential],
        mfaModules: [MFAModule]
    ) {
        self.id = id
        self.name = name
        self.isOwner = isOwner
        self.isAdmin = isAdmin
        self.credentials = credentials
        self.mfaModules = mfaModules
    }

}
