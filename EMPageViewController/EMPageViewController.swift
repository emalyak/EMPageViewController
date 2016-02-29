/*

  EMPageViewController.swift

  Copyright (c) 2015-2016 Erik Malyak

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

/**
    The `EMPageViewControllerDataSource` protocol is adopted to provide the view controllers that are displayed when the user scrolls through pages. Methods are called on an as-needed basis.

    Each method returns a `UIViewController` object or `nil` if there are no view controllers to be displayed.

    - note: If the data source is `nil`, gesture based scrolling will be disabled and all view controllers must be provided through `selectViewController:direction:animated:completion:`.
*/
@objc public protocol EMPageViewControllerDataSource {
    
    /**
        Called to optionally return a view controller that is to the left of a given view controller in a horizontal orientation, or above a given view controller in a vertical orientation.
        
        - parameter pageViewController: The page view controller
        - parameter viewController: The point of reference view controller
        
        - returns: The view controller that is to the left of the given `viewController` in a horizontal orientation, or above the given `viewController` in a vertical orientation, or `nil` if there is no view controller to be displayed.
    */
    func em_pageViewController(pageViewController: EMPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
    
    /**
        Called to optionally return a view controller that is to the right of a given view controller.

        - parameter pageViewController: The page view controller
        - parameter viewController: The point of reference view controller
     
        - returns: The view controller that is to the right of the given `viewController` in a horizontal orientation, or below the given `viewController` in a vertical orientation, or `nil` if there is no view controller to be displayed.
    */
    func em_pageViewController(pageViewController: EMPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
}

/**
    The EMPageViewControllerDelegate protocol is adopted to receive messages for all important events of the page transition process.
*/
@objc public protocol EMPageViewControllerDelegate {
    
    /**
        Called before scrolling to a new view controller.

        - note: This method will not be called if the starting view controller is `nil`. A common scenario where this will occur is when you initialize the page view controller and use `selectViewController:direction:animated:completion:` to load the first selected view controller.

        - important: If bouncing is enabled, it is possible this method will be called more than once for one page transition. It can be called before the initial scroll to the destination view controller (which is when it is usually called), and it can also be called when the scroll momentum carries over slightly to the view controller after the original destination view controller.

        - parameter pageViewController: The page view controller
        - parameter startingViewController: The currently selected view controller the transition is starting from
        - parameter destinationViewController: The view controller that will be scrolled to, where the transition should end
     */
    optional func em_pageViewController(pageViewController: EMPageViewController, willStartScrollingFrom startingViewController: UIViewController, destinationViewController:UIViewController)
    
    /**
        Called whenever there has been a scroll position change in a page transition. This method is very useful if you need to know the exact progress of the page transition animation.

        - note: This method will not be called if the starting view controller is `nil`. A common scenario where this will occur is when you initialize the page view controller and use `selectViewController:direction:animated:completion:` to load the first selected view controller.

        - parameter pageViewController: The page view controller
        - parameter startingViewController: The currently selected view controller the transition is starting from
        - parameter destinationViewController: The view controller being scrolled to where the transition should end
        - parameter progress: The progress of the transition, where 0 is a neutral scroll position, >= 1 is a complete transition to the right view controller in a horizontal orientation, or the below view controller in a vertical orientation, and <= -1 is a complete transition to the left view controller in a horizontal orientation, or the above view controller in a vertical orientation. Values may be greater than 1 or less than -1 if bouncing is enabled and the scroll velocity is quick enough.
    */
    optional func em_pageViewController(pageViewController: EMPageViewController, isScrollingFrom startingViewController: UIViewController, destinationViewController:UIViewController, progress: CGFloat)
    
    /**
        Called after a page transition attempt has completed.
     
        - important: If bouncing is enabled, it is possible this method will be called more than once for one page transition. It can be called after the scroll transition to the intended destination view controller (which is when it is usually called), and it can also be called when the scroll momentum carries over slightly to the view controller after the intended destination view controller. In the latter scenario, `transitionSuccessful` will return `false` the second time it's called because the scroll view will bounce back to the intended destination view controller.

        - parameter pageViewController: The page view controller
        - parameter startingViewController: The currently selected view controller the transition is starting from
        - parameter destinationViewController: The view controller that has been attempted to be selected
        - parameter transitionSuccessful: A Boolean whether the transition to the destination view controller was successful or not. If `true`, the new selected view controller is `destinationViewController`. If `false`, the transition returned to the view controller it started from, so the selected view controller is still `startingViewController`.
    */
    optional func em_pageViewController(pageViewController: EMPageViewController, didFinishScrollingFrom startingViewController: UIViewController?, destinationViewController:UIViewController, transitionSuccessful: Bool)
}

/**
    The navigation scroll direction.
*/
@objc public enum EMPageViewControllerNavigationDirection : Int {
    /// Forward direction. Can be right in a horizontal orientation or down in a vertical orientation.
    case Forward
    /// Reverse direction. Can be left in a horizontal orientation or up in a vertical orientation.
    case Reverse
}

/**
    The navigation scroll orientation.
*/
@objc public enum EMPageViewControllerNavigationOrientation: Int {
    /// Horiziontal orientation. Scrolls left and right.
    case Horizontal
    /// Vertical orientation. Scrolls up and down.
    case Vertical
}

/// Manages page navigation between view controllers. View controllers can be navigated via swiping gestures, or called programmatically.
public class EMPageViewController: UIViewController, UIScrollViewDelegate {
    
    /// The object that provides view controllers on an as-needed basis throughout the navigation of the page view controller.
    ///
    /// If the data source is `nil`, gesture based scrolling will be disabled and all view controllers must be provided through `selectViewController:direction:animated:completion:`.
    ///
    /// - important: If you are using a data source, make sure you set `dataSource` before calling `selectViewController:direction:animated:completion:`.
    public weak var dataSource: EMPageViewControllerDataSource?
    
    /// The object that receives messages throughout the navigation process of the page view controller.
    public weak var delegate: EMPageViewControllerDelegate?
    
    /// The direction scrolling navigation occurs
    public private(set) var navigationOrientation: EMPageViewControllerNavigationOrientation = .Horizontal
    
    private var orientationIsHorizontal: Bool {
        return self.navigationOrientation == .Horizontal
    }

    /// The underlying `UIScrollView` responsible for scrolling page views.
    /// - important: Properties should be set with caution to prevent unexpected behavior.
    public private(set) lazy var scrollView: UIScrollView = {
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
    
    /// The view controller before the selected view controller.
    private var beforeViewController: UIViewController?
    
    /// The currently selected view controller. Can be `nil` if no view controller is selected.
    public private(set) var selectedViewController: UIViewController?
    
    /// The view controller after the selected view controller.
    private var afterViewController: UIViewController?
    
    /// Boolean that indicates whether the page controller is currently in the process of scrolling.
    public private(set) var scrolling = false
    
    /// The direction the page controller is scrolling towards.
    public private(set) var navigationDirection: EMPageViewControllerNavigationDirection?
    
    private var adjustingContentOffset = false // Flag used to prevent isScrolling delegate when shifting scrollView
    private var loadNewAdjoiningViewControllersOnFinish = false
    private var didFinishScrollingCompletionHandler: ((transitionSuccessful: Bool) -> Void)?
    private var transitionAnimated = false // Used for accurate view appearance messages
    
    // MARK: - Public Methods
    
    /// Initializes a newly created page view controller with the specified navigation orientation.
    /// - parameter navigationOrientation: The page view controller's navigation scroll direction.
    /// - returns: The initialized page view controller.
    public convenience init(navigationOrientation: EMPageViewControllerNavigationOrientation) {
        self.init()
        self.navigationOrientation = navigationOrientation
    }
    
    /**
        Sets the view controller that will be selected after the animation. This method is also used to provide the first view controller that will be selected in the page view controller.

        If a data source has been set, the view controllers before and after the selected view controller will also be loaded but not appear yet.

        - important: If you are using a data source, make sure you set `dataSource` before calling `selectViewController:direction:animated:completion:`

        - parameter selectViewController: The view controller to be selected.
        - parameter direction: The direction of the navigation and animation, if applicable.
        - parameter completion: A block that's called after the transition is finished. The block parameter `transitionSuccessful` is `true` if the transition to the selected view controller was completed successfully.
    */
    public func selectViewController(viewController: UIViewController, direction: EMPageViewControllerNavigationDirection, animated: Bool, completion: ((transitionSuccessful: Bool) -> Void)?) {
        
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
    
    /**
        Transitions to the view controller right of the currently selected view controller in a horizontal orientation, or below the currently selected view controller in a vertical orientation. Also described as going to the next page.

        - parameter animated: A Boolean whether or not to animate the transition
        - parameter completion: A block that's called after the transition is finished. The block parameter `transitionSuccessful` is `true` if the transition to the selected view controller was completed successfully. If `false`, the transition returned to the view controller it started from.
    */
    public func scrollForwardAnimated(animated: Bool, completion: ((transitionSuccessful: Bool) -> Void)?) {
        
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
    
    /**
        Transitions to the view controller left of the currently selected view controller in a horizontal orientation, or above the currently selected view controller in a vertical orientation. Also described as going to the previous page.

        - parameter animated: A Boolean whether or not to animate the transition
        - parameter completion: A block that's called after the transition is finished. The block parameter `transitionSuccessful` is `true` if the transition to the selected view controller was completed successfully. If `false`, the transition returned to the view controller it started from.
     */
    public func scrollReverseAnimated(animated: Bool, completion: ((transitionSuccessful: Bool) -> Void)?) {
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
    
    // Overriden to have control of accurate view appearance method calls
    public override func shouldAutomaticallyForwardAppearanceMethods() -> Bool {
        return false
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        self.view.addSubview(self.scrollView)
    }
    
    public override func viewWillLayoutSubviews() {
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
    
    private func layoutViews() {
        
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
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
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
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.transitionAnimated = true
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
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
