//
//  AppDelegate.m
//  Airmote+
//
//  Created by Long Nguyen on 11/6/13.
//  Copyright (c) 2013 Long Nguyen. All rights reserved.
//

#import "AppDelegate.h"
#import "InstructionViewController.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#import "Antenna.h"
#import "DDAntennaLogger.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@implementation AppDelegate

@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [Fabric with:@[CrashlyticsKit]];

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  if ([[NSUserDefaults standardUserDefaults] objectForKey:kRequireWifiSetup] == nil) {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kRequireWifiSetup];
  }

  TrackPadViewController *viewController = [[TrackPadViewController alloc] init];
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
  navigationController.navigationBarHidden = YES;
  self.window.rootViewController = navigationController;

  UIView *view=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
  view.backgroundColor = RGBA(242, 242, 242, 0.9f);
  [self.window.rootViewController.view addSubview:view];

  [self.window makeKeyAndVisible];

  [self setupLogger];
  return YES;
}

- (void)setupLogger {
  [DDLog addLogger:[DDASLLogger sharedInstance]];
  [DDLog addLogger:[DDTTYLogger sharedInstance]];

#ifdef DEBUG
  [[Antenna sharedLogger] addChannelWithURL:[NSURL URLWithString:@"http://yosemite.local:3205/log/"] method:@"POST"];
  [[Antenna sharedLogger] startLoggingApplicationLifecycleNotifications];

  DDAntennaLogger *logger = [[DDAntennaLogger alloc] initWithAntenna:[Antenna sharedLogger]];
  [DDLog addLogger:logger];
#endif
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state.
  // This can occur for certain types of temporary interruptions (such as an
  // incoming phone call or SMS message) or when the user quits the application
  // and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down
  // OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate
  // timers, and store enough application state information to restore your
  // application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called
  // instead of applicationWillTerminate: when the user quits.
  [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationDidEnterBackground" object:self];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state;
  // here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationDidBecomeActive" object:self];
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
