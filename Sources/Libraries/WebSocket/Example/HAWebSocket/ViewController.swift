//
//  ViewController.swift
//  HAWebSocket
//
//  Created by Zac West on 02/15/2021.
//  Copyright (c) 2021 Zac West. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        push(nil)
    }

    @IBAction func push(_ sender: Any?) {
        let controller = TemplateLoggerViewController()
        let navController = UINavigationController(rootViewController: controller)
        present(navController, animated: true, completion: nil)
    }
}

