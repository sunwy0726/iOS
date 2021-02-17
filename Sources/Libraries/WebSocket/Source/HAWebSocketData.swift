public enum HAWebSocketData {
    case dictionary([String: Any])
    case array([Any])
    case empty

    subscript(key: String) -> Any? {
        if case let .dictionary(dictionary) = self {
            return dictionary[key]
        } else {
            return nil
        }
    }

    init(value: Any?) {
        if let value = value as? [String: Any] {
            self = .dictionary(value)
        } else if let value = value as? [Any] {
            self = .array(value)
        } else {
            self = .empty
        }
    }
}
