public extension HATypedRequest {
    static func callService(
        domain: String,
        service: String,
        data: [String: Any] = [:]
    ) -> HATypedRequest<HAResponseVoid> {
        .init(request: .init(type: .callService, data: [
            "domain": domain,
            "service": service,
            "service_data": data,
        ]))
    }
}
