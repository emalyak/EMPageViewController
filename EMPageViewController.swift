/*

  EMPageViewController.swift
  EMPageViewController

  Created by Erik Malyak on 3/16/15.
  Copyright (c) 2015 Erik Malyak

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

*/

import UIKit


@objc protocol EMPageViewControllerDataSource {
    func em_pageViewController(pageViewController:EMPageViewController, viewControllerLeftOfViewController viewController:UIViewController) -> UIViewController?
    func em_pageViewController(pageViewController:EMPageViewController, viewControllerRightOfViewController viewController:UIViewController) -> UIViewController?
}

@objc protocol EMPageViewControllerDelegate {
    optional func em_pageViewController(pageViewController:EMPageViewController, willStartScrollingFrom startingViewController:UIViewController, destinationViewController:UIViewController)
    optional func em_pageViewController(pageViewController:EMPageViewController, didFinishScrollingFrom previousViewController:UIViewController?, selectedViewController:UIViewController, transitionSuccessful:Bool)
    optional func em_pageViewController(pageViewController:EMPageViewController, isScrollingFrom startingViewController:UIViewController, destinationViewController:UIViewController, progress:CGFloat)
}

enum EMPageViewControllerNavigationDirection : Int {
    case Forward
    case Reverse
}

class EMPageViewController: UIViewController, UIScrollViewDelegate {
    
    weak var dataSource:EMPageViewControllerDataSource!
    weak var delegate:EMPageViewControllerDelegate?

    private let scrollView:UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.pagingEnabled = true
        scrollView.scrollsToTop = false
        scrollView.autoresizingMask = .FlexibleTopMargin | .FlexibleRightMargin | .FlexibleBottomMargin | .FlexibleLeftMargin
        scrollView.bounces = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.setTranslatesAutoresizingMaskIntoConstraints(true)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    
    private var leftViewController:UIViewController?
    private(set) var selectedViewController:UIViewController?
    private var rightViewController:UIViewController?
    
    private var adjustingContentOffset = false // Flag used to prevent isScrolling delegate when shifting scrollView
    var scrolling = false // Flag to make sure willStartScrollingFrom is only called once
    var navigationDirection:EMPageViewControllerNavigationDirection?
    var reloadViewControllersOnFinish = false
    private var didFinishScrollingCompletionHandler:((transitionSuccessful:Bool)->())?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        self.view.addSubview(scrollView)
    }
    
    
    func setInitialViewController(viewController:UIViewController) {
        
        self.loadViewControllers(viewController)
        self.layoutViews()

    }
    
    func selectViewController(viewController:UIViewController, direction:EMPageViewControllerNavigationDirection, animated:Bool, completion:((transitionSuccessful:Bool)->())?) {
        
        if (direction == .Forward) {
            self.rightViewController = viewController
            self.layoutViews()
            self.reloadViewControllersOnFinish = true
            self.scrollForward(animated, completion: completion)
        } else if (direction == .Reverse) {
            self.leftViewController = viewController
            self.layoutViews()
            self.reloadViewControllersOnFinish = true
            self.scrollReverse(animated, completion: completion)
        }
        
    }
    
    func scrollForward(animated:Bool, completion:((transitionSuccessful:Bool)->())?) {
        if (self.rightViewController != nil) {
            self.didFinishScrollingCompletionHandler?(transitionSuccessful: false)
            self.didFinishScrollingCompletionHandler = nil
            
            self.didFinishScrollingCompletionHandler = completion
            self.scrollView.setContentOffset(CGPoint(x: self.view.bounds.width * 2, y: 0), animated: animated)
        }
    }
    
    func scrollReverse(animated:Bool, completion:((transitionSuccessful:Bool)->())?) {
        if (self.leftViewController != nil) {
            self.didFinishScrollingCompletionHandler?(transitionSuccessful: false)
            self.didFinishScrollingCompletionHandler = nil
            
            self.didFinishScrollingCompletionHandler = completion
            self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: animated)
        }
    }
    
    private func loadViewControllers(selectedViewController:UIViewController) {
        
        assert(self.dataSource != nil, "EMPageViewController Data Source must be set.")
        
        // Scrolled forward
        if (selectedViewController == self.rightViewController) {
            
            self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.selectedViewController!, selectedViewController: self.rightViewController!, transitionSuccessful: true)
            
            self.didFinishScrollingCompletionHandler?(transitionSuccessful: true)
            self.didFinishScrollingCompletionHandler = nil
            
            self.removeChildIfNeeded(self.selectedViewController)
            
            if self.reloadViewControllersOnFinish {
                self.leftViewController = self.dataSource.em_pageViewController(self, viewControllerLeftOfViewController: selectedViewController)
                self.reloadViewControllersOnFinish = false
            } else {
                // Set new left controller as the old current controller
                self.leftViewController = self.selectedViewController
            }
            
            // Set the new current controller as the old right controller
            self.selectedViewController = self.rightViewController
            
            // Retreive the new right controller from the data source if available, otherwise set as nil
            self.rightViewController = self.dataSource.em_pageViewController(self, viewControllerRightOfViewController: selectedViewController)
            
            
        // Scrolled reverse
        } else if (selectedViewController == self.leftViewController) {
            
            self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.selectedViewController!, selectedViewController: self.leftViewController!, transitionSuccessful: true)
            
            self.didFinishScrollingCompletionHandler?(transitionSuccessful: true)
            self.didFinishScrollingCompletionHandler = nil
            
            self.removeChildIfNeeded(self.selectedViewController)
            
            if self.reloadViewControllersOnFinish {
                self.rightViewController = self.dataSource.em_pageViewController(self, viewControllerRightOfViewController: selectedViewController)
                self.reloadViewControllersOnFinish = false
            } else {
                // Set new right controller as the old current controller
                self.rightViewController = self.selectedViewController
            }
            
            // Set the new current controller as the old left controller
            self.selectedViewController = self.leftViewController
            
            // Retreive the new left controller from the data source if available, otherwise set as nil
            self.leftViewController = self.dataSource.em_pageViewController(self, viewControllerLeftOfViewController: selectedViewController)
            
        
        // Scrolled but ended up where started
        } else if (selectedViewController == self.selectedViewController) {
            
            if (self.navigationDirection == .Forward) {
                self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.selectedViewController!, selectedViewController: self.rightViewController!, transitionSuccessful: false)
            } else if (self.navigationDirection == .Reverse) {
                self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.selectedViewController!, selectedViewController: self.leftViewController!, transitionSuccessful: false)
            }
            
            self.didFinishScrollingCompletionHandler?(transitionSuccessful: false)
            self.didFinishScrollingCompletionHandler = nil
            
            // Remove hidden view controllers
            self.removeChildIfNeeded(self.leftViewController)
            self.removeChildIfNeeded(self.rightViewController)
            
        // Initialization
        } else {
            
            // Set controller as current
            self.selectedViewController = selectedViewController
            
            // Show view controller
            self.addChildIfNeeded(self.selectedViewController!)
            
            // Retreive left and right view controllers if available
            self.leftViewController = self.dataSource.em_pageViewController(self, viewControllerLeftOfViewController: selectedViewController)
            self.rightViewController = self.dataSource.em_pageViewController(self, viewControllerRightOfViewController: selectedViewController)
        }
        
        self.navigationDirection = nil
        self.scrolling = false
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.scrollView.frame = self.view.bounds
        self.scrollView.contentSize = CGSize(width: self.view.bounds.width * 3, height: self.view.bounds.height)
        self.layoutViews()
    }
    
    private func addChildIfNeeded(viewController:UIViewController) {
        self.scrollView.addSubview(viewController.view)
        self.addChildViewController(viewController)
        viewController.didMoveToParentViewController(self)
    }
    
    private func removeChildIfNeeded(viewController:UIViewController?) {
        viewController?.view.removeFromSuperview()
        viewController?.didMoveToParentViewController(nil)
        viewController?.removeFromParentViewController()
    }
    
    func layoutViews() {
        let viewWidth = self.view.bounds.width
        let viewHeight = self.view.bounds.height
        
        var leftInset:CGFloat = 0
        var rightInset:CGFloat = 0
        
        if (self.leftViewController == nil) {
            leftInset = -viewWidth
        }
        
        if (self.rightViewController == nil) {
            rightInset = -viewWidth
        }
        
        self.adjustingContentOffset = true
        self.scrollView.contentOffset = CGPoint(x: viewWidth, y: 0)
        self.adjustingContentOffset = false
        
        self.scrollView.contentInset = UIEdgeInsetsMake(0, leftInset, 0, rightInset)
        
        self.leftViewController?.view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        self.selectedViewController?.view.frame = CGRect(x: viewWidth, y: 0, width: viewWidth, height: viewHeight)
        self.rightViewController?.view.frame = CGRect(x: viewWidth * 2, y: 0, width: viewWidth, height: viewHeight)
    }
    
    private func willScrollFromViewController(startingViewController:UIViewController, destinationViewController:UIViewController) {
        self.addChildIfNeeded(destinationViewController)
        self.delegate?.em_pageViewController?(self, willStartScrollingFrom: startingViewController, destinationViewController: destinationViewController)
    }
    
    private func didFinishScrollingToViewController(viewController:UIViewController) {
        self.loadViewControllers(viewController)
        self.layoutViews()
    }
    
    
    // MARK: - UIScrollView Delegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if !adjustingContentOffset {
        
            let viewWidth = self.view.bounds.width
            let progress = (scrollView.contentOffset.x - viewWidth) / viewWidth
            
            // Scrolling forward / right
            if (progress > 0) {
                if (self.rightViewController != nil) {
                    if !scrolling { // call willScroll once
                        self.willScrollFromViewController(self.selectedViewController!, destinationViewController: self.rightViewController!)
                        self.scrolling = true
                    }
                    
                    if self.navigationDirection == .Reverse { // check if direction changed
                        self.didFinishScrollingToViewController(self.selectedViewController!)
                        self.willScrollFromViewController(self.selectedViewController!, destinationViewController: self.rightViewController!)
                    }
                    
                    self.navigationDirection = .Forward
                    
                    self.delegate?.em_pageViewController?(self, isScrollingFrom: self.selectedViewController!, destinationViewController: self.rightViewController!, progress: progress)
                }
                
            // Scrolling reverse / left
            } else if (progress < 0) {
                if (self.leftViewController != nil) {
                    if !scrolling { // call willScroll once
                        self.willScrollFromViewController(self.selectedViewController!, destinationViewController: self.leftViewController!)
                        self.scrolling = true
                    }
                    
                    if self.navigationDirection == .Forward { // check if direction changed
                        self.didFinishScrollingToViewController(self.selectedViewController!)
                        self.willScrollFromViewController(self.selectedViewController!, destinationViewController: self.leftViewController!)
                    }
                    
                    self.navigationDirection = .Reverse
                    
                    self.delegate?.em_pageViewController?(self, isScrollingFrom: self.selectedViewController!, destinationViewController: self.leftViewController!, progress: progress)
                }
                
            // At zero
            } else {
                if (self.navigationDirection == .Forward) {
                    self.delegate?.em_pageViewController?(self, isScrollingFrom: self.selectedViewController!, destinationViewController: self.rightViewController!, progress: progress)
                } else if (self.navigationDirection == .Reverse) {
                    self.delegate?.em_pageViewController?(self, isScrollingFrom: self.selectedViewController!, destinationViewController: self.leftViewController!, progress: progress)
                }
            }
            
            // Thresholds to update view layouts call delegates
            if (progress >= 1 && self.rightViewController != nil) {
                self.didFinishScrollingToViewController(self.rightViewController!)
            } else if (progress <= -1  && self.leftViewController != nil) {
                self.didFinishScrollingToViewController(self.leftViewController!)
            } else if (progress == 0  && self.selectedViewController != nil) {
                self.didFinishScrollingToViewController(self.selectedViewController!)
            }
            
        }
        
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // setContentOffset is called to center the selected view after bounces
        // This prevents yucky behavior at the beginning and end of the page collection by making sure setContentOffset is called only if...
        if (self.leftViewController != nil && self.rightViewController != nil) // It isn't at the beginning or end of the page collection
            || (self.leftViewController == nil && scrollView.contentOffset.x > fabs(scrollView.contentInset.left)) // If it's at the beginning of the collection, the decelleration can't be triggered by scrolling away from, than torwards the inset
            || (self.rightViewController == nil && scrollView.contentOffset.x < fabs(scrollView.contentInset.right)) { // Same as the last condition, but at the end of the collection
            scrollView.setContentOffset(CGPoint(x: self.view.bounds.width, y: 0), animated: true)
        }
        
    }
}
