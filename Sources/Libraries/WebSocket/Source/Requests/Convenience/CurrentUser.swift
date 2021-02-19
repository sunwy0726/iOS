public extension HAWebSocketTypedRequest {
    static func currentUser() -> HAWebSocketTypedRequest<HAResponseCurrentUser> {
        .init(request: .init(type: .currentUser, data: [:]))
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

        public init(data: HAWebSocketData) throws {
            self.init(
                type: try data.get("auth_provider_type"),
                id: data.get("auth_provider_id", fallback: nil)
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

        public init(data: HAWebSocketData) throws {
            self.init(
                id: try data.get("id"),
                name: try data.get("name"),
                isEnabled: try data.get("enabled")
            )
        }

        public init(id: String, name: String, isEnabled: Bool) {
            self.id = id
            self.name = name
            self.isEnabled = isEnabled
        }
    }

    public init(data: HAWebSocketData) throws {
        self.init(
            id: try data.get("id"),
            name: data.get("name", fallback: nil),
            isOwner: data.get("is_owner", fallback: false),
            isAdmin: data.get("is_admin", fallback: false),
            credentials: try data.get("credentials", fallback: []).compactMap(Credential.init(data:)),
            mfaModules: try data.get("mfa_modules", fallback: []).compactMap(MFAModule.init(data:))
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
