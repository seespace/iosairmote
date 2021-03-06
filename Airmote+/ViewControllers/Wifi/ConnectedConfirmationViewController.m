//
//  ConnectedConfirmationViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/28/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "ConnectedConfirmationViewController.h"
#import "WifiHelper.h"
#import "Reachability.h"

@interface ConnectedConfirmationViewController ()

@end

@implementation ConnectedConfirmationViewController {
  __weak IBOutlet UILabel *networkSSIDLabel;

  Reachability *reachability;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
  [self updateNetworkStatus];
  networkSSIDLabel.text = self.networkSSID;
  reachability = [Reachability reachabilityForLocalWiFi];
  __weak ConnectedConfirmationViewController * weakSelf = self;
  [reachability setReachableBlock:^(Reachability *r) {
    [weakSelf updateNetworkStatus];
  }];
  [reachability startNotifier];
}

- (void)updateNetworkStatus {
  NSString *currentSSID = [WifiHelper currentConnectedWiFiSSID];
  if ([self.networkSSID isEqualToString:currentSSID]) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kRequireWifiSetup];
    [[NSNotificationCenter defaultCenter] postNotificationName:kInAirDeviceDidConnectToWifiNotification object:nil userInfo:nil];
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];

  }
}


- (void)applicationDidBecomeActive:(NSNotification *)notification {
  [self updateNetworkStatus];

}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
