extension HAWebSocketAPI: HAWebSocketRequestControllerDelegate {
    func requestControllerShouldSendRequests(_ requestController: HAWebSocketRequestController) -> Bool {
        if case .command = responseController.phase {
            return true
        } else {
            return false
        }
    }

    func requestController(
        _ requestController: HAWebSocketRequestController,
        didPrepareRequest request: HAWebSocketRequest,
        with identifier: HAWebSocketRequestIdentifier
    ) {
        var data = request.data
        data["id"] = identifier.rawValue
        data["type"] = request.type.rawValue

        print("sending \(data)")

        sendRaw(data) { _ in
        }
    }
}
