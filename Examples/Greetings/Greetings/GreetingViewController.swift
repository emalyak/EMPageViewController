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
    var greeting:String!
    var color:UIColor!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = color
        self.label.text = greeting
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        println("viewWillAppear: \(self.greeting)")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        println("viewDidAppear: \(self.greeting)")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        println("viewWillDisappear: \(self.greeting)")
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        println("viewDidDisappear: \(self.greeting)")
    }
    
    deinit {
        println("deinit: \(self.greeting)")
    }

}
