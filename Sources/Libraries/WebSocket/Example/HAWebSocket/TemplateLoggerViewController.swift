import Foundation
import HAWebSocket
import UIKit

class TemplateLoggerViewController: UIViewController {
    let textView = UITextView()
    let websocket = HAConnection.api(configuration: .init(
        connectionInfo: {
            .init(url: URL(string: "http://127.0.0.1:8123/api/websocket")!)
        },
        fetchAuthToken: { completion in
            completion(.success(ProcessInfo.processInfo.environment["TOKEN"]!))
        }
    ))

    @objc private func toggle() {
        switch websocket.state {
        case .connecting, .ready: websocket.disconnect()
        case .disconnected: websocket.connect()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Toggle", style: .plain, target: self, action: #selector(toggle)),
        ]

        view.addSubview(textView)
        textView.frame = view.bounds

        textView.text = "initial"

        websocket.connect()
//        websocket.subscribe(to: .init(
//            type: .renderTemplate,
//            data: ["template": "{{ states.device_tracker | count }}"]
        ////            data: ["template": "{{ now() }} {{ states('sun.sun') }} {{ states.device_tracker | count }}"]
//        ), handler: { [textView] token, data in
//            if case let .dictionary(underlying) = data,
//               let result = underlying["result"] {
//                textView.text = String(describing: result)
//            }
//        })

        websocket.subscribe(
            to: .renderTemplate("{{ now() }} {{ states('sun.sun') }} {{ states.device_tracker | count }}"),
            initiated: { _ in },
            handler: { [textView] _, response in
                textView.text = String(describing: response.result)
                print(response)
//                token.cancel()
            }
        )

        websocket.send(.currentUser()) { result in
            switch result {
            case let .success(user):
                print(user)
            case let .failure(error):
                print(error)
            }
        }

        websocket.subscribe(
            to: .events(.all),
            initiated: { result in
                print(result)
            }, handler: { _, event in
                print(event)
            }
        )

        websocket.subscribe(to: .stateChanged(), handler: { _, event in
            print(event)
        })

//        websocket.subscribe(to:  .init(
//            type: .renderTemplate,
//            data: ["template": "{{ states.device_tracker | count }}"]
        ////            data: ["template": "{{ now() }} {{ states('sun.sun') }} {{ states.device_tracker | count }}"]
//        ), handler: { [textView] token, data in
//            if case let .dictionary(underlying) = data,
//               let result = underlying["result"] {
//                textView.text = String(describing: result)
//            }
//        })
    }
}
