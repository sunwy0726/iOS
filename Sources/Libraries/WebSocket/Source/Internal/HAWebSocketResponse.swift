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

    case result(identifier: HAWebSocketRequestIdentifier, data: Result<HAWebSocketData, HAWebSocketError>)
    case event(identifier: HAWebSocketRequestIdentifier, event: HAWebSocketEvent)
    case auth(AuthState)

    init(dictionary: [String: Any]) throws {
        guard let type = dictionary["type"] as? String else {
            throw HAWebSocketError.ResponseError.parseError(nil)
        }

        func parseIdentifier() throws -> HAWebSocketRequestIdentifier {
            if let value = (dictionary["id"] as? Int).flatMap(HAWebSocketRequestIdentifier.init(rawValue:)) {
                return value
            } else {
                throw HAWebSocketError.ResponseError.parseError(nil)
            }
        }

        switch ResponseType(rawValue: type) {
        case .result:
            let identifier = try parseIdentifier()

            if dictionary["success"] as? Bool == true {
                self = .result(identifier: identifier, data: .success(.init(value: dictionary["result"])))
            } else {
                self = .result(identifier: identifier, data: .failure(.responseError(.response(error: {
                    if let error = dictionary["error"] as? [String: Any],
                       let code = error["code"] as? Int,
                       let message = error["message"] as? String {
                        return (code, message)
                    } else {
                        return nil
                    }
                }()))))
            }

        case .event:
            let identifier = try parseIdentifier()

            let event = try HAWebSocketEvent(dictionary: dictionary["event"] as? [String: Any] ?? [:])
            self = .event(identifier: identifier, event: event)
        case .authRequired:
            self = .auth(.required)
        case .authOK:
            self = .auth(.ok)
        case .authInvalid:
            self = .auth(.invalid)
        case .none:
            throw HAWebSocketError.ResponseError.unknownType(type)
        }
    }
}
