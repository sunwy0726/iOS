import Foundation

internal enum HAWebSocketResponse {
    enum ResponseType: String {
        case result = "result"
        case event = "event"
        case authRequired = "auth_required"
        case authOK = "auth_ok"
        case authInvalid = "auth_invalid"
    }

    enum AuthState {
        case required
        case ok
        case invalid
    }

    case result(identifier: HAWebSocketRequestIdentifier, result: Result<HAWebSocketData, HAWebSocketError>)
    case event(identifier: HAWebSocketRequestIdentifier, data: HAWebSocketData)
    case auth(AuthState)

    enum ParseError: Error {
        case unknownType(Any)
        case unknownId(Any)
    }

    enum TempError: Error {
        case parseError(String)
    }

    init(dictionary: [String: Any]) throws {
        guard let type = dictionary["type"] as? String else {
            throw ParseError.unknownType(dictionary["type"])
        }

        func parseIdentifier() throws -> HAWebSocketRequestIdentifier {
            if let value = (dictionary["id"] as? Int).flatMap(HAWebSocketRequestIdentifier.init(rawValue:)) {
                return value
            } else {
                throw ParseError.unknownId(dictionary["id"])
            }
        }

        switch ResponseType(rawValue: type) {
        case .result:
            let identifier = try parseIdentifier()

            if dictionary["success"] as? Bool == true {
                self = .result(identifier: identifier, result: .success(.init(value: dictionary["result"])))
            } else {
                self = .result(identifier: identifier, result: .failure(.external(.init(dictionary["error"]))))
            }
        case .event:
            let identifier = try parseIdentifier()
            self = .event(identifier: identifier, data: HAWebSocketData(value: dictionary["event"]))
        case .authRequired:
            self = .auth(.required)
        case .authOK:
            self = .auth(.ok)
        case .authInvalid:
            self = .auth(.invalid)
        case .none:
            throw TempError.parseError("unknown response type \(type)")
        }
    }
}
