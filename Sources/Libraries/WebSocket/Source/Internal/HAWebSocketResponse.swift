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

    enum TempError: Error {
        case parseError(String)
    }

    init(dictionary: [String: Any]) throws {
        guard let type = dictionary["type"] as? String else {
            throw TempError.parseError("type is not valid")
        }

        func parseIdentifier() throws -> HAWebSocketRequestIdentifier {
            if let value = (dictionary["id"] as? Int).flatMap(HAWebSocketRequestIdentifier.init(rawValue:)) {
                return value
            } else {
                throw TempError.parseError("id is not valid")
            }
        }

        switch ResponseType(rawValue: type) {
        case .result:
            let identifier = try parseIdentifier()

            if dictionary["success"] as? Bool == true {
                self = .result(identifier: identifier, result: .success(.init(value: dictionary["result"])))
            } else {
                let externalError: HAWebSocketError.ExternalError

                if let error = dictionary["error"] as? [String: Any],
                   let code = error["code"] as? Int,
                   let message = error["message"] as? String {
                    externalError = .init(code: code, message: message)
                } else {
                    externalError = .init(code: -1, message: "unable to parse error response")
                }

                self = .result(identifier: identifier, result: .failure(.init(type: .external(externalError))))
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
