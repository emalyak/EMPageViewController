//
//  DemoViewController.swift
//  EMPageViewController
//
//  Created by Erik Malyak on 3/17/15.
//  Copyright (c) 2015 Erik Malyak. All rights reserved.
//

import UIKit

class GreetingViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    var greeting:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.label.text = greeting!
    }

}
