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
        // let pageViewController = EMPageViewController(navigationOrientation: .Vertical)
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        // Set the initially selected view controller
        // IMPORTANT: If you are using a dataSource, make sure you set it BEFORE calling selectViewController:direction:animated:completion
        let currentViewController = self.viewController(at: 0)!
        pageViewController.selectViewController(currentViewController, direction: .forward, animated: false, completion: nil)
        
        // Add EMPageViewController to the root view controller
        self.addChild(pageViewController)
        self.view.insertSubview(pageViewController.view, at: 0) // Insert the page controller view below the navigation buttons
        pageViewController.didMove(toParent: self)
        
        self.pageViewController = pageViewController
    }
    
    
    // MARK: - Convienient EMPageViewController scroll / transition methods
    
    @IBAction func forward(_ sender: AnyObject) {
        self.pageViewController!.scrollForward(animated: true, completion: nil)
    }
    
    @IBAction func reverse(_ sender: AnyObject) {
        self.pageViewController!.scrollReverse(animated: true, completion: nil)
    }
    
    @IBAction func scrollTo(_ sender: AnyObject) {
        
        let choiceViewController = UIAlertController(title: "Scroll To...", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        let selectedIndex = self.index(of: self.pageViewController!.selectedViewController as! GreetingViewController)!
        
        for (index, viewControllerGreeting) in greetings.enumerated() {
            
            if (index != selectedIndex) {
            
                let action = UIAlertAction(title: viewControllerGreeting, style: UIAlertAction.Style.default, handler: { (alertAction) in
                    
                    let viewController = self.viewController(at: index)!
                    
                    let direction:EMPageViewControllerNavigationDirection = index > selectedIndex ? .forward : .reverse
                    
                    self.pageViewController!.selectViewController(viewController, direction: direction, animated: true, completion: nil)
                    
                })
                
                choiceViewController.addAction(action)
            }
        }
        
        let action = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
        choiceViewController.addAction(action)
        
        self.present(choiceViewController, animated: true, completion: nil)
        
    }
    
    // MARK: - EMPageViewController Data Source
    
    func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.index(of: viewController as! GreetingViewController) {
            let beforeViewController = self.viewController(at: viewControllerIndex - 1)
            return beforeViewController
        } else {
            return nil
        }
    }
    
    func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.index(of: viewController as! GreetingViewController) {
            let afterViewController = self.viewController(at: viewControllerIndex + 1)
            return afterViewController
        } else {
            return nil
        }
    }
    
    func viewController(at index: Int) -> GreetingViewController? {
        if (self.greetings.count == 0) || (index < 0) || (index >= self.greetings.count) {
            return nil
        }
        
        let viewController = self.storyboard!.instantiateViewController(withIdentifier: "GreetingViewController") as! GreetingViewController
        viewController.greeting = self.greetings[index]
        viewController.color = self.greetingColors[index]
        return viewController
    }
    
    func index(of viewController: GreetingViewController) -> Int? {
        if let greeting: String = viewController.greeting {
            return self.greetings.firstIndex(of: greeting)
        } else {
            return nil
        }
    }
    
    
    // MARK: - EMPageViewController Delegate

    func em_pageViewController(_ pageViewController: EMPageViewController, willStartScrollingFrom startViewController: UIViewController, destinationViewController: UIViewController) {
        
        let startGreetingViewController = startViewController as! GreetingViewController
        let destinationGreetingViewController = destinationViewController as! GreetingViewController
        
        print("Will start scrolling from \(startGreetingViewController.greeting!) to \(destinationGreetingViewController.greeting!).")
    }
    
    func em_pageViewController(_ pageViewController: EMPageViewController, isScrollingFrom startViewController: UIViewController, destinationViewController: UIViewController, progress: CGFloat) {
        let startGreetingViewController = startViewController as! GreetingViewController
        let destinationGreetingViewController = destinationViewController as! GreetingViewController
        
        // Ease the labels' alphas in and out
        let absoluteProgress = abs(progress)
        startGreetingViewController.label.alpha = pow(1 - absoluteProgress, 2)
        destinationGreetingViewController.label.alpha = pow(absoluteProgress, 2)
        
       print("Is scrolling from \(startGreetingViewController.greeting!) to \(destinationGreetingViewController.greeting!) with progress '\(progress)'.")
    }
    
    func em_pageViewController(_ pageViewController: EMPageViewController, didFinishScrollingFrom startViewController: UIViewController?, destinationViewController: UIViewController, transitionSuccessful: Bool) {
        let startViewController = startViewController as! GreetingViewController?
        let destinationViewController = destinationViewController as! GreetingViewController
        
        // If the transition is successful, the new selected view controller is the destination view controller.
        // If it wasn't successful, the selected view controller is the start view controller
        if transitionSuccessful {
            
            if (self.index(of: destinationViewController) == 0) {
                self.reverseButton.isEnabled = false
            } else {
                self.reverseButton.isEnabled = true
            }
            
            if (self.index(of: destinationViewController) == self.greetings.count - 1) {
                self.forwardButton.isEnabled = false
            } else {
                self.forwardButton.isEnabled = true
            }
        }
        
        print("Finished scrolling from \(startViewController != nil ? startViewController!.greeting! : "nil") to \(destinationViewController.greeting!). Transition successful? \(transitionSuccessful)")
    }
    
}

