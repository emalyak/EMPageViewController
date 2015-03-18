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

enum EMPageViewControllerNavigationDirection : Int {
    case Neutral
    case Forward
    case Reverse
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
    
    private var navigationDirection:EMPageViewControllerNavigationDirection = .Neutral
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        self.view.addSubview(scrollView)
    }
    
    func setCurrentViewController(viewController:UIViewController, animated:Bool, completion:(()->())?) {
        
        // Scrolled right
        if (viewController == self.rightViewController) {
            
            // Release the old left controller
            self.removeViewControllerIfNeeded(self.leftViewController)
            
            // Set new left controller as the old current controller
            self.leftViewController = self.currentViewController
            
            // Set the new current controller as the old right controller
            self.currentViewController = self.rightViewController
            
            println("current: \((self.currentViewController as GreetingViewController).greeting)")
            
            // Get the new right controller from the data source if available
            if self.dataSource != nil {
                if let rightViewController = self.dataSource!.em_pageViewController(self, viewControllerRightOfViewController: viewController) {
                    self.rightViewController = rightViewController
                }
            }
        
        // Scrolled left
        } else if (viewController == self.leftViewController) {
            
            // Release the old left controller
            self.removeViewControllerIfNeeded(self.rightViewController)
            
            // Set new right controller as the old current controller
            self.rightViewController = self.currentViewController
            
            // Set the new current controller as the old left controller
            self.currentViewController = self.leftViewController
            
            // Get the new left controller from the data source if available
            if self.dataSource != nil {
                if let leftViewController = self.dataSource!.em_pageViewController(self, viewControllerLeftOfViewController: viewController) {
                    self.leftViewController = leftViewController
                }
            }
        
        // Scrolled but ended up where started
        } else if (viewController == self.currentViewController) {
            
            self.removeViewControllerIfNeeded(self.leftViewController)
            self.removeViewControllerIfNeeded(self.rightViewController)
            
        // Initialized
        } else {
            
            self.currentViewController = viewController
            self.addViewControllerIfNeeded(self.currentViewController!)
            
            if self.dataSource != nil {
                
                if let leftViewController = self.dataSource!.em_pageViewController(self, viewControllerLeftOfViewController: viewController) {
                    self.leftViewController = leftViewController
                }
                
                if let rightViewController = self.dataSource!.em_pageViewController(self, viewControllerRightOfViewController: viewController) {
                    self.rightViewController = rightViewController
                }
                
            }
            
        }
        
        self.navigationDirection = .Neutral
                
    }
    
    func addViewControllerIfNeeded(viewController:UIViewController) {
        self.scrollView.addSubview(viewController.view)
        self.addChildViewController(viewController)
        viewController.didMoveToParentViewController(self)
    }
    
    func removeViewControllerIfNeeded(viewController:UIViewController?) {
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
    
    func didScrollToViewController(viewController:UIViewController) {
        self.setCurrentViewController(viewController, animated: false, completion: nil)
        self.layoutViews()
    }
        
    func scrollViewDidScroll(scrollView: UIScrollView) {

        let viewWidth = self.view.bounds.width
        let progress = (scrollView.contentOffset.x - viewWidth) / viewWidth
        
        //println("progress: \(progress)")
        
        if (progress > 0) {
            if (self.rightViewController != nil) {
                self.addViewControllerIfNeeded(self.rightViewController!)
            }
        } else {
            if (self.leftViewController != nil) {
                self.addViewControllerIfNeeded(self.leftViewController!)
            }
        }
        
        if (progress >= 1 && self.rightViewController != nil) {
            self.navigationDirection = .Forward
        } else if (progress <= -1  && self.leftViewController != nil) {
            self.navigationDirection = .Reverse
        } else if (progress == 0  && self.currentViewController != nil) {
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        switch self.navigationDirection {
        case .Neutral:
            self.didScrollToViewController(self.currentViewController!)
            break
        case .Forward:
            self.didScrollToViewController(self.rightViewController!)
            break
        case .Reverse:
            self.didScrollToViewController(self.leftViewController!)
            break
        }
    }

}
