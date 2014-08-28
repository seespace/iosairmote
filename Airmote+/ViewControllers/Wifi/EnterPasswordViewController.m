//
//  EnterPasswordViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/20/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import "EnterPasswordViewController.h"
#import "ProtoHelper.h"

@interface EnterPasswordViewController ()

@end

@implementation EnterPasswordViewController {
  __weak IBOutlet UITextField *passwordTextField;
  __weak IBOutlet UILabel *wifiNameLabel;

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

  wifiNameLabel.text = self.networkSSID;
  if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    self.edgesForExtendedLayout = UIRectEdgeNone;
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextButtonPressed:)];
}

- (void)viewDidAppear:(BOOL)animated {
  [EventCenter defaultCenter].delegate = self;

}

- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event {
  SetupResponseEvent *ev = [event getExtension:[SetupResponseEvent event]];
  self.navigationItem.rightBarButtonItem.enabled = YES;
  if (ev.error) {
//    NSString *errorMessage = ev.errorMessage;
    [SVProgressHUD showErrorWithStatus:@"Failed to connect"];
  } else {
    [SVProgressHUD showSuccessWithStatus:@"Connected"];
    ConnectedConfirmationViewController *confirmationViewController = [[ConnectedConfirmationViewController alloc] init];
    confirmationViewController.delegate = self;
    confirmationViewController.networkSSID = self.networkSSID;

    [self.navigationController presentViewController:confirmationViewController animated:YES completion:NULL];
  }
}


- (void)didConnectedToTheSameNetworkWithInAirDevice {
  [self.parentViewController.presentingViewController dismissViewControllerAnimated:NO completion:NULL];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)nextButtonPressed:(id)sender {
  Event *ev = [ProtoHelper setupWifiConnectRequestWithSSID:self.networkSSID password:passwordTextField.text];
  [[EventCenter defaultCenter] sendEvent:ev withTag:0];
  self.navigationItem.rightBarButtonItem.enabled = NO;
  [SVProgressHUD showWithStatus:@"InAir device connecting..."];
}

@end
