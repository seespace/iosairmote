//
//  AppDelegate.h
//  Airmote+
//
//  Created by Long Nguyen on 11/6/13.
//  Copyright (c) 2013 Long Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TrackPadViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) TrackPadViewController *viewController;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end
