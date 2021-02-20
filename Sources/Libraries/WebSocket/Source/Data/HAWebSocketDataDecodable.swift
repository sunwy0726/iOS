/// A type which can be decoded using our data type
///
/// - Note: This differs from `Decodable` intentionally; `Decodable` does not support `Any` types or JSON well when the
///         results are extremely dynamic. This limitation requires that we do it ourselves.
public protocol HAWebSocketDataDecodable {
    // one day, if Decodable can handle 'Any' types well, this can be init(decoder:)
    init(data: HAWebSocketData) throws
}

/// Parse error
public enum HAWebSocketDataError: Error {
    case missingKey(String)
    case incorrectType(key: String, expected: String, actual: String)
    case couldntTransform(key: String)
}

public extension HAWebSocketData {
    /// Convenience access to the dictionary case for a particular key, with an expected type
    ///
    /// - Parameter key: The key to look up in `dictionary` case
    /// - Returns: The value from the dictionary
    /// - Throws: If the key was not present in the dictionary or the type was not the expected type or convertable
    func decode<T>(_ key: String) throws -> T {
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

        if T.self == Date.self, let value = value as? String, let date = Self.formatter.date(from: value) {
            // TODO: can i do this type-safe
            return date as! T
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
    func decode<Value, Transform>(_ key: String, transform: (Value) throws -> Transform?) throws -> Transform {
        let base: Value = try decode(key)
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
    func decode<T>(_ key: String, fallback: @autoclosure () -> T) -> T {
        if let value: T = try? decode(key) {
            return value
        } else {
            return fallback()
        }
    }

    /// Date formatter
    private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        return formatter
    }()
}
