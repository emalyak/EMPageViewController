//
//  GreetingViewController.m
//  Greetings-ObjC
//
//  Created by Erik Malyak on 9/20/16.
//  Copyright © 2016 Erik Malyak. All rights reserved.
//

#import "GreetingViewController.h"

@interface GreetingViewController ()

@end

@implementation GreetingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = self.color;
    self.label.text = self.greeting;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"viewWillAppear: %@", self.greeting);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSLog(@"viewDidAppear: %@", self.greeting);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSLog(@"viewWillDisappear: %@", self.greeting);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    NSLog(@"viewDidDisappear: %@", self.greeting);
}

- (void)dealloc {
    NSLog(@"dealloc: %@", self.greeting);
}

@end
