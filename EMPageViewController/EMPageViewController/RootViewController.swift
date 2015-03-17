//
//  RootViewController.swift
//  EMPageViewController
//
//  Created by Erik Malyak on 3/16/15.
//  Copyright (c) 2015 Erik Malyak. All rights reserved.
//

import UIKit

class RootViewController: UIViewController, EMPageViewControllerDataSource {

    var pageViewController:EMPageViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate EMPageViewController and set the data source to 'self'
        let pageViewController = EMPageViewController()
        pageViewController.dataSource = self
        
        // Set the initially selected view controller
        let currentViewController = self.storyboard!.instantiateViewControllerWithIdentifier("DemoViewController") as UIViewController
        currentViewController.view.backgroundColor = UIColor(red: 52.0/255.0, green: 73.0/255.0, blue: 94.0/255.0, alpha: 1.0)
        pageViewController.setCurrentViewController(currentViewController, animated: false, completion: nil)
        
        // Add EMPageViewController to the root view controller
        self.addChildViewController(pageViewController)
        self.view.addSubview(pageViewController.view)
        pageViewController.didMoveToParentViewController(self)
        
        self.pageViewController = pageViewController
    }
    
    
    // MARK: - EMPageViewController Data Source
    
    func em_pageViewController(pageViewController: EMPageViewController, viewControllerLeftOfViewController viewController: UIViewController) -> UIViewController? {
        let leftViewController = self.storyboard!.instantiateViewControllerWithIdentifier("DemoViewController") as UIViewController
        leftViewController.view.backgroundColor = UIColor(red: 52.0/255.0, green: 152.0/255.0, blue: 219.0/255.0, alpha: 1.0)
        return leftViewController
    }
    
    func em_pageViewController(pageViewController: EMPageViewController, viewControllerRightOfViewController viewController: UIViewController) -> UIViewController? {
        let rightViewController = self.storyboard!.instantiateViewControllerWithIdentifier("DemoViewController") as UIViewController
        rightViewController.view.backgroundColor = UIColor(red: 231.0/255.0, green: 76.0/255.0, blue: 60.0/255.0, alpha: 1.0)
        return rightViewController
    }

}

