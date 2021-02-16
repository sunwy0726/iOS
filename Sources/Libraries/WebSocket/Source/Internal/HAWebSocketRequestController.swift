internal protocol HAWebSocketRequestControllerDelegate: AnyObject {
    func requestController(
        _ requestController: HAWebSocketRequestController,
        didPrepareRequest request: HAWebSocketRequest,
        with identifier: HAWebSocketRequestIdentifier
    )
}

internal class HAWebSocketRequestController {
    enum RequestType: Hashable {
        case request(HAWebSocketRequestInvocation)
        case subscription(HAWebSocketSubscription)

        var requestIdentifier: HAWebSocketRequestIdentifier? {
            requestInvocation?.requestIdentifier ?? subscription?.subscriptionIdentifier
        }

        var needsAssignment: Bool {
            requestIdentifier == nil
        }

        func assign(identifier: HAWebSocketRequestIdentifier) {
            switch self {
            case let .request(request):
                request.requestIdentifier = identifier
            case let .subscription(subscription):
                subscription.subscriptionIdentifier = identifier
            }
        }

        var request: HAWebSocketRequest {
            switch self {
            case .request(let request): return request.request
            case .subscription(let subscription): return subscription.request
            }
        }

        var requestInvocation: HAWebSocketRequestInvocation? {
            if case let .request(request) = self {
                return request
            } else {
                return nil
            }
        }

        var subscription: HAWebSocketSubscription? {
            if case let .subscription(subscription) = self {
                return subscription
            } else {
                return nil
            }
        }
    }

    private struct State {
        var pending: Set<RequestType> = Set()
        var active: [HAWebSocketRequestIdentifier: RequestType] = [:]

        struct IdentifierGenerator {
            private var lastIdentifierInteger = 0

            mutating func next() -> HAWebSocketRequestIdentifier {
                lastIdentifierInteger += 1
                return .init(rawValue: lastIdentifierInteger)
            }
        }
        var identifierGenerator = IdentifierGenerator()
    }

    weak var delegate: HAWebSocketRequestControllerDelegate?

    private var state: State = .init() {
        willSet {
            dispatchPrecondition(condition: .onQueueAsBarrier(stateQueue))
        }
    }

    private var stateQueue = DispatchQueue(label: "hawebsocket-request-state")

    private func mutate(using handler: @escaping (inout State) -> Void, then perform: @escaping () -> Void = {}) {
        dispatchPrecondition(condition: .notOnQueue(stateQueue))
        stateQueue.async(execute: .init(qos: .default, flags: .barrier, block: { [self] in
            handler(&state)
            DispatchQueue.main.async(execute: perform)
        }))
    }

    private func read<T>(using handler: (State) -> T) -> T {
        dispatchPrecondition(condition: .notOnQueue(stateQueue))
        return stateQueue.sync {
            let result = handler(state)
            assert(result as? State == nil)
            return result
        }
    }

    func add(_ request: HAWebSocketRequestInvocation) {
        mutate { state in
            state.pending.insert(.request(request))
        }
    }

    func add(_ subscription: HAWebSocketSubscription) {
        mutate { state in
            state.pending.insert(.subscription(subscription))
        }
    }

    func cancel(_ request: HAWebSocketRequestInvocation) {
        mutate { state in
            state.pending.remove(.request(request))
        }

        request.cancel()
    }

    func cancel(_ subscription: HAWebSocketSubscription) {
        mutate { state in
            state.pending.remove(.subscription(subscription))
        }

        subscription.cancel()
    }

    func resetActive() {
        mutate { state in
            for pending in state.pending {
                switch pending {
                case let .request(request):
                    request.requestIdentifier = nil
                case let .subscription(subscription):
                    subscription.subscriptionIdentifier = nil
                }
            }

            state.active.removeAll()
        }
    }

    func request(for identifier: HAWebSocketRequestIdentifier) -> HAWebSocketRequestInvocation? {
        read { state in
            state.pending.compactMap(\.requestInvocation).first(where: { $0.requestIdentifier == identifier })
        }
    }

    func subscription(for identifier: HAWebSocketRequestIdentifier) -> HAWebSocketSubscription? {
        read { state in
            state.pending.compactMap(\.subscription).first(where: { $0.subscriptionIdentifier == identifier })
        }
    }

    func prepare() {
        let queue = DispatchQueue(label: "websocket-request-controller-callback", target: .main)
        queue.suspend()

        mutate(using: { state in
            for item in state.pending.filter(\.needsAssignment) {
                let identifier = state.identifierGenerator.next()
                state.active[identifier] = item
                item.assign(identifier: identifier)

                queue.async { [self] in
                    delegate?.requestController(self, didPrepareRequest: item.request, with: identifier)
                }
            }
        }, then: {
            queue.resume()
        })
    }
}
