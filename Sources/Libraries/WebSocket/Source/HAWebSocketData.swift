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

    /// Convenience subscript to access the dictionary case
    ///
    /// - Parameter key: The key to look up in `dictionary` case
    /// - Returns: The value from the dictionary
    subscript(key: String) -> Any? {
        if case let .dictionary(dictionary) = self {
            return dictionary[key]
        } else {
            return nil
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
