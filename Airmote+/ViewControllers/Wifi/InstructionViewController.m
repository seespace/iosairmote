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

@interface InstructionViewController ()

@end

@implementation InstructionViewController {
  __weak IBOutlet UILabel *instructionLabel;

  BonjourManager *_bonjourManager;
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

  _bonjourManager = [[BonjourManager alloc] init];
  _bonjourManager.delegate = self;

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
    [_bonjourManager start];
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

  NSError *error = nil;
  if ([EventCenter defaultCenter].isActive) {
    [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupSocketConnected userInfo:nil error:&error];
  } else {
    if ([WifiHelper isConnectedToInAiRWiFi]) {
      [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupDetectedInAirWifi userInfo:nil error:&error];
    } else {
      [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupFailedToConnectToSocket userInfo:nil error:&error];
    }
  }

  if (error) {
    NSLog(@"connectIfNeeded - ERROR: %@", [error description]);
  }
}



- (void)viewDidAppear:(BOOL)animated {
  [EventCenter defaultCenter].delegate = self;
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
//  isDiscoveringBonjourServices = NO;
  NSError *error = nil;
  if ([services count]) {
    
    _netService.delegate = nil;
    [_netService stop];
    _netService = services[0];
    _netService.delegate = self;

    [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupFoundBonjourService userInfo:nil error:&error];
  } else {
    [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupFailedToConnectToSocket userInfo:nil error:&error];
  }

  if (error) {

    NSLog(@"bonjourManagerFinishedDiscoveringServices - ERROR: %@", [error description]);
  }

}

- (void)bonjourManagerServiceNotFound {
  NSError *error = nil;
  [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupFailedToConnectToSocket userInfo:nil error:&error];
  if (error) {
    NSLog(@"bonjourManagerServiceNotFound - ERROR: %@", [error description]);
  }
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
  NSLog(@"Failed to resolve address for service: %@", sender);

  NSError *error = nil;
  [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupFailedToConnectToSocket userInfo:nil error:&error];
  if (error) {
    NSLog(@"netService: didNotResolve: - ERROR: %@", [error description]);
  }
}


- (void)netServiceDidResolveAddress:(NSNetService *)service {
  NSError *error = nil;

  if ([service.addresses count]) {
    _netService.delegate = nil;
    _lastResolvedAddress = [(service.addresses)[0] socketAddress];
    [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupServiceResolved userInfo:nil error:&error];

  } else {
    _lastResolvedAddress = nil;
      [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupFailedToConnectToSocket userInfo:nil error:&error];
    }

  if (error) {
    NSLog(@"netServiceDidResolveAddress: - ERROR: %@", [error description]);
  }
}


- (void)connectToHost:(NSString *)hostname {

  EventCenter *eventCenter = [EventCenter defaultCenter];
  eventCenter.delegate = nil;

  eventCenter = [EventCenter defaultCenter];
  eventCenter.delegate = self;
  BOOL isConnecting = [eventCenter connectToHost:hostname];
  if (isConnecting) {
    [SVProgressHUD showWithStatus:@"Connecting" maskType:SVProgressHUDMaskTypeBlack];
  }
}

- (void)eventCenterDidConnectToHost:(NSString *)hostName {
  NSError *error = nil;

  [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupSocketConnected userInfo:nil error:&error];
  if (error) {
    NSLog(@"eventCenterDidConnectToHost: - ERROR: %@", [error description]);
  }

}


- (void)showVerificationViewController {
  VerifyInAiRViewController *verifyVC = [[VerifyInAiRViewController alloc] init];
  [EventCenter defaultCenter].delegate = verifyVC;
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
