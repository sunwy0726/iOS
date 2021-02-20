public extension HATypedRequest {
    static func currentUser() -> HATypedRequest<HAResponseCurrentUser> {
        .init(request: .init(type: .currentUser, data: [:]))
    }
}

public struct HAResponseCurrentUser: HADataDecodable {
    public var id: String
    public var name: String?
    public var isOwner: Bool
    public var isAdmin: Bool
    public var credentials: [Credential]
    public var mfaModules: [MFAModule]

    public struct Credential {
        public var type: String
        public var id: String?

        public init(data: HAData) throws {
            self.init(
                type: try data.decode("auth_provider_type"),
                id: data.decode("auth_provider_id", fallback: nil)
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

        public init(data: HAData) throws {
            self.init(
                id: try data.decode("id"),
                name: try data.decode("name"),
                isEnabled: try data.decode("enabled")
            )
        }

        public init(id: String, name: String, isEnabled: Bool) {
            self.id = id
            self.name = name
            self.isEnabled = isEnabled
        }
    }

    public init(data: HAData) throws {
        self.init(
            id: try data.decode("id"),
            name: data.decode("name", fallback: nil),
            isOwner: data.decode("is_owner", fallback: false),
            isAdmin: data.decode("is_admin", fallback: false),
            credentials: try data.decode("credentials", fallback: []).compactMap(Credential.init(data:)),
            mfaModules: try data.decode("mfa_modules", fallback: []).compactMap(MFAModule.init(data:))
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
