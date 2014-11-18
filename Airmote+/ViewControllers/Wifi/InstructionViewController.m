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
#import "NSData+NetService.h"
#import "WifiHelper.h"
#import "TKState.h"
#import "IAStateMachine.h"
#import "IAConnection.h"

@interface InstructionViewController ()

@end

@implementation InstructionViewController {
  __weak IBOutlet UILabel *instructionLabel;

  NSNetService *_netService;
  BOOL viewDidAppear;
  NSString *_lastResolvedAddress;
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

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
  viewDidAppear = NO;
  [self configureStateMachine];
}

- (void)configureStateMachine {
  TKState *bonjourDiscoveryState = [[IAStateMachine sharedStateMachine] stateNamed:kStateSetupBonjourDiscovery];
  [bonjourDiscoveryState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {

  }];

  TKState *serviceResolvingState = [[IAStateMachine sharedStateMachine] stateNamed:kStateSetupServiceResolving];
  [serviceResolvingState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
    [_netService resolveWithTimeout:10];
  }];

  TKState *serviceResolved = [[IAStateMachine sharedStateMachine] stateNamed:kStateSetupServiceResolved];
  [serviceResolved setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
    [self connectToHost:_lastResolvedAddress];
  }];

  TKState *socketConnected = [[IAStateMachine sharedStateMachine] stateNamed:kStateSetupSocketConnected];
  [socketConnected setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
    [SVProgressHUD dismiss];
    [self showVerificationViewController];
  }];
}


- (void)didBecomeActive:(NSNotification *)notification {

  [self connectIfNeeded];

}

- (void)connectIfNeeded {

  if ([IAConnection sharedConnection].isConnected) {
    [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupSocketConnected];
  } else {
    if ([WifiHelper isConnectedToInAiRWiFi]) {
      [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupDetectedInAirWifi];
    } else {
      [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupFailedToConnectToSocket];
    }
  }

  NSLog(@"connectIfNeeded");
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

- (void)bonjourManagerFinishedDiscoveringServices:(NSArray *)services {
  if ([services count]) {

    _netService.delegate = nil;
    [_netService stop];
    _netService = services[0];
    _netService.delegate = self;

    [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupFoundBonjourService];
  } else {
    [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupFailedToConnectToSocket];
  }

  NSLog(@"bonjourManagerFinishedDiscoveringServices");
}

- (void)bonjourManagerServiceNotFound {
  [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupFailedToConnectToSocket];
  NSLog(@"bonjourManagerServiceNotFound");
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
  NSLog(@"Failed to resolve address for service: %@", sender);
  [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupFailedToConnectToSocket];
}


- (void)netServiceDidResolveAddress:(NSNetService *)service {
  if ([service.addresses count]) {
    _netService.delegate = nil;
    _lastResolvedAddress = [(service.addresses)[0] socketAddress];
    [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupServiceResolved];

  } else {
    _lastResolvedAddress = nil;
    [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupFailedToConnectToSocket];
  }

    NSLog(@"netServiceDidResolveAddress:");
}


- (void)connectToHost:(NSString *)hostname {
  [IAConnection sharedConnection].delegate = self;
  //TODO rewrite this
//  BOOL isConnecting = [eventCenter connectToHost:hostname];
//  if (isConnecting) {
//    [SVProgressHUD showWithStatus:@"Connecting" maskType:SVProgressHUDMaskTypeBlack];
//  }
}

- (void)eventCenterDidConnectToHost:(NSString *)hostName {

  [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupSocketConnected];
  NSLog(@"eventCenterDidConnectToHost");
}


- (void)showVerificationViewController {
  VerifyInAiRViewController *verifyVC = [[VerifyInAiRViewController alloc] init];
  [IAConnection sharedConnection].delegate = verifyVC;
  [self.navigationController pushViewController:verifyVC animated:NO];

}


- (void)eventCenterDidDisconnectFromHost:(NSString *)hostName withError:(NSError *)error {
  [SVProgressHUD dismiss];
  //TODO check if this need to fire an event
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
