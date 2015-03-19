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
    optional func em_pageViewController(pageViewController:EMPageViewController, didFinishScrollingFrom previousViewController:UIViewController?, currentViewController:UIViewController, transitionSuccessful:Bool)
    optional func em_pageViewController(pageViewController:EMPageViewController, isScrollingFrom startingViewController:UIViewController, destinationViewController:UIViewController, progress:Float)
}

enum EMPageViewControllerNavigationDirection : Int {
    case Forward
    case Reverse
}

class EMPageViewController: UIViewController, UIScrollViewDelegate {
    
    weak var dataSource:EMPageViewControllerDataSource?
    weak var delegate:EMPageViewControllerDelegate?

    private let scrollView:UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.pagingEnabled = true
        scrollView.scrollsToTop = false
        scrollView.autoresizingMask = .FlexibleLeftMargin | .FlexibleRightMargin
        scrollView.bounces = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.setTranslatesAutoresizingMaskIntoConstraints(true)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    
    private var leftViewController:UIViewController?
    private var currentViewController:UIViewController?
    private var rightViewController:UIViewController?
    
    private var adjustingContentOffset = false // Flag used to prevent isScrolling delegate when shifting scrollView
    var scrolling = false // Flag to make sure willStartScrollingFrom is only called once
    var navigationDirection:EMPageViewControllerNavigationDirection?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        self.view.addSubview(scrollView)
    }
    
    func setCurrentViewController(viewController:UIViewController, animated:Bool, completion:(()->())?) {
        
        // Scrolled forward
        if (viewController == self.rightViewController) {
            
            // Hide the old left controller
            self.removeChildIfNeeded(self.leftViewController)
            
            // Set new left controller as the old current controller
            self.leftViewController = self.currentViewController
            
            // Set the new current controller as the old right controller
            self.currentViewController = self.rightViewController
            
            // Retreive the new right controller from the data source if available, otherwise set as nil
            if let rightViewController = self.dataSource?.em_pageViewController(self, viewControllerRightOfViewController: viewController) {
                self.rightViewController = rightViewController
            } else {
                self.rightViewController = nil
            }
        
            self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.leftViewController!, currentViewController: self.currentViewController!, transitionSuccessful: true)
            
        // Scrolled reverse
        } else if (viewController == self.leftViewController) {
            
            // Hide the old left controller
            self.removeChildIfNeeded(self.rightViewController)
            
            // Set new right controller as the old current controller
            self.rightViewController = self.currentViewController
            
            // Set the new current controller as the old left controller
            self.currentViewController = self.leftViewController
            
            // Retreive the new left controller from the data source if available, otherwise set as nil
            if let leftViewController = self.dataSource?.em_pageViewController(self, viewControllerLeftOfViewController: viewController) {
                self.leftViewController = leftViewController
            } else {
                self.leftViewController = nil
            }
            
            self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.rightViewController!, currentViewController: self.currentViewController!, transitionSuccessful: true)
        
        // Scrolled but ended up where started
        } else if (viewController == self.currentViewController) {
            
            // Remove hidden view controllers
            self.removeChildIfNeeded(self.leftViewController)
            self.removeChildIfNeeded(self.rightViewController)
            
            let intendedDestinationViewController = self.navigationDirection == .Forward ? self.rightViewController! : self.leftViewController!
            self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.currentViewController!, currentViewController: intendedDestinationViewController, transitionSuccessful: false)
            
        // Initialization
        } else {
            
            // Set controller as current
            self.currentViewController = viewController
            
            // Show view controller
            self.addChildIfNeeded(self.currentViewController!)
            
            // Retreive left and right view controllers if available
            if let leftViewController = self.dataSource?.em_pageViewController(self, viewControllerLeftOfViewController: viewController) {
                self.leftViewController = leftViewController
            }
            
            if let rightViewController = self.dataSource?.em_pageViewController(self, viewControllerRightOfViewController: viewController) {
                self.rightViewController = rightViewController
            }
            
            self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: nil, currentViewController: self.currentViewController!, transitionSuccessful: true)
            
        }
        
    }
    
    private func didScrollToViewController(viewController:UIViewController) {
        self.setCurrentViewController(viewController, animated: false, completion: nil)
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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.scrollView.frame = self.view.bounds
        self.scrollView.contentSize = CGSize(width: self.view.bounds.width * 3, height: self.view.bounds.height)
        self.layoutViews()
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
        self.currentViewController?.view.frame = CGRect(x: viewWidth, y: 0, width: viewWidth, height: viewHeight)
        self.rightViewController?.view.frame = CGRect(x: viewWidth * 2, y: 0, width: viewWidth, height: viewHeight)
    }
    
    
    // MARK: - UIScrollView Delegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {

        if !adjustingContentOffset {
        
            let viewWidth = self.view.bounds.width
            let progress = (scrollView.contentOffset.x - viewWidth) / viewWidth
            
            // Scrolling forward / right
            if (progress > 0) {
                if (self.rightViewController != nil) {
                    self.addChildIfNeeded(self.rightViewController!)
                    if !scrolling || self.navigationDirection == .Reverse { // call willScroll once, or change direction
                        self.delegate?.em_pageViewController?(self, willStartScrollingFrom: self.currentViewController!, destinationViewController: self.rightViewController!)
                        self.scrolling = true
                    }
                    
                    self.delegate?.em_pageViewController?(self, isScrollingFrom: self.currentViewController!, destinationViewController: self.rightViewController!, progress: Float(progress))
                    self.navigationDirection = .Forward
                }
                
            // Scrolling reverse / left
            } else if (progress < 0) {
                if (self.leftViewController != nil) {
                    self.addChildIfNeeded(self.leftViewController!)
                    if !scrolling || self.navigationDirection == .Forward { // call willScroll once
                        self.delegate?.em_pageViewController?(self, willStartScrollingFrom: self.currentViewController!, destinationViewController: self.leftViewController!)
                        self.scrolling = true
                    }
                    
                    self.delegate?.em_pageViewController?(self, isScrollingFrom: self.currentViewController!, destinationViewController: self.leftViewController!, progress: Float(progress))
                    self.navigationDirection = .Reverse
                }
                
            // At zero
            } else {
                if (self.navigationDirection == .Forward) {
                    self.delegate?.em_pageViewController?(self, isScrollingFrom: self.currentViewController!, destinationViewController: self.rightViewController!, progress: Float(progress))
                } else {
                    self.delegate?.em_pageViewController?(self, isScrollingFrom: self.currentViewController!, destinationViewController: self.leftViewController!, progress: Float(progress))
                }
            }
            
            // Thresholds to update view layouts call delegates
            if (progress >= 1 && self.rightViewController != nil) {
                self.didScrollToViewController(self.rightViewController!)
                self.scrolling = false
            } else if (progress <= -1  && self.leftViewController != nil) {
                self.didScrollToViewController(self.leftViewController!)
                self.scrolling = false
            } else if (progress == 0  && self.currentViewController != nil) {
                self.didScrollToViewController(self.currentViewController!)
                self.scrolling = false
            }
        }
        
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // Called to center view after bounce
        scrollView.setContentOffset(CGPoint(x: self.view.bounds.width, y: 0), animated: true) // bug at end view controllers
    }
}
