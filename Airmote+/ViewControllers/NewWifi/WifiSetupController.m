//
// Created by Long Nguyen on 2/12/15.
// Copyright (c) 2015 Long Nguyen. All rights reserved.
//

#import "WifiSetupController.h"
#import "WSInstructionController.h"
#import "WSNetworksController.h"
#import "WSEnterPasswordController.h"


@implementation WifiSetupController {

}

- (void)viewDidLoad {
  [super viewDidLoad];
  WSInstructionController *initialController = [[WSInstructionController alloc] init];
  [self setViewControllers:@[initialController] animated:NO];
}

- (UIViewController<MBPage> *)setupController:(MBSetupController *)setupController viewControllerAfterViewController:(UIViewController<MBPage> *)viewController {
  if ([viewController isKindOfClass:[WSInstructionController class]]) {
    WSNetworksController *networksController = [[WSNetworksController alloc] init];
    return networksController;
  }
  if ([viewController isKindOfClass:[WSNetworksController class]]) {
    WifiNetwork *network = [(WSNetworksController *) viewController selectedNetwork];
    WSEnterPasswordController *enterPasswordController = [[WSEnterPasswordController alloc] initWithNetwork:network];
    return enterPasswordController;
  }
  return nil;
}

@end
