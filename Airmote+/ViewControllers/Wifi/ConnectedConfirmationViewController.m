//
//  ConnectedConfirmationViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/28/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "ConnectedConfirmationViewController.h"
#import "WifiHelper.h"

@interface ConnectedConfirmationViewController ()

@end

@implementation ConnectedConfirmationViewController {
  __weak IBOutlet UILabel *confirmationLabel;

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

}

- (void)updateNetworkStatus {
  NSString *currentSSID = [WifiHelper currentConnectedWiFiSSID];
  if ([self.networkSSID isEqualToString:currentSSID]) {
    if ([self.delegate respondsToSelector:@selector(didConnectedToTheSameNetworkWithInAirDevice)]) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DidSetupWifi"];
            [self.delegate didConnectedToTheSameNetworkWithInAirDevice];
            [[NSNotificationCenter defaultCenter] postNotificationName:kInAirDeviceDidConnectToTheSameWifiNotification object:nil userInfo:nil];
        }];
    }
  } else {
    confirmationLabel.text = self.networkSSID;
//    [self updateConfirmationMessage:currentSSID];
  }
}

- (void)updateConfirmationMessage:(NSString *)currentSSID {
  NSString *message = [NSString stringWithFormat:@"Your InAiR device has connected to %@, and your iPhone is currently connected to %@. Open Settings to change your Wifi network to %@", self.networkSSID, currentSSID, self.networkSSID];
  NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:message];

  NSDictionary *normalText = @{NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:confirmationLabel.font.pointSize] };
  NSDictionary *boldText = @{NSFontAttributeName: [UIFont fontWithName:@"Helvetica-Bold" size:confirmationLabel.font.pointSize] };

  NSRange inAiRNetworkNameRange = [message rangeOfString:self.networkSSID options:0];

  NSUInteger lastLocation = inAiRNetworkNameRange.location + inAiRNetworkNameRange.length + 1;
  NSRange remainingRange = NSMakeRange(lastLocation, message.length - lastLocation);
  NSRange currentNetworkNameRange = [message rangeOfString:currentSSID options:0 range:remainingRange];

  lastLocation = currentNetworkNameRange.length + currentNetworkNameRange.location + 1;
  remainingRange = NSMakeRange(lastLocation, message.length - lastLocation);
  NSRange connectToNetworkNameRange = [message rangeOfString:self.networkSSID options:0 range:remainingRange];

  [attributedMessage setAttributes:normalText range:NSMakeRange(0, message.length)];
  [attributedMessage setAttributes:boldText range:inAiRNetworkNameRange];
  [attributedMessage setAttributes:boldText range:currentNetworkNameRange];
  [attributedMessage setAttributes:boldText range:connectToNetworkNameRange];
  confirmationLabel.attributedText = attributedMessage;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
  [self updateNetworkStatus];

}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
