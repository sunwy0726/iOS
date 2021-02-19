import Starscream

internal protocol HAWebSocketResponseControllerDelegate: AnyObject {
    func responseController(
        _ controller: HAWebSocketResponseController,
        didTransitionTo phase: HAWebSocketResponseController.Phase
    )
    func responseController(_ controller: HAWebSocketResponseController, didReceive response: HAWebSocketResponse)
}

internal class HAWebSocketResponseController {
    weak var delegate: HAWebSocketResponseControllerDelegate?

    enum Phase {
        case disconnected
        case auth
        case command
    }

    var phase: Phase = .disconnected {
        didSet {
            HAWebSocketGlobalConfig.log("phase transition to \(phase)")
            delegate?.responseController(self, didTransitionTo: phase)
        }
    }

    func didUpdate(to webSocket: WebSocket?) {
        phase = .disconnected
    }
}

extension HAWebSocketResponseController: Starscream.WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: WebSocket) {
        switch event {
        case let .connected(headers):
            HAWebSocketGlobalConfig.log("connected with headers: \(headers)")
            phase = .auth
        case let .disconnected(reason, code):
            HAWebSocketGlobalConfig.log("disconnected: \(reason) with code: \(code)")
            phase = .disconnected
        case let .text(string):
            HAWebSocketGlobalConfig.log("Received text: \(string)")
            do {
                if let data = string.data(using: .utf8),
                   let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let response = try HAWebSocketResponse(dictionary: json)

                    if case .auth(.ok) = response {
                        phase = .command
                    }

                    delegate?.responseController(self, didReceive: response)
                }
            } catch {
                HAWebSocketGlobalConfig.log("text parse error: \(error)")
            }
        case let .binary(data):
            HAWebSocketGlobalConfig.log("Received binary data: \(data.count)")
        case .ping, .pong:
            break
        case .reconnectSuggested:
            break
        case .viabilityChanged:
            break
        case .cancelled:
            phase = .disconnected
        case let .error(error):
            HAWebSocketGlobalConfig.log("connection error: \(String(describing: error))")
            phase = .disconnected
        }
    }
}
