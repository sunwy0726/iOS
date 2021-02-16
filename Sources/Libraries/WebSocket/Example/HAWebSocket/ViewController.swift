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

    @IBAction func push(_ sender: Any) {
        present(TemplateLoggerViewController(), animated: true, completion: nil)
    }
}

