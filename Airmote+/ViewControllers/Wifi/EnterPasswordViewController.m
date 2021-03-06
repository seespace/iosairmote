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
  __weak IBOutlet UILabel *wrongPasswordLabel;
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

  passwordTextField.tintColor = [UIColor redColor];
  passwordTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 30)];
  passwordTextField.leftViewMode = UITextFieldViewModeAlways;
  wifiNameLabel.text = self.networkSSID;
  if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    self.edgesForExtendedLayout = UIRectEdgeNone;
  [passwordTextField becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
  [IAConnection sharedConnection].delegate = self;
}

- (void)didReceiveEvent:(Event *)event
{
  SetupResponseEvent *ev = [event getExtension:[SetupResponseEvent event]];
  switch (ev.phase ) {
    case SetupPhaseRequestWifiConnect: {
      if (ev.error) {
        [SVProgressHUD showErrorWithStatus:@"Authentication Failed"];
      } else {
        [SVProgressHUD showSuccessWithStatus:@"Connected"];
        ConnectedConfirmationViewController *confirmationViewController = [[ConnectedConfirmationViewController alloc] init];
        confirmationViewController.delegate = self;
        confirmationViewController.networkSSID = self.networkSSID;
        [self.navigationController pushViewController:confirmationViewController animated:YES];
      }
    }
      break;

    default:
      break;
  }
}


- (void)didConnectedToTheSameNetworkWithInAirDevice {
  [self.parentViewController.presentingViewController dismissViewControllerAnimated:NO completion:NULL];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (YES) {
    Event *ev = [ProtoHelper setupWifiConnectRequestWithSSID:self.networkSSID password:passwordTextField.text];
    [[IAConnection sharedConnection] sendEvent:ev withTag:0];
    [SVProgressHUD showWithStatus:@"InAir device connecting..."];
  }
  
  return YES;
}

- (IBAction)backButtonPressed:(id)sender {
  [self.navigationController popViewControllerAnimated:NO];
}

@end
