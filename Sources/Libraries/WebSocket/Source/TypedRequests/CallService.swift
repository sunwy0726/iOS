public extension HAWebSocketTypedRequest {
    static func callService(
        domain: String,
        service: String,
        data: [String: Any] = [:]
    ) -> HAWebSocketTypedSubscription<HAResponseVoid> {
        return .init(request: .init(type: .callService, data: [
            "domain": domain,
            "service": service,
            "service_data": data
        ]))
    }
}
