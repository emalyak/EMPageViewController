//
//  GreetingViewController.h
//  Greetings-ObjC
//
//  Created by Erik Malyak on 9/20/16.
//  Copyright © 2016 Erik Malyak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GreetingViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) NSString *greeting;
@property (strong, nonatomic) UIColor *color;

@end
