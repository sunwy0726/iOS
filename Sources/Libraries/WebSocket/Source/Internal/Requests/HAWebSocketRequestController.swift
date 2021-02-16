internal protocol HAWebSocketRequestControllerDelegate: AnyObject {
    func requestController(
        _ requestController: HAWebSocketRequestController,
        didPrepareRequest request: HAWebSocketRequest,
        with identifier: HAWebSocketRequestIdentifier
    )
}

internal class HAWebSocketRequestController {
    private struct State {
        var pending: Set<HAWebSocketRequestInvocation> = Set()
        var active: [HAWebSocketRequestIdentifier: HAWebSocketRequestInvocation] = [:]

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

    func add(_ invocation: HAWebSocketRequestInvocation) {
        mutate { state in
            state.pending.insert(invocation)
        }
    }

    func cancel(_ request: HAWebSocketRequestInvocation) {
        mutate { state in
            state.pending.remove(request)
        }

        request.cancel()
    }

    func resetActive() {
        mutate { state in
            for pending in state.pending {
                pending.identifier = nil
            }

            state.active.removeAll()
        }
    }

    private func invocation(for identifier: HAWebSocketRequestIdentifier) -> HAWebSocketRequestInvocation? {
        read { state in
            state.pending.first(where: { $0.identifier == identifier })
        }
    }

    func single(for identifier: HAWebSocketRequestIdentifier) -> HAWebSocketRequestInvocationSingle? {
        invocation(for: identifier) as? HAWebSocketRequestInvocationSingle
    }

    func subscription(for identifier: HAWebSocketRequestIdentifier) -> HAWebSocketRequestInvocationSubscription? {
        invocation(for: identifier) as? HAWebSocketRequestInvocationSubscription
    }

    func prepare() {
        let queue = DispatchQueue(label: "websocket-request-controller-callback", target: .main)
        queue.suspend()

        mutate(using: { state in
            for item in state.pending.filter(\.needsAssignment) {
                let identifier = state.identifierGenerator.next()
                state.active[identifier] = item
                item.identifier = identifier

                queue.async { [self] in
                    delegate?.requestController(self, didPrepareRequest: item.request, with: identifier)
                }
            }
        }, then: {
            queue.resume()
        })
    }
}
