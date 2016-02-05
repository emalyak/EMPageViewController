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
    func em_pageViewController(pageViewController: EMPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
    func em_pageViewController(pageViewController: EMPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
}

@objc protocol EMPageViewControllerDelegate {
    optional func em_pageViewController(pageViewController: EMPageViewController, willStartScrollingFrom startingViewController: UIViewController, destinationViewController:UIViewController)
    optional func em_pageViewController(pageViewController: EMPageViewController, isScrollingFrom startingViewController: UIViewController, destinationViewController:UIViewController, progress: CGFloat)
    optional func em_pageViewController(pageViewController: EMPageViewController, didFinishScrollingFrom startingViewController: UIViewController?, destinationViewController:UIViewController, transitionSuccessful: Bool)
}

@objc enum EMPageViewControllerNavigationDirection : Int {
    case Forward
    case Reverse
}

@objc enum EMPageViewControllerNavigationOrientation: Int {
    case Horizontal
    case Vertical
}

class EMPageViewController: UIViewController, UIScrollViewDelegate {
    
    weak var dataSource: EMPageViewControllerDataSource?
    weak var delegate: EMPageViewControllerDelegate?
    
    // Navigation orientation
    private(set) var navigationOrientation: EMPageViewControllerNavigationOrientation = .Horizontal
    private var orientationIsHorizontal: Bool {
        return self.navigationOrientation == .Horizontal
    }

    // This is private because some properties cannot be changed publicly, or else it will break things
    private(set) lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.pagingEnabled = true
        scrollView.scrollsToTop = false
        scrollView.autoresizingMask = [.FlexibleTopMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleLeftMargin]
        scrollView.bounces = true
        scrollView.alwaysBounceHorizontal = self.orientationIsHorizontal
        scrollView.alwaysBounceVertical = !self.orientationIsHorizontal
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private var beforeViewController: UIViewController?
    private(set) var selectedViewController: UIViewController?
    private var afterViewController: UIViewController?
    
    private(set) var scrolling = false
    private(set) var navigationDirection: EMPageViewControllerNavigationDirection?
    
    private var adjustingContentOffset = false // Flag used to prevent isScrolling delegate when shifting scrollView
    private var loadNewAdjoiningViewControllersOnFinish = false
    private var didFinishScrollingCompletionHandler: ((transitionSuccessful: Bool) -> Void)?
    private var transitionAnimated = false // Used for accurate view appearance messages

    override func shouldAutomaticallyForwardAppearanceMethods() -> Bool {
        return false
    }
    
    convenience init(orientation: EMPageViewControllerNavigationOrientation) {
        self.init()
        self.navigationOrientation = orientation
    }
    
    // MARK: - Public Methods
    
    func selectViewController(viewController: UIViewController, direction: EMPageViewControllerNavigationDirection, animated: Bool, completion: ((transitionSuccessful: Bool) -> Void)?) {
        
        if (direction == .Forward) {
            self.afterViewController = viewController
            self.layoutViews()
            self.loadNewAdjoiningViewControllersOnFinish = true
            self.scrollForwardAnimated(animated, completion: completion)
        } else if (direction == .Reverse) {
            self.beforeViewController = viewController
            self.layoutViews()
            self.loadNewAdjoiningViewControllersOnFinish = true
            self.scrollReverseAnimated(animated, completion: completion)
        }
        
    }
    
    func scrollForwardAnimated(animated: Bool, completion: ((transitionSuccessful: Bool) -> Void)?) {
        
        if (self.afterViewController != nil) {
            
            // Cancel current animation and move
            if self.scrolling {
                if self.orientationIsHorizontal {
                    self.scrollView.setContentOffset(CGPoint(x: self.view.bounds.width * 2, y: 0), animated: false)
                } else {
                    self.scrollView.setContentOffset(CGPoint(x: 0, y: self.view.bounds.height * 2), animated: false)
                }

            }
            
            self.didFinishScrollingCompletionHandler = completion
            self.transitionAnimated = animated
            if self.orientationIsHorizontal {
                self.scrollView.setContentOffset(CGPoint(x: self.view.bounds.width * 2, y: 0), animated: animated)
            } else {
                self.scrollView.setContentOffset(CGPoint(x: 0, y: self.view.bounds.height * 2), animated: animated)
            }

        }
    }
    
    func scrollReverseAnimated(animated: Bool, completion: ((transitionSuccessful: Bool) -> Void)?) {
        if (self.beforeViewController != nil) {

            // Cancel current animation and move
            if self.scrolling {
                self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            }
            
            self.didFinishScrollingCompletionHandler = completion
            self.transitionAnimated = animated
            self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: animated)
        }
    }
    
    
    // MARK: - View Controller Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        self.view.addSubview(scrollView)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.scrollView.frame = self.view.bounds
        if self.orientationIsHorizontal {
            self.scrollView.contentSize = CGSize(width: self.view.bounds.width * 3, height: self.view.bounds.height)
        } else {
            self.scrollView.contentSize = CGSize(width: self.view.bounds.width, height: self.view.bounds.height * 3)
        }

        self.layoutViews()
    }
    
    
    // MARK: - View Controller Management
    
    private func loadViewControllers(selectedViewController: UIViewController) {
        
        // Scrolled forward
        if (selectedViewController == self.afterViewController) {
            
            // Shift view controllers forward
            self.beforeViewController = self.selectedViewController
            self.selectedViewController = self.afterViewController
            
            self.selectedViewController!.endAppearanceTransition()
            
            self.removeChildIfNeeded(self.beforeViewController)
            self.beforeViewController?.endAppearanceTransition()
            
            self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.beforeViewController, destinationViewController: self.selectedViewController!, transitionSuccessful: true)
            
            self.didFinishScrollingCompletionHandler?(transitionSuccessful: true)
            self.didFinishScrollingCompletionHandler = nil
            
            // Load new before view controller if required
            if self.loadNewAdjoiningViewControllersOnFinish {
                self.loadBeforeViewControllerForSelectedViewController(selectedViewController)
                self.loadNewAdjoiningViewControllersOnFinish = false
            }
            
            // Load new after view controller
            self.loadAfterViewControllerForSelectedViewController(selectedViewController)
            
            
        // Scrolled reverse
        } else if (selectedViewController == self.beforeViewController) {
            
            // Shift view controllers reverse
            self.afterViewController = self.selectedViewController
            self.selectedViewController = self.beforeViewController
            
            self.selectedViewController!.endAppearanceTransition()
            
            self.removeChildIfNeeded(self.afterViewController)
            self.afterViewController?.endAppearanceTransition()
            
            self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.afterViewController!, destinationViewController: self.selectedViewController!, transitionSuccessful: true)
            
            self.didFinishScrollingCompletionHandler?(transitionSuccessful: true)
            self.didFinishScrollingCompletionHandler = nil
            
            // Load new after view controller if required
            if self.loadNewAdjoiningViewControllersOnFinish {
                self.loadAfterViewControllerForSelectedViewController(selectedViewController)
                self.loadNewAdjoiningViewControllersOnFinish = false
            }
            
            // Load new before view controller
            self.loadBeforeViewControllerForSelectedViewController(selectedViewController)
        
        // Scrolled but ended up where started
        } else if (selectedViewController == self.selectedViewController) {
            
            self.selectedViewController!.beginAppearanceTransition(true, animated: self.transitionAnimated)
            
            if (self.navigationDirection == .Forward) {
                self.afterViewController!.beginAppearanceTransition(false, animated: self.transitionAnimated)
            } else if (self.navigationDirection == .Reverse) {
                self.beforeViewController!.beginAppearanceTransition(false, animated: self.transitionAnimated)
            }
            
            self.selectedViewController!.endAppearanceTransition()
            
            // Remove hidden view controllers
            self.removeChildIfNeeded(self.beforeViewController)
            self.removeChildIfNeeded(self.afterViewController)
            
            if (self.navigationDirection == .Forward) {
                self.afterViewController!.endAppearanceTransition()
                self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.selectedViewController!, destinationViewController: self.afterViewController!, transitionSuccessful: false)
            } else if (self.navigationDirection == .Reverse) {
                self.beforeViewController!.endAppearanceTransition()
                self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.selectedViewController!, destinationViewController: self.beforeViewController!, transitionSuccessful: false)
            }
            
            self.didFinishScrollingCompletionHandler?(transitionSuccessful: false)
            self.didFinishScrollingCompletionHandler = nil
            
            if self.loadNewAdjoiningViewControllersOnFinish {
                if (self.navigationDirection == .Forward) {
                    self.loadAfterViewControllerForSelectedViewController(selectedViewController)
                } else if (self.navigationDirection == .Reverse) {
                    self.loadBeforeViewControllerForSelectedViewController(selectedViewController)
                }
            }
            
        }
        
        self.navigationDirection = nil
        self.scrolling = false
        
    }
    
    private func loadBeforeViewControllerForSelectedViewController(selectedViewController:UIViewController) {
        // Retreive the new before controller from the data source if available, otherwise set as nil
        if let beforeViewController = self.dataSource?.em_pageViewController(self, viewControllerBeforeViewController: selectedViewController) {
            self.beforeViewController = beforeViewController
        } else {
            self.beforeViewController = nil
        }
    }
    
    private func loadAfterViewControllerForSelectedViewController(selectedViewController:UIViewController) {
        // Retreive the new after controller from the data source if available, otherwise set as nil
        if let afterViewController = self.dataSource?.em_pageViewController(self, viewControllerAfterViewController: selectedViewController) {
            self.afterViewController = afterViewController
        } else {
            self.afterViewController = nil
        }
    }
    
    
    // MARK: - View Management
    
    private func addChildIfNeeded(viewController: UIViewController) {
        self.scrollView.addSubview(viewController.view)
        self.addChildViewController(viewController)
        viewController.didMoveToParentViewController(self)
    }
    
    private func removeChildIfNeeded(viewController: UIViewController?) {
        viewController?.view.removeFromSuperview()
        viewController?.didMoveToParentViewController(nil)
        viewController?.removeFromParentViewController()
    }
    
    func layoutViews() {
        
        let viewWidth = self.view.bounds.width
        let viewHeight = self.view.bounds.height
        
        var beforeInset:CGFloat = 0
        var afterInset:CGFloat = 0
        
        if (self.beforeViewController == nil) {
            beforeInset = self.orientationIsHorizontal ? -viewWidth : -viewHeight
        }
        
        if (self.afterViewController == nil) {
            afterInset = self.orientationIsHorizontal ? -viewWidth : -viewHeight
        }
        
        self.adjustingContentOffset = true
        self.scrollView.contentOffset = CGPoint(x: self.orientationIsHorizontal ? viewWidth : 0, y: self.orientationIsHorizontal ? 0 : viewHeight)
        if self.orientationIsHorizontal {
            self.scrollView.contentInset = UIEdgeInsetsMake(0, beforeInset, 0, afterInset)
        } else {
            self.scrollView.contentInset = UIEdgeInsetsMake(beforeInset, 0, afterInset, 0)
        }
        self.adjustingContentOffset = false
        
        if self.orientationIsHorizontal {
            self.beforeViewController?.view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
            self.selectedViewController?.view.frame = CGRect(x: viewWidth, y: 0, width: viewWidth, height: viewHeight)
            self.afterViewController?.view.frame = CGRect(x: viewWidth * 2, y: 0, width: viewWidth, height: viewHeight)
        } else {
            self.beforeViewController?.view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
            self.selectedViewController?.view.frame = CGRect(x: 0, y: viewHeight, width: viewWidth, height: viewHeight)
            self.afterViewController?.view.frame = CGRect(x: 0, y: viewHeight * 2, width: viewWidth, height: viewHeight)
        }
        
    }
    
    
    // MARK: - Internal Callbacks
    
    private func willScrollFromViewController(startingViewController: UIViewController?, destinationViewController: UIViewController) {
        if (startingViewController != nil) {
            self.delegate?.em_pageViewController?(self, willStartScrollingFrom: startingViewController!, destinationViewController: destinationViewController)
        }
        
        destinationViewController.beginAppearanceTransition(true, animated: self.transitionAnimated)
        startingViewController?.beginAppearanceTransition(false, animated: self.transitionAnimated)
        self.addChildIfNeeded(destinationViewController)
    }
    
    private func didFinishScrollingToViewController(viewController: UIViewController) {
        self.loadViewControllers(viewController)
        self.layoutViews()
    }
    
    
    // MARK: - UIScrollView Delegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if !adjustingContentOffset {
        
            let distance = self.orientationIsHorizontal ? self.view.bounds.width : self.view.bounds.height
            let progress = ((self.orientationIsHorizontal ? scrollView.contentOffset.x : scrollView.contentOffset.y) - distance) / distance
            
            // Scrolling forward / after
            if (progress > 0) {
                if (self.afterViewController != nil) {
                    if !scrolling { // call willScroll once
                        self.willScrollFromViewController(self.selectedViewController, destinationViewController: self.afterViewController!)
                        self.scrolling = true
                    }
                    
                    if self.navigationDirection == .Reverse { // check if direction changed
                        self.didFinishScrollingToViewController(self.selectedViewController!)
                        self.willScrollFromViewController(self.selectedViewController, destinationViewController: self.afterViewController!)
                    }
                    
                    self.navigationDirection = .Forward
                    
                    if (self.selectedViewController != nil) {
                        self.delegate?.em_pageViewController?(self, isScrollingFrom: self.selectedViewController!, destinationViewController: self.afterViewController!, progress: progress)
                    }
                }
                
            // Scrolling reverse / before
            } else if (progress < 0) {
                if (self.beforeViewController != nil) {
                    if !scrolling { // call willScroll once
                        self.willScrollFromViewController(self.selectedViewController, destinationViewController: self.beforeViewController!)
                        self.scrolling = true
                    }
                    
                    if self.navigationDirection == .Forward { // check if direction changed
                        self.didFinishScrollingToViewController(self.selectedViewController!)
                        self.willScrollFromViewController(self.selectedViewController, destinationViewController: self.beforeViewController!)
                    }
                    
                    self.navigationDirection = .Reverse
                    
                    if (self.selectedViewController != nil) {
                        self.delegate?.em_pageViewController?(self, isScrollingFrom: self.selectedViewController!, destinationViewController: self.beforeViewController!, progress: progress)
                    }
                }
                
            // At zero
            } else {
                if (self.navigationDirection == .Forward) {
                    self.delegate?.em_pageViewController?(self, isScrollingFrom: self.selectedViewController!, destinationViewController: self.afterViewController!, progress: progress)
                } else if (self.navigationDirection == .Reverse) {
                    self.delegate?.em_pageViewController?(self, isScrollingFrom: self.selectedViewController!, destinationViewController: self.beforeViewController!, progress: progress)
                }
            }
            
            // Thresholds to update view layouts call delegates
            if (progress >= 1 && self.afterViewController != nil) {
                self.didFinishScrollingToViewController(self.afterViewController!)
            } else if (progress <= -1  && self.beforeViewController != nil) {
                self.didFinishScrollingToViewController(self.beforeViewController!)
            } else if (progress == 0  && self.selectedViewController != nil) {
                self.didFinishScrollingToViewController(self.selectedViewController!)
            }
            
        }
        
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.transitionAnimated = true
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // setContentOffset is called to center the selected view after bounces
        // This prevents yucky behavior at the beginning and end of the page collection by making sure setContentOffset is called only if...
        
        if self.orientationIsHorizontal {
            if  (self.beforeViewController != nil && self.afterViewController != nil) || // It isn't at the beginning or end of the page collection
                (self.afterViewController != nil && self.beforeViewController == nil && scrollView.contentOffset.x > fabs(scrollView.contentInset.left)) || // If it's at the beginning of the collection, the decelleration can't be triggered by scrolling away from, than torwards the inset
                (self.beforeViewController != nil && self.afterViewController == nil && scrollView.contentOffset.x < fabs(scrollView.contentInset.right)) { // Same as the last condition, but at the end of the collection
                    scrollView.setContentOffset(CGPoint(x: self.view.bounds.width, y: 0), animated: true)
            }
        } else {
            if  (self.beforeViewController != nil && self.afterViewController != nil) || // It isn't at the beginning or end of the page collection
                (self.afterViewController != nil && self.beforeViewController == nil && scrollView.contentOffset.y > fabs(scrollView.contentInset.top)) || // If it's at the beginning of the collection, the decelleration can't be triggered by scrolling away from, than torwards the inset
                (self.beforeViewController != nil && self.afterViewController == nil && scrollView.contentOffset.y < fabs(scrollView.contentInset.bottom)) { // Same as the last condition, but at the end of the collection
                    scrollView.setContentOffset(CGPoint(x: 0, y: self.view.bounds.height), animated: true)
            }
        }
        
    }
}
