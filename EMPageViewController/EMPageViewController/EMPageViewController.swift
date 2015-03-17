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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        self.view.addSubview(scrollView)
    }
    
    func setCurrentViewController(viewController:UIViewController, animated:Bool, completion:(()->())?) {
        self.scrollView.addSubview(viewController.view)
        self.addChildViewController(viewController)
        viewController.didMoveToParentViewController(self)
        self.currentViewController = viewController
        
        if (dataSource != nil) {
            
            if let leftViewController = self.dataSource!.em_pageViewController(self, viewControllerLeftOfViewController: viewController) {
                self.scrollView.addSubview(leftViewController.view)
                self.addChildViewController(leftViewController)
                leftViewController.didMoveToParentViewController(self)
                self.leftViewController = leftViewController
            }
            
            if let rightViewController = self.dataSource!.em_pageViewController(self, viewControllerRightOfViewController: viewController) {
                self.scrollView.addSubview(rightViewController.view)
                self.addChildViewController(rightViewController)
                rightViewController.didMoveToParentViewController(self)
                self.rightViewController = rightViewController
            }

        }

    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.scrollView.frame = self.view.bounds
        let viewWidth = self.view.bounds.width
        let viewHeight = self.view.bounds.height
        
        var scrollViewContentSizeWidth = viewWidth
        var scrollViewContentOffset = 0 as CGFloat
        
        if (self.leftViewController != nil) {
            scrollViewContentSizeWidth += viewWidth
            scrollViewContentOffset += viewWidth
        }
        
        if (self.rightViewController != nil) {
            scrollViewContentSizeWidth += viewWidth
        }
        
        self.scrollView.contentSize = CGSize(width: scrollViewContentSizeWidth, height: self.view.bounds.height)
        self.scrollView.contentOffset = CGPoint(x: scrollViewContentOffset, y: 0)
        
        self.leftViewController?.view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        self.currentViewController?.view.frame = CGRect(x: scrollViewContentOffset, y: 0, width: viewWidth, height: viewHeight)
        self.rightViewController?.view.frame = CGRect(x: scrollViewContentOffset + viewWidth, y: 0, width: viewWidth, height: viewHeight)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
