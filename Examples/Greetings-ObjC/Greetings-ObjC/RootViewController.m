//
//  ViewController.m
//  Greetings-ObjC
//
//  Created by Erik Malyak on 9/20/16.
//  Copyright © 2016 Erik Malyak. All rights reserved.
//

#import "RootViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupGreetings];
    
    // Instantiate EMPageViewController and set the data source and delegate to 'self'
    EMPageViewController *pageViewController = [[EMPageViewController alloc] init];
    
    // Or, for a vertical orientation
    // EMPageViewController *pageViewController = [[EMPageViewController alloc] initWithNavigationOrientation:EMPageViewControllerNavigationOrientationVertical];
    
    pageViewController.dataSource = self;
    pageViewController.delegate = self;
    
    // Set the initially selected view controller
    // IMPORTANT: If you are using a dataSource, make sure you set it BEFORE calling selectViewController:direction:animated:completion
    GreetingViewController *currentViewController = [self viewControllerAtIndex:0];
    [pageViewController selectViewController:currentViewController direction:EMPageViewControllerNavigationDirectionForward animated:false completion:nil];
    
    // Add EMPageViewController to the root view controller
    [self addChildViewController:pageViewController];
    [self.view insertSubview:pageViewController.view atIndex:0]; // Insert the page controller view below the navigation buttons
    [pageViewController didMoveToParentViewController:self];
    
    self.pageViewController = pageViewController;
}

- (void)setupGreetings {
    self.greetings = @[@"Hello!", @"¡Hola!", @"Salut!", @"Hallo!", @"Ciao!"];
    self.greetingColors = @[
                            [UIColor colorWithRed:108.0/255.0 green:122.0/255.0 blue:137.0/255.0 alpha:1.0],
                            [UIColor colorWithRed:135.0/255.0 green:211.0/255.0 blue:124.0/255.0 alpha:1.0],
                            [UIColor colorWithRed:34.0/255.0 green:167.0/255.0 blue:240.0/255.0 alpha:1.0],
                            [UIColor colorWithRed:245.0/255.0 green:171.0/255.0 blue:53.0/255.0 alpha:1.0],
                            [UIColor colorWithRed:214.0/255.0 green:69.0/255.0 blue:65.0/255.0 alpha:1.0]
                            ];
}


# pragma mark - Convienient EMPageViewController scroll / transition methods

- (IBAction)forward:(id)sender {
    [self.pageViewController scrollForwardAnimated:true completion:nil];
}

- (IBAction)reverse:(id)sender {
    [self.pageViewController scrollReverseAnimated:true completion:nil];
}

- (IBAction)scrollTo:(id)sender {
    
    UIAlertController *choiceAlertController = [UIAlertController alertControllerWithTitle:@"Scroll To..." message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSUInteger selectedIndex = [self indexOfViewController:(GreetingViewController *)self.pageViewController.selectedViewController];
    
    NSUInteger index = 0;
    
    for (NSString *greeting in self.greetings) {
        
        if (index != selectedIndex) {
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:greeting style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                GreetingViewController *viewController = [self viewControllerAtIndex:index];
                
                EMPageViewControllerNavigationDirection direction = index > selectedIndex ? EMPageViewControllerNavigationDirectionForward : EMPageViewControllerNavigationDirectionReverse;
                
                [self.pageViewController selectViewController:viewController direction:direction animated:YES completion:nil];
                
            }];
            
            [choiceAlertController addAction:action];
        }
        
        index++;
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [choiceAlertController addAction:cancelAction];
    
    [self presentViewController:choiceAlertController animated:YES completion:nil];
    
}


# pragma mark - EMPageViewController Data Source

- (UIViewController *)em_pageViewController:(EMPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger viewControllerIndex = [self indexOfViewController:(GreetingViewController *)viewController];
    if (viewControllerIndex == NSNotFound) {
        return nil;
    } else {
        return [self viewControllerAtIndex:viewControllerIndex - 1];
    }
}

- (UIViewController *)em_pageViewController:(EMPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger viewControllerIndex = [self indexOfViewController:(GreetingViewController *)viewController];
    if (viewControllerIndex == NSNotFound) {
        return nil;
    } else {
        return [self viewControllerAtIndex:viewControllerIndex + 1];
    }
}

- (GreetingViewController * _Nullable)viewControllerAtIndex: (NSUInteger)index {
    if ((self.greetings.count == 0) || (index >= self.greetings.count)) {
        return nil;
    }
    
    GreetingViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GreetingViewController"];
    viewController.greeting = self.greetings[index];
    viewController.color = self.greetingColors[index];
    return viewController;
}

- (NSUInteger)indexOfViewController:(GreetingViewController * _Nonnull)viewController {
    NSString *greeting = viewController.greeting;
    return [self.greetings indexOfObject:greeting];
}


# pragma mark - EMPageViewController Delegate

- (void)em_pageViewController:(EMPageViewController *)pageViewController willStartScrollingFrom:(UIViewController *)startingViewController destinationViewController:(UIViewController *)destinationViewController {
    
    GreetingViewController *startGreetingViewController = (GreetingViewController *)startingViewController;
    GreetingViewController *destinationGreetingViewController = (GreetingViewController *)destinationViewController;
    
    NSLog(@"Will start scrolling from %@ to %@.", startGreetingViewController.greeting, destinationGreetingViewController.greeting);
}

- (void)em_pageViewController:(EMPageViewController *)pageViewController isScrollingFrom:(UIViewController *)startingViewController destinationViewController:(UIViewController *)destinationViewController progress:(CGFloat)progress {
    
    GreetingViewController *startGreetingViewController = (GreetingViewController *)startingViewController;
    GreetingViewController *destinationGreetingViewController = (GreetingViewController *)destinationViewController;
    
    // Ease the labels' alphas in and out
    CGFloat absoluteProgress = fabs(progress);
    startGreetingViewController.label.alpha = pow(1 - absoluteProgress, 2);
    destinationGreetingViewController.label.alpha = pow(absoluteProgress, 2);
    
    NSLog(@"Is scrolling from %@ to %@ with progress %f.", startGreetingViewController.greeting, destinationGreetingViewController.greeting, progress);
}

- (void)em_pageViewController:(EMPageViewController *)pageViewController didFinishScrollingFrom:(UIViewController *)startingViewController destinationViewController:(UIViewController *)destinationViewController transitionSuccessful:(BOOL)transitionSuccessful {
    
    GreetingViewController *startGreetingViewController = (GreetingViewController *)startingViewController;
    GreetingViewController *destinationGreetingViewController = (GreetingViewController *)destinationViewController;
    
    // If the transition is successful, the new selected view controller is the destination view controller.
    // If it wasn't successful, the selected view controller is the start view controller
    if (transitionSuccessful) {
        
        NSUInteger destinationViewControllerIndex = [self indexOfViewController:destinationGreetingViewController];
        
        if (destinationViewControllerIndex == 0) {
            [self.reverseButton setEnabled:NO];
        } else {
            [self.reverseButton setEnabled:YES];
        }
        
        if (destinationViewControllerIndex == self.greetings.count - 1) {
            [self.forwardButton setEnabled:NO];
        } else {
            [self.forwardButton setEnabled:YES];
        }
        
    }
    
    NSLog(@"Finished scrolling from %@ to %@. Transition successful? %@", startGreetingViewController.greeting, destinationGreetingViewController.greeting, (transitionSuccessful ? @"YES" : @"NO"));
    
}


@end
