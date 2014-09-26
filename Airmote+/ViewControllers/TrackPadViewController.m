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

#define kTimeOutDuration 10.0

@interface TrackPadViewController () {
  BOOL _serverSelectorDisplayed;

  Event *_oauthEvent;
}

@end

@implementation TrackPadViewController {
  NSArray *_services;
  BonjourManager *_bonjourManager;
  BOOL isConnecting;
  NSString *lastConnectedHostName;
  BOOL isReconnecting;
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
                                               name:@"applicationDidBecomeActive"
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inAirDeviceDiDConnect:) name:kInAirDeviceDidConnectToWifiNotification object:nil];

  [self.navigationController setNavigationBarHidden:YES];
  _trackpadView.viewController = self;

  BOOL requiredWifiSetup = [[NSUserDefaults standardUserDefaults] boolForKey:kWifiSetupKey];
  if (! requiredWifiSetup) {
    [_bonjourManager start];
    isConnecting = YES;
    _services = nil;
    [SVProgressHUD showWithStatus:@"Scanning..." maskType:SVProgressHUDMaskTypeBlack];
  } else {
    InstructionViewController *instructionViewController = [[InstructionViewController alloc] init];
    UINavigationController *navigationVC = [[UINavigationController alloc] initWithRootViewController:instructionViewController];
    navigationVC.navigationBarHidden = YES;
    [self.navigationController presentViewController:navigationVC
                                            animated:NO
                                          completion:NULL];

  }
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
  
  BOOL requiredWifi = [[NSUserDefaults standardUserDefaults] boolForKey:kWifiSetupKey];
  if (!requiredWifi) {
    if (self.navigationController.presentedViewController != nil){
      [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
    }
  }
  
  if ([lastConnectedHostName length] > 0) {
    if (![EventCenter defaultCenter].isActive) {
      [[EventCenter defaultCenter] connectToHost:lastConnectedHostName];
      isReconnecting = YES;
    }
  } else {
    [self reconnectToServiceIfNeeded];
  }

}

- (void)reconnectToServiceIfNeeded {
  BOOL requiredWifiSetup = [[NSUserDefaults standardUserDefaults] boolForKey:kWifiSetupKey];
  if ([WifiHelper isConnectedToInAiRWiFi] || requiredWifiSetup)
    return;

  if (isConnecting || _serverSelectorDisplayed) {
    return;
  }

  if (![EventCenter defaultCenter].isActive && [_services count]) {
    [self chooseServerWithMessage:@"Choose a device"];
  } else {
    [_bonjourManager start];
    _services = nil;
    [SVProgressHUD showWithStatus:@"Scanning..." maskType:SVProgressHUDMaskTypeBlack];
    isConnecting = YES;

  }
}

#pragma mark - BonjourManagerDelegate


- (void)bonjourManagerServiceNotFound {
  [SVProgressHUD showErrorWithStatus:@"Service not found"];
  isConnecting = NO;
}

- (void)bonjourManagerFinishedDiscoveringServices:(NSArray *)services {
  [SVProgressHUD dismiss];
  isConnecting = NO;
  _services = services;
  if (!_serverSelectorDisplayed) {
    [self chooseServerWithMessage:@"Choose a device"];
  }
}


#pragma mark - Action sheets

- (void)chooseServerWithMessage:(NSString *)message {
  if (_services.count > 1) {
    _actionSheet = [[UIActionSheet alloc] init];
    [_actionSheet setDelegate:self];

    [_actionSheet setTitle:message];

    for (NSNetService *service in _services) {
      NSString *title = service.name;
      [_actionSheet addButtonWithTitle:title];
    }

    [_actionSheet addButtonWithTitle:@"Cancel"];
    _actionSheet.cancelButtonIndex = _services.count;

    [_actionSheet showInView:self.view];
    _serverSelectorDisplayed = YES;
  } else if (_services.count == 1) {
    NSNetService *service = (NSNetService *) _services[0];
    [self connectToService:service];
  } else {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AirServer"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Connect", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *alertTextField = [alert textFieldAtIndex:0];
    alertTextField.placeholder = @"inair.local or 127.0.0.1";
    [alert show];
  }
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
  if (buttonIndex != actionSheet.cancelButtonIndex) {
    NSNetService *service = (NSNetService *) _services[buttonIndex];
    [self connectToService:service];
  }
  else {
    _serverSelectorDisplayed = NO;
  }
  _serverSelectorDisplayed = NO;
}

#pragma mark - AlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if ([alertView.title isEqualToString:@"AirServer"]) {
    if (buttonIndex != alertView.cancelButtonIndex) {
      UITextField *alertTextField = [alertView textFieldAtIndex:0];
      [self connectToHost:alertTextField.text];
    }
  } else if ([alertView.title isEqualToString:@"OAuth"]) {
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
  if (isReconnecting) {
    isReconnecting = NO;
  }
  else {
    [SVProgressHUD showSuccessWithStatus:@"Connected"];
    isConnecting = NO;
  }
}

- (void)eventCenterDidDisconnectFromHost:(NSString *)hostName withError:(NSError *)error {
  if (isReconnecting) {
    if (![EventCenter defaultCenter].isActive) {
      if ([hostName isEqualToString:lastConnectedHostName]) {
        [self reconnectToServiceIfNeeded];
      }
    }
  } else {
    isConnecting = NO;
    [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
    NSLog(@"Error: %@. Code: %ld", [error localizedDescription], (long) [error code]);
  }
  lastConnectedHostName = nil;
}

#pragma mark - NetServiceDelegate

-(void)netServiceDidStop:(NSNetService *)sender {
  NSLog(@"NetService did stop");
  sender.delegate = nil;
  
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
  NSLog(@"Service is denied with Error: %@", errorDict);
  sender.delegate = nil;
  isConnecting = NO;
}


- (void)netServiceDidResolveAddress:(NSNetService *)service {
  NSString *address = [(service.addresses)[0] socketAddress];
  [self connectToHost:address];
  service.delegate = nil;
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
