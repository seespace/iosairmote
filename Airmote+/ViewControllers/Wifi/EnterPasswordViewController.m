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

  wifiNameLabel.text = self.networkSSID;
  if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    self.edgesForExtendedLayout = UIRectEdgeNone;
  [passwordTextField becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
  [EventCenter defaultCenter].delegate = self;

}

- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event {
  SetupResponseEvent *ev = [event getExtension:[SetupResponseEvent event]];
  switch (ev.phase ) {
    case SetupPhaseRequestWifiConnect: {
      if (ev.error) {
        [SVProgressHUD dismiss];
        wrongPasswordLabel.text = @"WRONG PASSWORD";
        [UIView animateWithDuration:0.6 animations:^{
          wrongPasswordLabel.alpha = 1.0;
        }];
        
      } else {
        [SVProgressHUD showSuccessWithStatus:@"Connected"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAirConnectedToSelectedWifiNotification object:nil userInfo:@{kNetworkSSIDKey: self.networkSSID}];
      }
    }
      break;
      
    default:
      break;
  }
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField.text.length >= 5) {
    Event *ev = [ProtoHelper setupWifiConnectRequestWithSSID:self.networkSSID password:passwordTextField.text];
    [[EventCenter defaultCenter] sendEvent:ev withTag:0];
    [SVProgressHUD showWithStatus:@"InAir device connecting..."];
    [UIView animateWithDuration:0.6 animations:^{
      wrongPasswordLabel.alpha = 0.0;
    }];

  } else {
    wrongPasswordLabel.text = @"PASSWORD MUST BE AT LEAST 5 CHARACTERS";
    [UIView animateWithDuration:0.6 animations:^{
      wrongPasswordLabel.alpha = 1.0;
    }];

  }
  
  return YES;
}

- (IBAction)backButtonPressed:(id)sender {
  [self.navigationController popViewControllerAnimated:NO];
}

@end
