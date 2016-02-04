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
    func em_pageViewController(pageViewController: EMPageViewController, viewControllerLeftOfViewController viewController: UIViewController) -> UIViewController?
    func em_pageViewController(pageViewController: EMPageViewController, viewControllerRightOfViewController viewController: UIViewController) -> UIViewController?
}

@objc protocol EMPageViewControllerDelegate {
    optional func em_pageViewController(pageViewController: EMPageViewController, willStartScrollingFrom startingViewController: UIViewController, destinationViewController:UIViewController)
    optional func em_pageViewController(pageViewController: EMPageViewController, isScrollingFrom startingViewController: UIViewController, destinationViewController:UIViewController, progress: CGFloat)
    optional func em_pageViewController(pageViewController: EMPageViewController, didFinishScrollingFrom startingViewController: UIViewController?, destinationViewController:UIViewController, transitionSuccessful: Bool)
}

enum EMPageViewControllerNavigationDirection : Int {
    case Forward
    case Reverse
}

enum EMPageViewControllerNavigationOrientation: Int {
    case Horizontal
    case Vertical
}

class EMPageViewController: UIViewController, UIScrollViewDelegate {
    
    weak var dataSource: EMPageViewControllerDataSource?
    weak var delegate: EMPageViewControllerDelegate?
    
    // Navigation orientation
    private var navigationOrientation: EMPageViewControllerNavigationOrientation = .Horizontal
    var horizontal: Bool {
        return self.navigationOrientation == .Horizontal
    }

    // This is private because some properties cannot be changed publicly, or else it will break things
    private(set) lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.pagingEnabled = true
        scrollView.scrollsToTop = false
        scrollView.autoresizingMask = [.FlexibleTopMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleLeftMargin]
        scrollView.bounces = true
        scrollView.alwaysBounceHorizontal = self.horizontal
        scrollView.alwaysBounceVertical = !self.horizontal
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private var leftViewController: UIViewController?
    private(set) var selectedViewController: UIViewController?
    private var rightViewController: UIViewController?
    
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
            self.rightViewController = viewController
            self.layoutViews()
            self.loadNewAdjoiningViewControllersOnFinish = true
            self.scrollForwardAnimated(animated, completion: completion)
        } else if (direction == .Reverse) {
            self.leftViewController = viewController
            self.layoutViews()
            self.loadNewAdjoiningViewControllersOnFinish = true
            self.scrollReverseAnimated(animated, completion: completion)
        }
        
    }
    
    func scrollForwardAnimated(animated: Bool, completion: ((transitionSuccessful: Bool) -> Void)?) {
        
        if (self.rightViewController != nil) {
            
            // Cancel current animation and move
            if self.scrolling {
                if (self.horizontal) {
                    self.scrollView.setContentOffset(CGPoint(x: self.view.bounds.width * 2, y: 0), animated: false)
                } else {
                    self.scrollView.setContentOffset(CGPoint(x: 0, y: self.view.bounds.height * 2), animated: false)
                }

            }
            
            self.didFinishScrollingCompletionHandler = completion
            self.transitionAnimated = animated
            if (self.horizontal) {
                self.scrollView.setContentOffset(CGPoint(x: self.view.bounds.width * 2, y: 0), animated: animated)
            } else {
                self.scrollView.setContentOffset(CGPoint(x: 0, y: self.view.bounds.height * 2), animated: animated)
            }

        }
    }
    
    func scrollReverseAnimated(animated: Bool, completion: ((transitionSuccessful: Bool) -> Void)?) {
        if (self.leftViewController != nil) {

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
        if (self.horizontal) {
            self.scrollView.contentSize = CGSize(width: self.view.bounds.width * 3, height: self.view.bounds.height)
        } else {
            self.scrollView.contentSize = CGSize(width: self.view.bounds.width, height: self.view.bounds.height * 3)
        }

        self.layoutViews()
    }
    
    
    // MARK: - View Controller Management
    
    private func loadViewControllers(selectedViewController: UIViewController) {
        
        // Scrolled forward
        if (selectedViewController == self.rightViewController) {
            
            // Shift view controllers forward
            self.leftViewController = self.selectedViewController
            self.selectedViewController = self.rightViewController
            
            self.selectedViewController!.endAppearanceTransition()
            
            self.removeChildIfNeeded(self.leftViewController)
            self.leftViewController?.endAppearanceTransition()
            
            self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.leftViewController, destinationViewController: self.selectedViewController!, transitionSuccessful: true)
            
            self.didFinishScrollingCompletionHandler?(transitionSuccessful: true)
            self.didFinishScrollingCompletionHandler = nil
            
            // Load new left view controller if required
            if self.loadNewAdjoiningViewControllersOnFinish {
                self.loadLeftViewControllerForSelectedViewController(selectedViewController)
                self.loadNewAdjoiningViewControllersOnFinish = false
            }
            
            // Load new right view controller
            self.loadRightViewControllerForSelectedViewController(selectedViewController)
            
            
        // Scrolled reverse
        } else if (selectedViewController == self.leftViewController) {
            
            // Shift view controllers reverse
            self.rightViewController = self.selectedViewController
            self.selectedViewController = self.leftViewController
            
            self.selectedViewController!.endAppearanceTransition()
            
            self.removeChildIfNeeded(self.rightViewController)
            self.rightViewController?.endAppearanceTransition()
            
            self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.rightViewController!, destinationViewController: self.selectedViewController!, transitionSuccessful: true)
            
            self.didFinishScrollingCompletionHandler?(transitionSuccessful: true)
            self.didFinishScrollingCompletionHandler = nil
            
            // Load new right view controller if required
            if self.loadNewAdjoiningViewControllersOnFinish {
                self.loadRightViewControllerForSelectedViewController(selectedViewController)
                self.loadNewAdjoiningViewControllersOnFinish = false
            }
            
            // Load new left view controller
            self.loadLeftViewControllerForSelectedViewController(selectedViewController)
        
        // Scrolled but ended up where started
        } else if (selectedViewController == self.selectedViewController) {
            
            self.selectedViewController!.beginAppearanceTransition(true, animated: self.transitionAnimated)
            
            if (self.navigationDirection == .Forward) {
                self.rightViewController!.beginAppearanceTransition(false, animated: self.transitionAnimated)
            } else if (self.navigationDirection == .Reverse) {
                self.leftViewController!.beginAppearanceTransition(false, animated: self.transitionAnimated)
            }
            
            self.selectedViewController!.endAppearanceTransition()
            
            // Remove hidden view controllers
            self.removeChildIfNeeded(self.leftViewController)
            self.removeChildIfNeeded(self.rightViewController)
            
            if (self.navigationDirection == .Forward) {
                self.rightViewController!.endAppearanceTransition()
                self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.selectedViewController!, destinationViewController: self.rightViewController!, transitionSuccessful: false)
            } else if (self.navigationDirection == .Reverse) {
                self.leftViewController!.endAppearanceTransition()
                self.delegate?.em_pageViewController?(self, didFinishScrollingFrom: self.selectedViewController!, destinationViewController: self.leftViewController!, transitionSuccessful: false)
            }
            
            self.didFinishScrollingCompletionHandler?(transitionSuccessful: false)
            self.didFinishScrollingCompletionHandler = nil
            
            if self.loadNewAdjoiningViewControllersOnFinish {
                if (self.navigationDirection == .Forward) {
                    self.loadRightViewControllerForSelectedViewController(selectedViewController)
                } else if (self.navigationDirection == .Reverse) {
                    self.loadLeftViewControllerForSelectedViewController(selectedViewController)
                }
            }
            
        }
        
        self.navigationDirection = nil
        self.scrolling = false
        
    }
    
    private func loadLeftViewControllerForSelectedViewController(selectedViewController:UIViewController) {
        // Retreive the new left controller from the data source if available, otherwise set as nil
        if let leftViewController = self.dataSource?.em_pageViewController(self, viewControllerLeftOfViewController: selectedViewController) {
            self.leftViewController = leftViewController
        } else {
            self.leftViewController = nil
        }
    }
    
    private func loadRightViewControllerForSelectedViewController(selectedViewController:UIViewController) {
        // Retreive the new right controller from the data source if available, otherwise set as nil
        if let rightViewController = self.dataSource?.em_pageViewController(self, viewControllerRightOfViewController: selectedViewController) {
            self.rightViewController = rightViewController
        } else {
            self.rightViewController = nil
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
        
        var leftInset:CGFloat = 0
        var rightInset:CGFloat = 0
        
        if (self.leftViewController == nil) {
            leftInset = horizontal ? -viewWidth : -viewHeight
        }
        
        if (self.rightViewController == nil) {
            rightInset = horizontal ? -viewWidth : -viewHeight
        }
        
        self.adjustingContentOffset = true
        self.scrollView.contentOffset = CGPoint(x: self.horizontal ? viewWidth : 0, y: self.horizontal ? 0 : viewHeight)
        if (self.horizontal) {
            self.scrollView.contentInset = UIEdgeInsetsMake(0, leftInset, 0, rightInset)
        } else {
            self.scrollView.contentInset = UIEdgeInsetsMake(leftInset, 0, rightInset, 0)
        }
        self.adjustingContentOffset = false
        
        if (self.horizontal) {
            self.leftViewController?.view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
            self.selectedViewController?.view.frame = CGRect(x: viewWidth, y: 0, width: viewWidth, height: viewHeight)
            self.rightViewController?.view.frame = CGRect(x: viewWidth * 2, y: 0, width: viewWidth, height: viewHeight)
        } else {
            self.leftViewController?.view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
            self.selectedViewController?.view.frame = CGRect(x: 0, y: viewHeight, width: viewWidth, height: viewHeight)
            self.rightViewController?.view.frame = CGRect(x: 0, y: viewHeight * 2, width: viewWidth, height: viewHeight)
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
        
            let distance = self.horizontal ? self.view.bounds.width : self.view.bounds.height
            let progress = ((self.horizontal ? scrollView.contentOffset.x : scrollView.contentOffset.y) - distance) / distance
            
            // Scrolling forward / right
            if (progress > 0) {
                if (self.rightViewController != nil) {
                    if !scrolling { // call willScroll once
                        self.willScrollFromViewController(self.selectedViewController, destinationViewController: self.rightViewController!)
                        self.scrolling = true
                    }
                    
                    if self.navigationDirection == .Reverse { // check if direction changed
                        self.didFinishScrollingToViewController(self.selectedViewController!)
                        self.willScrollFromViewController(self.selectedViewController, destinationViewController: self.rightViewController!)
                    }
                    
                    self.navigationDirection = .Forward
                    
                    if (self.selectedViewController != nil) {
                        self.delegate?.em_pageViewController?(self, isScrollingFrom: self.selectedViewController!, destinationViewController: self.rightViewController!, progress: progress)
                    }
                }
                
            // Scrolling reverse / left
            } else if (progress < 0) {
                if (self.leftViewController != nil) {
                    if !scrolling { // call willScroll once
                        self.willScrollFromViewController(self.selectedViewController, destinationViewController: self.leftViewController!)
                        self.scrolling = true
                    }
                    
                    if self.navigationDirection == .Forward { // check if direction changed
                        self.didFinishScrollingToViewController(self.selectedViewController!)
                        self.willScrollFromViewController(self.selectedViewController, destinationViewController: self.leftViewController!)
                    }
                    
                    self.navigationDirection = .Reverse
                    
                    if (self.selectedViewController != nil) {
                        self.delegate?.em_pageViewController?(self, isScrollingFrom: self.selectedViewController!, destinationViewController: self.leftViewController!, progress: progress)
                    }
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
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.transitionAnimated = true
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // setContentOffset is called to center the selected view after bounces
        // This prevents yucky behavior at the beginning and end of the page collection by making sure setContentOffset is called only if...
        
        if (self.horizontal) {
            if  (self.leftViewController != nil && self.rightViewController != nil) || // It isn't at the beginning or end of the page collection
                (self.rightViewController != nil && self.leftViewController == nil && scrollView.contentOffset.x > fabs(scrollView.contentInset.left)) || // If it's at the beginning of the collection, the decelleration can't be triggered by scrolling away from, than torwards the inset
                (self.leftViewController != nil && self.rightViewController == nil && scrollView.contentOffset.x < fabs(scrollView.contentInset.right)) { // Same as the last condition, but at the end of the collection
                    scrollView.setContentOffset(CGPoint(x: self.view.bounds.width, y: 0), animated: true)
            }
        } else {
            if  (self.leftViewController != nil && self.rightViewController != nil) || // It isn't at the beginning or end of the page collection
                (self.rightViewController != nil && self.leftViewController == nil && scrollView.contentOffset.y > fabs(scrollView.contentInset.left)) || // If it's at the beginning of the collection, the decelleration can't be triggered by scrolling away from, than torwards the inset
                (self.leftViewController != nil && self.rightViewController == nil && scrollView.contentOffset.y < fabs(scrollView.contentInset.right)) { // Same as the last condition, but at the end of the collection
                    scrollView.setContentOffset(CGPoint(x: 0, y: self.view.bounds.height), animated: true)
            }
        }
        
    }
}
