//
//  ViewController.h
//  Greetings-ObjC
//
//  Created by Erik Malyak on 9/20/16.
//  Copyright © 2016 Erik Malyak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GreetingViewController.h"
@import EMPageViewController;

@interface RootViewController : UIViewController<EMPageViewControllerDataSource, EMPageViewControllerDelegate>

@property (strong, nonatomic, nonnull) EMPageViewController *pageViewController;
@property (strong, nonatomic, nonnull) NSArray<NSString *> *greetings;
@property (strong, nonatomic, nonnull) NSArray<UIColor *> *greetingColors;

@property (weak, nonatomic, nullable) IBOutlet UIButton *reverseButton;
@property (weak, nonatomic, nullable) IBOutlet UIButton *scrollToButton;
@property (weak, nonatomic, nullable) IBOutlet UIButton *forwardButton;

- (IBAction)forward:(id _Nonnull)sender;
- (IBAction)reverse:(id _Nonnull)sender;
- (IBAction)scrollTo:(id _Nonnull)sender;

- (void)setupGreetings;
- (GreetingViewController * _Nullable)viewControllerAtIndex: (NSUInteger)index;
- (NSUInteger)indexOfViewController:(GreetingViewController * _Nonnull)viewController;

@end

