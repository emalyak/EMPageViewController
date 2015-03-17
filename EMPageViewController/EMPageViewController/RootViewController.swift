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
    
    var viewControllerGreetings:[String] = ["Hello!", "¡Hola!", "Salut!", "Hallo!", "Ciao!"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate EMPageViewController and set the data source to 'self'
        let pageViewController = EMPageViewController()
        pageViewController.dataSource = self
        
        // Set the initially selected view controller
        let currentViewController = self.viewControllerAtIndex(0)!
        pageViewController.setCurrentViewController(currentViewController, animated: false, completion: nil)
        
        // Add EMPageViewController to the root view controller
        self.addChildViewController(pageViewController)
        self.view.addSubview(pageViewController.view)
        pageViewController.didMoveToParentViewController(self)
        
        self.pageViewController = pageViewController
    }
    
    
    // MARK: - EMPageViewController Data Source
    
    func em_pageViewController(pageViewController: EMPageViewController, viewControllerLeftOfViewController viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.indexOfViewController(viewController as GreetingViewController) {
            let leftViewController = self.viewControllerAtIndex(viewControllerIndex - 1)
            return leftViewController
        } else {
            return nil
        }
    }
    
    func em_pageViewController(pageViewController: EMPageViewController, viewControllerRightOfViewController viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.indexOfViewController(viewController as GreetingViewController) {
            let rightViewController = self.viewControllerAtIndex(viewControllerIndex + 1)
            return rightViewController
        } else {
            return nil
        }
    }
    
    func viewControllerAtIndex(index: Int) -> GreetingViewController? {
        if (self.viewControllerGreetings.count == 0) || (index < 0) || (index >= self.viewControllerGreetings.count) {
            return nil
        }
        
        let viewController = self.storyboard!.instantiateViewControllerWithIdentifier("GreetingViewController") as GreetingViewController
        viewController.greeting = self.viewControllerGreetings[index]
        return viewController
    }
    
    func indexOfViewController(viewController: GreetingViewController) -> Int? {
        if let greeting: String = viewController.greeting {
            return find(self.viewControllerGreetings, greeting)
        } else {
            return nil
        }
    }


}

