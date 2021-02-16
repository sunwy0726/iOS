import Foundation
import UIKit
import HAWebSocket

class TemplateLoggerViewController: UIViewController {
    let textView = UITextView()
    let websocket = HAWebSocket.api(configuration: .init(
        connectionInfo: {
            .init(url: URL(string: "http://127.0.0.1:8123/api/websocket")!)
        },
        fetchAuthToken: { completion in
            completion(.success(ProcessInfo.processInfo.environment["TOKEN"]!))
        }
    ))

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(textView)
        textView.frame = view.bounds

        textView.text = "initial"

        websocket.connect()
        websocket.subscribe(to: .init(
            type: .renderTemplate,
            data: ["template": "{{ now() }}"]
        ), handler: { [textView] token, data in
            if case let .dictionary(underlying) = data,
               let result = underlying["result"] as? String {
                textView.text = result
            }
        })
    }
}
