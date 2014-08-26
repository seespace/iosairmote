//
//  EnterPasswordViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/20/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "EnterPasswordViewController.h"
#import "EventCenter.h"
#import "ProtoHelper.h"

@interface EnterPasswordViewController ()

@end

@implementation EnterPasswordViewController {
  __weak IBOutlet UITextField *passwordTextField;

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
    NSString *errorMessage = ev.errorMessage;

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
  } else {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Connected" message:@"Conencted to Wifi, go an change your wifi back to the same network you connected to."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];

  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)nextButtonPressed:(id)sender {
  Event *ev = [ProtoHelper setupWifiConnectRequestWithSSID:self.networkSDID password:passwordTextField.text];
  [[EventCenter defaultCenter] sendEvent:ev withTag:0];
  self.navigationItem.rightBarButtonItem.enabled = NO;
}

@end
