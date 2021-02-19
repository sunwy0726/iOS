/// Data from a response
///
/// The root-level information in either the `result` for individual requests or `event` for subscriptions.
public enum HAWebSocketData {
    /// A dictionary response.
    /// - SeeAlso: `subscript(key:)`
    case dictionary([String: Any])
    /// An array response.
    case array([Any])
    /// Any other response, including `null`
    case empty

    /// Convenience access to the dictionary case for a particular key, with an expected type
    ///
    /// - Parameter key: The key to look up in `dictionary` case
    /// - Returns: The value from the dictionary
    /// - Throws: If the key was not present in the dictionary or the type was not the expected type
    func get<T>(_ key: String) throws -> T {
        guard case let .dictionary(dictionary) = self, let value = dictionary[key] else {
            throw HAWebSocketDataError.missingKey(key)
        }

        if let value = value as? T {
            return value
        }

        if T.self == HAWebSocketData.self {
            // TODO: can i do this type-safe
            return HAWebSocketData(value: value) as! T
        }

        if T.self == [HAWebSocketData].self, let value = value as? [Any] {
            // TODO: can i do this type-safe
            return value.map(HAWebSocketData.init(value:)) as! T
        }

        throw HAWebSocketDataError.incorrectType(
            key: key,
            expected: String(describing: T.self),
            actual: String(describing: type(of: value))
        )
    }

    /// Convenience access to the dictionary case for a particular key, with an expected type, with a transform applied
    ///
    /// - Parameter key: The key to look up in `dictionary` case
    /// - Returns: The value from the dictionary
    /// - Throws: If the key was not present in the dictionary or the type was not the expected type or the value couldn't be transformed
    func get<Value, Transform>(_ key: String, transform: (Value) throws -> Transform?) throws -> Transform {
        let base: Value = try get(key)
        if let transformed = try transform(base) {
            return transformed
        } else {
            throw HAWebSocketDataError.couldntTransform(key: key)
        }
    }

    /// Convenience access to the dictionary case for a particular key, with an expected type
    ///
    /// - Parameter key: The key to look up in `dictionary` case
    /// - Parameter fallback: The fallback value to use if not found in the dictionary
    /// - Returns: The value from the dictionary
    func get<T>(_ key: String, fallback: @autoclosure () -> T) -> T {
        if let value: T = try? get(key) {
            return value
        } else {
            return fallback()
        }
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()

    /// Convenience acess to the dictionary case for a particular key which should be a date
    ///
    /// - Parameter key: The key to look up in `dictionary` case
    /// - Parameter fallback: The fallback value to use if not found in the dictionary
    /// - Returns: The value from the dictionary
    /// - Throws: If the key was not present in the dictionary or the type couldn't be converted to a date
    func getDate(_ key: String) throws -> Date {
        let value: String = try get(key)
        if let date = Self.formatter.date(from: value) {
            return date
        } else {
            throw HAWebSocketDataError.couldntTransform(key: key)
        }
    }

    /// Convert an unknown value type into an enum case
    /// For use with direct response handling.
    ///
    /// - Parameter value: The value to convert
    internal init(value: Any?) {
        if let value = value as? [String: Any] {
            self = .dictionary(value)
        } else if let value = value as? [Any] {
            self = .array(value)
        } else {
            self = .empty
        }
    }
}

public enum HAWebSocketDataError: Error {
    case missingKey(String)
    case incorrectType(key: String, expected: String, actual: String)
    case couldntTransform(key: String)
}
