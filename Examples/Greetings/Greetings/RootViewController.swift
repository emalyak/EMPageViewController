//
//  RootViewController.swift
//  EMPageViewController
//
//  Created by Erik Malyak on 3/16/15.
//  Copyright (c) 2015 Erik Malyak. All rights reserved.
//

import UIKit
import EMPageViewController

class RootViewController: UIViewController, EMPageViewControllerDataSource, EMPageViewControllerDelegate {

    @IBOutlet weak var reverseButton: UIButton!
    @IBOutlet weak var scrollToButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    var pageViewController: EMPageViewController?
    
    var greetings: [String] = ["Hello!", "¡Hola!", "Salut!", "Hallo!", "Ciao!"]
    var greetingColors: [UIColor] = [
        UIColor(red: 108.0/255.0, green: 122.0/255.0, blue: 137.0/255.0, alpha: 1.0),
        UIColor(red: 135.0/255.0, green: 211.0/255.0, blue: 124.0/255.0, alpha: 1.0),
        UIColor(red: 34.0/255.0, green: 167.0/255.0, blue: 240.0/255.0, alpha: 1.0),
        UIColor(red: 245.0/255.0, green: 171.0/255.0, blue: 53.0/255.0, alpha: 1.0),
        UIColor(red: 214.0/255.0, green: 69.0/255.0, blue: 65.0/255.0, alpha: 1.0)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate EMPageViewController and set the data source and delegate to 'self'
        let pageViewController = EMPageViewController()
        
        // Or, for a vertical orientation
        // let pageViewController = EMPageViewController(orientation: .Vertical)
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        // Set the initially selected view controller
        // IMPORTANT: If you are using a dataSource, make sure you set it BEFORE calling selectViewController:direction:animated:completion
        let currentViewController = self.viewControllerAtIndex(0)!
        pageViewController.selectViewController(currentViewController, direction: .Forward, animated: false, completion: nil)
        
        // Add EMPageViewController to the root view controller
        self.addChildViewController(pageViewController)
        self.view.insertSubview(pageViewController.view, atIndex: 0) // Insert the page controller view below the navigation buttons
        pageViewController.didMoveToParentViewController(self)
        
        self.pageViewController = pageViewController
    }
    
    
    // MARK: - Convienient EMPageViewController scroll / transition methods
    
    @IBAction func forward(sender: AnyObject) {
        self.pageViewController!.scrollForwardAnimated(true, completion: nil)
    }
    
    @IBAction func reverse(sender: AnyObject) {
        self.pageViewController!.scrollReverseAnimated(true, completion: nil)
    }
    
    @IBAction func scrollTo(sender: AnyObject) {
        
        let choiceViewController = UIAlertController(title: "Scroll To...", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let selectedIndex = self.indexOfViewController(self.pageViewController!.selectedViewController as! GreetingViewController)
        
        for (index, viewControllerGreeting) in greetings.enumerate() {
            
            if (index != selectedIndex) {
            
                let action = UIAlertAction(title: viewControllerGreeting, style: UIAlertActionStyle.Default, handler: { (alertAction) in
                    
                    let viewController = self.viewControllerAtIndex(index)!
                    
                    let direction:EMPageViewControllerNavigationDirection = index > selectedIndex ? .Forward : .Reverse
                    
                    self.pageViewController!.selectViewController(viewController, direction: direction, animated: true, completion: nil)
                    
                })
                
                choiceViewController.addAction(action)
            }
        }
        
        let action = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        choiceViewController.addAction(action)
        
        self.presentViewController(choiceViewController, animated: true, completion: nil)
        
    }
    
    // MARK: - EMPageViewController Data Source
    
    func em_pageViewController(pageViewController: EMPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.indexOfViewController(viewController as! GreetingViewController) {
            let beforeViewController = self.viewControllerAtIndex(viewControllerIndex - 1)
            return beforeViewController
        } else {
            return nil
        }
    }
    
    func em_pageViewController(pageViewController: EMPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.indexOfViewController(viewController as! GreetingViewController) {
            let afterViewController = self.viewControllerAtIndex(viewControllerIndex + 1)
            return afterViewController
        } else {
            return nil
        }
    }
    
    func viewControllerAtIndex(index: Int) -> GreetingViewController? {
        if (self.greetings.count == 0) || (index < 0) || (index >= self.greetings.count) {
            return nil
        }
        
        let viewController = self.storyboard!.instantiateViewControllerWithIdentifier("GreetingViewController") as! GreetingViewController
        viewController.greeting = self.greetings[index]
        viewController.color = self.greetingColors[index]
        return viewController
    }
    
    func indexOfViewController(viewController: GreetingViewController) -> Int? {
        if let greeting: String = viewController.greeting {
            return self.greetings.indexOf(greeting)
        } else {
            return nil
        }
    }
    
    
    // MARK: - EMPageViewController Delegate

    func em_pageViewController(pageViewController: EMPageViewController, willStartScrollingFrom startViewController: UIViewController, destinationViewController: UIViewController) {
        
        let startGreetingViewController = startViewController as! GreetingViewController
        let destinationGreetingViewController = destinationViewController as! GreetingViewController
        
        print("Will start scrolling from \(startGreetingViewController.greeting) to \(destinationGreetingViewController.greeting).")
    }
    
    func em_pageViewController(pageViewController: EMPageViewController, isScrollingFrom startViewController: UIViewController, destinationViewController: UIViewController, progress: CGFloat) {
        let startGreetingViewController = startViewController as! GreetingViewController
        let destinationGreetingViewController = destinationViewController as! GreetingViewController
        
        // Ease the labels' alphas in and out
        let absoluteProgress = fabs(progress)
        startGreetingViewController.label.alpha = pow(1 - absoluteProgress, 2)
        destinationGreetingViewController.label.alpha = pow(absoluteProgress, 2)
        
       print("Is scrolling from \(startGreetingViewController.greeting) to \(destinationGreetingViewController.greeting) with progress '\(progress)'.")
    }
    
    func em_pageViewController(pageViewController: EMPageViewController, didFinishScrollingFrom startViewController: UIViewController?, destinationViewController: UIViewController, transitionSuccessful: Bool) {
        let startViewController = startViewController as! GreetingViewController?
        let destinationViewController = destinationViewController as! GreetingViewController
        
        // If the transition is successful, the new selected view controller is the destination view controller.
        // If it wasn't successful, the selected view controller is the start view controller
        if transitionSuccessful {
            
            if (self.indexOfViewController(destinationViewController) == 0) {
                self.reverseButton.enabled = false
            } else {
                self.reverseButton.enabled = true
            }
            
            if (self.indexOfViewController(destinationViewController) == self.greetings.count - 1) {
                self.forwardButton.enabled = false
            } else {
                self.forwardButton.enabled = true
            }
        }
        
        print("Finished scrolling from \(startViewController?.greeting) to \(destinationViewController.greeting). Transition successful? \(transitionSuccessful)")
    }
    
}

