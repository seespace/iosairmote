//
//  TrackPadViewController.m
//  Airmote+
//
//  Created by Long Nguyen on 11/6/13.
//  Copyright (c) 2013 Long Nguyen. All rights reserved.
//

#import "TrackPadViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "ProtoHelper.h"
#import "TrackPadView.h"
#import "NSData+NetService.h"
#import "WifiHelper.h"
#import "InstructionViewController.h"
#import "IAStateMachine.h"
#import "TKState.h"
#import "TKTransition.h"

#define kTimeOutDuration 10.0

@interface TrackPadViewController () {
  BOOL _serverSelectorDisplayed;
  Event *_oauthEvent;
  NSNetService *_selectedService;
}

@end

@implementation TrackPadViewController {
  NSArray *_services;
  BonjourManager *_bonjourManager;
  NSString *lastConnectedHostName;
}

static const uint8_t kMotionShakeTag = 6;

@synthesize trackpadView = _trackpadView;
@synthesize webViewController = _webViewController;

- (void)viewDidLoad {
  [super viewDidLoad];
  _bonjourManager = [[BonjourManager alloc] init];
  _bonjourManager.delegate = self;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationDidBecomeActive)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(inAirDeviceDiDConnect:)
                                               name:kInAirDeviceDidConnectToWifiNotification
                                             object:nil];

  [self.navigationController setNavigationBarHidden:YES];
  _trackpadView.viewController = self;

  [self configureStateMachine];
  [self fireStartupEvents];
}

- (void)fireStartupEvents {
  IAStateMachine *stateMachine = [IAStateMachine sharedStateMachine];
  BOOL requiredWifiSetup = [[NSUserDefaults standardUserDefaults] boolForKey:kWifiSetupKey];
  if (requiredWifiSetup) {
    [stateMachine fireEvent:kEventSetupStart userInfo:nil error:nil];
  } else {
    [stateMachine fireEvent:kEventStartNormalWorkFlow userInfo:nil error:nil];
  }
}

- (void)configureStateMachine {
  IAStateMachine *stateMachine = [IAStateMachine sharedStateMachine];
  [stateMachine activate];

  TKState *wifiSetupDone = [stateMachine stateNamed:kStateNormalStart];
  [wifiSetupDone setWillEnterStateBlock:^(TKState *state, TKTransition *transition) {
    if ([stateMachine.currentState.name isEqualToString:kStateIdle]) {
      [self startBonjourDiscovery];
    }
  }];

  TKState *wifiSetupStart = [stateMachine stateNamed:kStateWifiSetupStart];
  [wifiSetupStart setWillEnterStateBlock:^(TKState *state, TKTransition *transition) {
    if ([stateMachine.currentState.name isEqualToString:kStateIdle] || [stateMachine.currentState.name isEqualToString:kStateBonjourDiscoveryFailed]) {
      [self startWifiSetupWorkFlow];
    }
  }];

  TKState *foundMultipleServices = [[IAStateMachine sharedStateMachine] stateNamed:kStateFoundMultipleServices];
  [foundMultipleServices setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
    [self showActionSheet];
  }];


  TKState *serviceResolvingState = [[IAStateMachine sharedStateMachine] stateNamed:kStateServiceResolving];
  [serviceResolvingState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
    [self connectToService:_selectedService];
  }];

  TKState *serviceResolvedState = [[IAStateMachine sharedStateMachine] stateNamed:kStateAddressResolved];
  [serviceResolvedState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
    [self connectToHost:lastConnectedHostName];
  }];
}

- (void)startWifiSetupWorkFlow {
  InstructionViewController *instructionViewController = [[InstructionViewController alloc] init];
  UINavigationController *navigationVC = [[UINavigationController alloc] initWithRootViewController:instructionViewController];
  navigationVC.navigationBarHidden = YES;
  [self.navigationController presentViewController:navigationVC
                                          animated:NO
                                        completion:NULL];
}


- (void)startBonjourDiscovery {

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [_bonjourManager start];
    _services = nil;
    [SVProgressHUD showWithStatus:@"Scanning..." maskType:SVProgressHUDMaskTypeBlack];

    NSError *error = nil;

    [[IAStateMachine sharedStateMachine] fireEvent:kEventBonjourStart userInfo:nil error:&error];
    if (error) {
      NSLog(@"ERROR: %@", error);
    }

  });
}

- (void)inAirDeviceDiDConnect:(NSNotification *)notification {
  [[EventCenter defaultCenter] disconnect];
  [self reconnectToServiceIfNeeded];
}


- (void)viewWillAppear:(BOOL)animated {
  [self.navigationController setNavigationBarHidden:YES];
}

#pragma mark -
#pragma mark Auto reconnect when become active

- (void)applicationDidBecomeActive {
  // Clear out cached services when the app coming back from foreground
  // because the services might be gone by the time we coming back.

//  BOOL requiredWifi = [[NSUserDefaults standardUserDefaults] boolForKey:kWifiSetupKey];
//  if (!requiredWifi) {
//    if (self.navigationController.presentedViewController != nil) {
//      [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
//    }
//  }
//
//  if ([lastConnectedHostName length] > 0) {
//    if (![EventCenter defaultCenter].isActive) {
//      [[EventCenter defaultCenter] connectToHost:lastConnectedHostName];
////      isReconnecting = YES;
//    }
//  } else {
//    [self reconnectToServiceIfNeeded];
//  }

}

- (void)reconnectToServiceIfNeeded {
  BOOL requiredWifiSetup = [[NSUserDefaults standardUserDefaults] boolForKey:kWifiSetupKey];
  if ([WifiHelper isConnectedToInAiRWiFi] || requiredWifiSetup)
    return;

  if (_serverSelectorDisplayed) {
    return;
  }

  if (![EventCenter defaultCenter].isActive && [_services count]) {
    [self connectToAvailableServices];
  } else {
    [_bonjourManager start];
    _services = nil;
    [SVProgressHUD showWithStatus:@"Scanning..." maskType:SVProgressHUDMaskTypeBlack];
  }
}

#pragma mark - BonjourManagerDelegate

- (void)bonjourManagerServiceNotFound {
  [SVProgressHUD showErrorWithStatus:@"InAiR devices not found."];
  NSError *error = NULL;
  [[IAStateMachine sharedStateMachine] fireEvent:kEventFailToConnectToInAiR userInfo:nil error:&error];
  if (error) {
    NSLog(@"Cannot fire event: [%@] - error: %@", kEventFailToConnectToInAiR, [error description]);
  }
}

- (void)bonjourManagerFinishedDiscoveringServices:(NSArray *)services {
  [SVProgressHUD dismiss];
  _services = services;
  if (!_serverSelectorDisplayed) {
    [self connectToAvailableServices];
  }
}


#pragma mark - Action sheets

- (void)connectToAvailableServices {
  NSError *error = NULL;
  if (_services.count > 1) {
    [[IAStateMachine sharedStateMachine] fireEvent:kEventFoundMultipleServices userInfo:nil error:&error];
  } else if (_services.count == 1) {
    _selectedService = _services[0];
    [[IAStateMachine sharedStateMachine] fireEvent:kEventStartResolvingService userInfo:nil error:&error];
  }

  if (error) {
    NSLog(@"ERROR: %@", error);
  }

}

- (void)showActionSheet {
  _actionSheet = [[UIActionSheet alloc] init];
  [_actionSheet setDelegate:self];

  [_actionSheet setTitle:@"Choose a device"];

  for (NSNetService *service in _services) {
      NSString *title = service.name;
      [_actionSheet addButtonWithTitle:title];
    }

  [_actionSheet addButtonWithTitle:@"Cancel"];
  _actionSheet.cancelButtonIndex = _services.count;

  [_actionSheet showInView:self.view];
//  _serverSelectorDisplayed = YES;  #warning: might need to check
}

- (void)connectToService:(NSNetService *)service {
  if (service.addresses.count > 0) {
    NSString *address = [(service.addresses)[0] socketAddress];
    [self connectToHost:address];
  }
  else {
    service.delegate = self;
    [service resolveWithTimeout:kTimeOutDuration];
  }
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSError *error = nil;
  if (buttonIndex != actionSheet.cancelButtonIndex) {
    _selectedService = _services[buttonIndex];
    [[IAStateMachine sharedStateMachine] fireEvent:kEventStartResolvingService userInfo:nil error:&error];
  }
  else {
    //TODO double check
//    _serverSelectorDisplayed = NO;
    [[IAStateMachine sharedStateMachine] fireEvent:kEventFailToConnectToInAiR userInfo:nil error:&error] ;
  }
//  _serverSelectorDisplayed = NO;
  if (error) {
    NSLog(@"ERROR: %@", error );
  }

}

#pragma mark - AlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if ([alertView.title isEqualToString:@"OAuth"]) {
    if (buttonIndex != alertView.cancelButtonIndex) {
      [self processOAuthRequest];
    }
  }
}


#pragma mark - EventCenterDelegate

- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event {
  NSLog(@"%@", event);

  // process events
  switch (event.type) {
    case EventTypeOauthRequest:
      [self processOAuthRequest:event];
      break;

    default:
      break;
  }
}

- (void)eventCenterDidConnectToHost:(NSString *)hostName {
  lastConnectedHostName = hostName;
//  if (isReconnecting) {
//    isReconnecting = NO;
//  }
//  else {
    TKState *socketConnected = [[IAStateMachine sharedStateMachine] stateNamed:kStateSocketConnected];
    [socketConnected setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
      [SVProgressHUD showSuccessWithStatus:@"Connected"];
    }];
    NSError *error = nil;
    [[IAStateMachine sharedStateMachine] fireEvent:kEventRealSocketConnected userInfo:nil error:&error];
    if (error) {
      NSLog(@"ERROR: %@", error);
    }

//  }

}

- (void)eventCenterDidDisconnectFromHost:(NSString *)hostName withError:(NSError *)error {
//  if (isReconnecting) {
//    if (![EventCenter defaultCenter].isActive) {
//      if ([hostName isEqualToString:lastConnectedHostName]) {
//        [self reconnectToServiceIfNeeded];
//      }
//    }
//  } else {
//    isConnecting = NO;
    [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
    NSLog(@"Error: %@. Code: %ld", [error localizedDescription], (long) [error code]);
//  }
//  lastConnectedHostName = nil;
}

#pragma mark - NetServiceDelegate

- (void)netServiceDidStop:(NSNetService *)sender {
  NSLog(@"NetService did stop");
  sender.delegate = nil;
  //TODO check if this need to go to an event
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
  NSLog(@"Service is denied with Error: %@", errorDict);
  sender.delegate = nil;
//  isConnecting = NO;
  [[IAStateMachine sharedStateMachine] fireEvent:kEventFailToConnectToInAiR userInfo:nil error:nil];
}


- (void)netServiceDidResolveAddress:(NSNetService *)service {
  NSString *address = [(service.addresses)[0] socketAddress];

  lastConnectedHostName = address;
  service.delegate = nil;
  [[IAStateMachine sharedStateMachine] fireEvent:kEventServiceResolved userInfo:nil error:nil];
}

#pragma mark -
#pragma mark Motion

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
  if (motion == UIEventSubtypeMotionShake) {
    Event *ev = [ProtoHelper motionEventWithTimestamp:(SInt64) (event.timestamp * 1000)
                                                 type:MotionEventTypeShake];
    [[EventCenter defaultCenter] sendEvent:ev withTag:kMotionShakeTag];
  }
}


#pragma mark -
#pragma mark OAuth

- (void)processOAuthRequest:(Event *)event {
  if (_oauthEvent == nil) {
    _oauthEvent = event;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"OAuth" message:@"InAir would like to open webview for OAuth authentication." delegate:self cancelButtonTitle:@"Don't Allow" otherButtonTitles:@"OK", nil];
    [alertView show];
  }
}

- (void)processOAuthRequest {
  if (_oauthEvent == nil) {
    return;
  }

  if (self.navigationController.topViewController != self.webViewController) {
    OAuthRequestEvent *event = [_oauthEvent getExtension:[OAuthRequestEvent event]];
    self.webViewController.URL = [NSURL URLWithString:event.authUrl];
    self.webViewController.delegate = self;
    self.webViewController.eventCenter = [EventCenter defaultCenter];
    self.webViewController.oauthEvent = _oauthEvent;
    [self.webViewController load];

    [self.navigationController pushViewController:self.webViewController animated:YES];
  }
}


#pragma mark -
#pragma mark Others

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


#pragma mark - Privates


- (void)connectToHost:(NSString *)hostname {

  [EventCenter defaultCenter].delegate = nil;


  _trackpadView.eventCenter = [EventCenter defaultCenter];
  [EventCenter defaultCenter].delegate = self;
  BOOL canStartConnection = [[EventCenter defaultCenter] connectToHost:hostname];
  if (canStartConnection) {
    [SVProgressHUD showWithStatus:@"Connecting" maskType:SVProgressHUDMaskTypeBlack];
  }
}


- (WebViewController *)webViewController {
  if (_webViewController == nil) {
    _webViewController = [[WebViewController alloc] init];
  }

  return _webViewController;
}

@end