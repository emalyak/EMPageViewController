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


protocol EMPageViewControllerDataSource {
    func em_pageViewController(pageViewController:EMPageViewController, viewControllerLeftOfViewController viewController:UIViewController) -> UIViewController?
    func em_pageViewController(pageViewController:EMPageViewController, viewControllerRightOfViewController viewController:UIViewController) -> UIViewController?
}

protocol EMPageViewControllerDelegate {
    func em_pageViewController(pageViewController:EMPageViewController, willStartTransitionFrom startingViewController:UIViewController, destinationViewController:UIViewController)
    func em_pageViewController(pageViewController:EMPageViewController, didFinishTransitionFrom startingViewController:UIViewController, destinationViewController:UIViewController, transitionSuccesful:Bool)
    func em_pageViewController(pageViewController:EMPageViewController, isTransitioningFrom startingViewController:UIViewController, destinationViewController:UIViewController, progress:Float)
}


class EMPageViewController: UIViewController, UIScrollViewDelegate {
    
    var dataSource:EMPageViewControllerDataSource?

    let scrollView:UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.pagingEnabled = true
        scrollView.scrollsToTop = false
        scrollView.autoresizingMask = .FlexibleLeftMargin | .FlexibleRightMargin
        scrollView.setTranslatesAutoresizingMaskIntoConstraints(true)
        return scrollView
    }()
    
    
    private var leftViewController:UIViewController?
    private var currentViewController:UIViewController?
    private var rightViewController:UIViewController?
    
    var scrolling = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        self.view.addSubview(scrollView)
    }
    
    func setCurrentViewController(viewController:UIViewController, animated:Bool, completion:(()->())?) {
        
        // Scrolled right
        if (viewController == self.rightViewController) {
            
            // Hide the old left controller
            self.removeChild(self.leftViewController)
            
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
        
        // Scrolled left
        } else if (viewController == self.leftViewController) {
            
            // Hide the old left controller
            self.removeChild(self.rightViewController)
            
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
        
        // Scrolled but ended up where started
        } else if (viewController == self.currentViewController) {
            
            // Remove hidden view controllers
            self.removeChild(self.leftViewController)
            self.removeChild(self.rightViewController)
            
        // Initialization
        } else {
            
            // Set controller as current
            self.currentViewController = viewController
            
            // Show view controller
            self.addChild(self.currentViewController!)
            
            // Retreive left and right view controllers if available
            if let leftViewController = self.dataSource?.em_pageViewController(self, viewControllerLeftOfViewController: viewController) {
                self.leftViewController = leftViewController
            }
            
            if let rightViewController = self.dataSource?.em_pageViewController(self, viewControllerRightOfViewController: viewController) {
                self.rightViewController = rightViewController
            }
            
        }
        
    }
    
    private func didScrollToViewController(viewController:UIViewController) {
        self.setCurrentViewController(viewController, animated: false, completion: nil)
        self.layoutViews()
    }
    
    private func addChild(viewController:UIViewController) {
        self.scrollView.addSubview(viewController.view)
        self.addChildViewController(viewController)
        viewController.didMoveToParentViewController(self)
    }
    
    private func removeChild(viewController:UIViewController?) {
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
        
        self.scrollView.contentOffset = CGPoint(x: viewWidth, y: 0)
        self.scrollView.contentInset = UIEdgeInsetsMake(0, leftInset, 0, rightInset)
        
        self.leftViewController?.view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        self.currentViewController?.view.frame = CGRect(x: viewWidth, y: 0, width: viewWidth, height: viewHeight)
        self.rightViewController?.view.frame = CGRect(x: viewWidth * 2, y: 0, width: viewWidth, height: viewHeight)
    }
    
    
    // MARK: - UIScrollView Delegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {

        if scrolling {
        
            let viewWidth = self.view.bounds.width
            let progress = (scrollView.contentOffset.x - viewWidth) / viewWidth
            
            if (progress > 0) {
                if (self.rightViewController != nil) {
                    self.addChild(self.rightViewController!)
                }
            } else {
                if (self.leftViewController != nil) {
                    self.addChild(self.leftViewController!)
                }
            }
            
            if (progress >= 1 && self.rightViewController != nil) {
                self.didScrollToViewController(self.rightViewController!)
            } else if (progress <= -1  && self.leftViewController != nil) {
                self.didScrollToViewController(self.leftViewController!)
            } else if (progress == 0  && self.currentViewController != nil) {
                
            }
        }
        
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.scrolling = true
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.scrolling = false
    }

}
