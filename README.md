# EMPageViewController

![EMPageViewController Demo](https://github.com/emalyak/EMPageViewController/blob/master/greetings-demo.gif)

## A better page view controller for iOS
EMPageViewController is a full replacement for UIPageViewController with the features and predictability you’ve always wanted from a page view controller.

### Delegate messages every step of the way
EMPageViewController gives your delegate messages for every step of the page transition process: before, during, and after. This makes it very easy for you to incorporate animations or any other events that are highly dependent on the progress of transitioning a page.

### Convenient navigation methods
In addition to the ability scroll to any view controller, you can also easily scroll to the next or previous page without gestures if your app has navigation buttons.

### Written in Swift (with support for Objective-C)
EMPageViewController is not a subclass of UIPageViewController. Instead, it's a subclass of UIViewController with a UIScrollView, written in Swift, and it has common sense delegate and data source methods that will make the development of your page-based iOS app a breeze.

## Compatibility
* Xcode 7.0+
* Swift 3.0+
* Objective-C compatible
* iOS 7+
* iPhone, iPad, and iPod Touch

## Installation

There are two ways to install. Please note that the *CocoaPods* method requires iOS 8+, whereas the *file include* method requires iOS 7+

### CocoaPods
To install using CocoaPods, specify the following in your `Podfile`:
```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'EMPageViewController'
```

### File include
Simply include the file [EMPageViewController.swift](https://github.com/emalyak/EMPageViewController/blob/master/EMPageViewController/EMPageViewController.swift) into your project.

## Example usage / Demo
Learn how to use EMPageViewController in your project by cloning this repository and opening the Xcode project file in:
* Swift: [Examples/Greetings](https://github.com/emalyak/EMPageViewController/blob/master/Examples/Greetings).
* Objective-C: [Examples/Greetings-ObjC](https://github.com/emalyak/EMPageViewController/blob/master/Examples/Greetings-ObjC).

The code for initializing EMPageViewController and implementing its delegate and data source is located in:
* Swift: [RootViewController.swift](https://github.com/emalyak/EMPageViewController/blob/master/Examples/Greetings/Greetings/RootViewController.swift)
* Objective-C: [RootViewController.m](https://github.com/emalyak/EMPageViewController/blob/master/Examples/Greetings-ObjC/Greetings-ObjC/RootViewController.m)

## Documentation
Full documentation is available on [CocoaDocs](http://cocoadocs.org/docsets/EMPageViewController)

### Classes
* [EMPageViewController](http://cocoadocs.org/docsets/EMPageViewController/3.0.0/Classes/EMPageViewController.html)

### Enums
* [EMPageViewControllerNavigationDirection](http://cocoadocs.org/docsets/EMPageViewController/3.0.0/Enums/EMPageViewControllerNavigationDirection.html)
* [EMPageViewControllerNavigationOrientation](http://cocoadocs.org/docsets/EMPageViewController/3.0.0/Enums/EMPageViewControllerNavigationOrientation.html)

### Protocols
* [EMPageViewControllerDataSource](http://cocoadocs.org/docsets/EMPageViewController/3.0.0/Protocols/EMPageViewControllerDataSource.html)
* [EMPageViewControllerDelegate](http://cocoadocs.org/docsets/EMPageViewController/3.0.0/Protocols/EMPageViewControllerDelegate.html)

## Contact

Feedback? Suggestions? Just want to say hello? Contact me anytime on Twitter [@emalyak](https://twitter.com/emalyak). You can also visit my website [erikmalyak.com](http://erikmalyak.com) for other ways to get in touch.

## License
Copyright (c) 2015-2016 [Erik Malyak](http://erikmalyak.com)

[MIT License](https://github.com/emalyak/EMPageViewController/blob/master/LICENSE)
