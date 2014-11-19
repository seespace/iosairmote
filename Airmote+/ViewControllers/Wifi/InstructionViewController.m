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

@interface InstructionViewController ()

@end

@implementation InstructionViewController {
  __weak IBOutlet UILabel *instructionLabel;
  BOOL viewDidAppear;
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

//  [[IAConnection sharedConnection] stop];
//  [[IAConnection sharedConnection] resetStates];
  if ([WifiHelper isConnectedToInAiRWiFi]) {
    [[IAConnection sharedConnection] start];
  }
}

- (BOOL)shouldConnectAutomatically
{
  return [WifiHelper isConnectedToInAiRWiFi];

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
  [SVProgressHUD dismiss];
  [self showVerificationViewController];

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




- (void)connectIfNeeded {
}


- (void)viewDidAppear:(BOOL)animated {
  [IAConnection sharedConnection].delegate = self;
  if (viewDidAppear) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [self connectIfNeeded];
    });

  }
  viewDidAppear = YES;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}



- (void)showVerificationViewController {
  VerifyInAiRViewController *verifyVC = [[VerifyInAiRViewController alloc] init];
  [IAConnection sharedConnection].delegate = verifyVC;
  [self.navigationController pushViewController:verifyVC animated:NO];

}

@end
