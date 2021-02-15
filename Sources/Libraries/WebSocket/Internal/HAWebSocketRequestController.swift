internal protocol HAWebSocketRequestControllerDelegate: AnyObject {
    func 
}

internal class HAWebSocketRequestController {
    enum RequestType: Hashable {
        case request(HAWebSocketRequestInvocation)
        case subscription(HAWebSocketSubscription)

        var needsAssignment: Bool {
            request?.requestIdentifier == nil && subscription?.subscriptionIdentifier == nil
        }

        func assign(identifier: HAWebSocketRequestIdentifier) {
            switch self {
            case let .request(request):
                request.requestIdentifier = identifier
            case let .subscription(subscription):
                subscription.subscriptionIdentifier = identifier
            }
        }

        var request: HAWebSocketRequestInvocation? {
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

    private var state: State = .init() {
        willSet {
            dispatchPrecondition(condition: .onQueueAsBarrier(stateQueue))
        }
    }

    private var stateQueue = DispatchQueue(label: "hawebsocket-request-state")

    private func mutate(using handler: @escaping (inout State) -> Void) {
        dispatchPrecondition(condition: .notOnQueue(stateQueue))
        stateQueue.async(execute: .init(qos: .default, flags: .barrier, block: { [self] in
            handler(&state)
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
            state.pending.compactMap(\.request).first(where: { $0.requestIdentifier == identifier })
        }
    }

    func subscription(for identifier: HAWebSocketRequestIdentifier) -> HAWebSocketSubscription? {
        read { state in
            state.pending.compactMap(\.subscription).first(where: { $0.subscriptionIdentifier == identifier })
        }
    }

    func enumerateAssigning(on queue: DispatchQueue = .main, handler: @escaping (RequestType) -> Void) {
        mutate { state in
            let pending = state.pending.filter(\.needsAssignment)
            for item in pending {
                let identifier = state.identifierGenerator.next()
                state.active[identifier] = item
                item.assign(identifier: identifier)
            }

            queue.async {
                for item in pending {
                    handler(item)
                }
            }
        }
    }
}
