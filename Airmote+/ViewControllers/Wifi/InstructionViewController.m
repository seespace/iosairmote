//
//  InstructionViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/19/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "InstructionViewController.h"
#import "VerifyInAiRViewController.h"
#import "SVProgressHUD.h"
#import "WifiHelper.h"
#import "ProtoHelper.h"

@interface InstructionViewController ()

@end

@implementation InstructionViewController {
  __weak IBOutlet UILabel *instructionLabel;
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
  [IAConnection sharedConnection].delegate = self;

  if ([WifiHelper isConnectedToInAiRWiFi]) {
    if ([IAConnection sharedConnection].isConnected) {
      [self requestConfirmationCode];
    } else {
      [[IAConnection sharedConnection] start];
    }
  }
}

- (BOOL)shouldConnectAutomatically
{
  return [WifiHelper isConnectedToInAiRWiFi];

}

- (IBAction)backTapped:(id)sender {
  [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  
}

-(void)didStartScanning
{
  [SVProgressHUD showWithStatus:@"Scanning"];
}

- (void)didStartConnecting
{
  [SVProgressHUD showWithStatus:@"Connecting"];
}

- (void)didConnect:(NSString *)hostName
{
//  [SVProgressHUD dismiss];

  [self requestConfirmationCode];
}

-(void)didFoundServices:(NSArray *)foundServices {
  if (foundServices.count ) {
    [[IAConnection sharedConnection] connectToServiceAtIndex:0];
  }
}

-(void)didFailToConnect:(NSError *)error
{
  switch (error.code) {
    case IAConnectionErrorServicesNotFound:
      [SVProgressHUD showErrorWithStatus:@"Devices not found!"];
      break;
      
    case IAConnectionErrorDiscoveryTimedOut:
      [SVProgressHUD showErrorWithStatus:@"Timed out"];
      break;
      
    case IAConnectionErrorDidNotSearch:
      [SVProgressHUD showErrorWithStatus:@"Cannot start scanning"];
      break;
      
    case IAConnectionErrorSocketLost:
      [SVProgressHUD showErrorWithStatus:@"Socket is lost!"];
      break;
      
    case IAConnectionErrorServiceNotResolved:
      [SVProgressHUD showErrorWithStatus:@"Cannot resolve service"];
      break;
      
    case IAConnectionErrorSocketInvalidData:
      [SVProgressHUD showErrorWithStatus:@"Socket data is invalid"];
      break;
      
    case IAConnectionErrorFailToSendEvent:
      NSLog(@"Failed to send event");
      break;
      
    case IAConnectionErrorWifiNotAvailable:
      [SVProgressHUD showErrorWithStatus:@"Wifi is not available"];
      break;
      
    case IAConnectionErrorFailToConnectSocket:
      [SVProgressHUD showErrorWithStatus:@"Cannot connect to socket"];
      break;
      
    default:
      [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Unknown Error Code: %ld", (long)error.code]];
      break;
  }
}

- (void)didReceiveEvent:(Event *)event
{
  [SVProgressHUD dismiss];
  SetupResponseEvent *ev = [event getExtension:[SetupResponseEvent event]];
  NSString *confirmationCode = ev.code;

  switch (ev.phase) {
    case SetupPhaseRequestCode: {
      VerifyInAiRViewController *verifyVC = [[VerifyInAiRViewController alloc] init];
      verifyVC.confirmationCode = confirmationCode;
      [self.navigationController pushViewController:verifyVC animated:YES];
      break;
    }
    default:
      NSLog(@"Event recevied - Phase: %d", ev.phase);
  }

}



- (void)viewDidAppear:(BOOL)animated {
  [IAConnection sharedConnection].delegate = self;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)requestConfirmationCode {
  [SVProgressHUD showWithStatus:@"Requesting Code"];
  Event *ev = [ProtoHelper setupCodeRequest];
  [[IAConnection sharedConnection] sendEvent:ev withTag:0];
}

@end
