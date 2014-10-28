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
#import "InstructionViewController.h"
#import "IAStateMachine.h"
#import "TKState.h"
#import "TKTransition.h"

#define kTimeOutDuration 10.0

@implementation TrackPadViewController {
  NSArray *_services;
  BonjourManager *_bonjourManager;
  NSString *lastConnectedHostName;
  Event *_oauthEvent;
  NSNetService *_selectedService;
  __weak IBOutlet UIView *inputView;
  __weak IBOutlet NSLayoutConstraint *inputViewTopConstrain;
  __weak IBOutlet UITextView *plainText;
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

  [self.navigationController setNavigationBarHidden:YES];
  _trackpadView.viewController = self;

  [self configureStateMachine];
  [self fireStartupEvents];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
}

- (void)showInputView {
  plainText.text = @"";
  [plainText becomeFirstResponder];
}

#pragma mark - AppDidBecomeActive

- (void)applicationDidBecomeActive {
  if ([lastConnectedHostName length] > 0) {
    if (![EventCenter defaultCenter].isActive) {
      [[IAStateMachine sharedStateMachine] fireEvent:kEventFailToConnectToInAiR]; //TODO double check why there 2 events
      [[IAStateMachine sharedStateMachine] fireEvent:kEventServiceResolved];
    }
  } else {
    [self reconnectToServiceIfNeeded];
  }

}

- (void)reconnectToServiceIfNeeded {
  if (![EventCenter defaultCenter].isActive && [_services count]) {
    [self connectToAvailableServices];
  } else {
    [[IAStateMachine sharedStateMachine] fireEvent:kEventBonjourStart];
  }
}


#pragma mark - BonjourManagerDelegate

- (void)bonjourManagerServiceNotFound {
  [SVProgressHUD showErrorWithStatus:@"InAiR devices not found."];
  [[IAStateMachine sharedStateMachine] fireEvent:kEventFailToConnectToInAiR];
}

- (void)bonjourManagerFinishedDiscoveringServices:(NSArray *)services {
  [SVProgressHUD dismiss];
  _services = services;
  [self connectToAvailableServices];
}


#pragma mark - NetServiceDelegate

- (void)netServiceDidStop:(NSNetService *)sender {
  NSLog(@"NetService did stop");
  sender.delegate = nil;
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
  NSLog(@"Service is denied with Error: %@", errorDict);
  sender.delegate = nil;
  [[IAStateMachine sharedStateMachine] fireEvent:kEventFailToConnectToInAiR];
}


- (void)netServiceDidResolveAddress:(NSNetService *)service {
  NSString *address = [(service.addresses)[0] socketAddress];
  lastConnectedHostName = address;
  service.delegate = nil;
  [[IAStateMachine sharedStateMachine] fireEvent:kEventServiceResolved];
}


#pragma mark - EventCenterDelegate

- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event {
  NSLog(@"%@", event);

  // process events
  switch (event.type) {
    case EventTypeOauthRequest:
      [self processOAuthRequest:event];
      break;

    case EventTypeTextInputRequest:
      [self showInputView];
    default:
      break;
  }
}

- (void)eventCenterDidConnectToHost:(NSString *)hostName {
  lastConnectedHostName = hostName;
  TKState *socketConnected = [[IAStateMachine sharedStateMachine] stateNamed:kStateSocketConnected];
  [socketConnected setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
    [SVProgressHUD showSuccessWithStatus:@"Connected"];
  }];
  [[IAStateMachine sharedStateMachine] fireEvent:kEventRealSocketConnected];
}

- (void)eventCenterDidDisconnectFromHost:(NSString *)hostName withError:(NSError *)error {
  [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
  NSLog(@"Error: %@. Code: %ld", [error localizedDescription], (long) [error code]);
}


#pragma mark - Action sheets


- (void)showActionSheet {
  _actionSheet = [[UIActionSheet alloc] init];
  [_actionSheet setTitle:@"Choose a device"];
  [_actionSheet setDelegate:self];

  for (NSNetService *service in _services) {
    NSString *title = service.name;
    [_actionSheet addButtonWithTitle:title];
  }

  [_actionSheet addButtonWithTitle:@"Cancel"];
  _actionSheet.cancelButtonIndex = _services.count;

  [_actionSheet showInView:self.view];
}

#pragma mark - ActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex != actionSheet.cancelButtonIndex) {
    _selectedService = _services[buttonIndex];
    [[IAStateMachine sharedStateMachine] fireEvent:kEventStartResolvingService];
  }
  else {
    [[IAStateMachine sharedStateMachine] fireEvent:kEventFailToConnectToInAiR];
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

#pragma mark - Privates


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


- (void)connectToHost:(NSString *)hostname {
  [EventCenter defaultCenter].delegate = nil;
  _trackpadView.eventCenter = [EventCenter defaultCenter];
  [EventCenter defaultCenter].delegate = self;

  BOOL canStartConnection = [[EventCenter defaultCenter] connectToHost:hostname];
  if (canStartConnection) {
    [SVProgressHUD showWithStatus:@"Connecting" maskType:SVProgressHUDMaskTypeBlack];
  }
}


- (void)fireStartupEvents {
  IAStateMachine *stateMachine = [IAStateMachine sharedStateMachine];
  BOOL completeWifiSetup = [[NSUserDefaults standardUserDefaults] boolForKey:kWifiSetupKey];
  if (! completeWifiSetup) {
    [stateMachine fireEvent:kEventSetupStart];
  } else {
    [stateMachine fireEvent:kEventStartNormalWorkFlow];
  }
}


- (void)configureStateMachine {
  IAStateMachine *stateMachine = [IAStateMachine sharedStateMachine];
  [stateMachine activate];

  TKState *wifiSetupDone = [stateMachine stateNamed:kStateNormalStart];
  [wifiSetupDone setWillEnterStateBlock:^(TKState *state, TKTransition *transition) {
    if ([stateMachine isInState:kStateIdle] || [stateMachine isInState:kStateSameWifiAwaiting]) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startBonjourDiscovery];
      });
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
  _services = nil;
  [_bonjourManager start];
  [SVProgressHUD showWithStatus:@"Scanning..." maskType:SVProgressHUDMaskTypeBlack];

  [[IAStateMachine sharedStateMachine] fireEvent:kEventBonjourStart];
}


- (void)connectToAvailableServices {
  if (_services.count > 1) {
    [[IAStateMachine sharedStateMachine] fireEvent:kEventFoundMultipleServices];
  } else if (_services.count == 1) {
    _selectedService = _services[0];
    [[IAStateMachine sharedStateMachine] fireEvent:kEventStartResolvingService];
  }
}


- (WebViewController *)webViewController {
  if (_webViewController == nil) {
    _webViewController = [[WebViewController alloc] init];
  }

  return _webViewController;
}

#pragma mark - Show/Hide Keyboard


- (void)keyboardWillHide:(NSNotification *)notification {
  float duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
  UIViewAnimationCurve curve = (UIViewAnimationCurve) [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
  UIViewAnimationOptions curveOption = (UIViewAnimationOptions) (curve << 16);
  [UIView animateWithDuration:duration
                        delay:0
                      options:curveOption
                   animations:^{
                      inputViewTopConstrain.constant = - inputView.frame.size.height - 20;
                     [[self view] layoutIfNeeded];

                   } completion:NULL];
}

- (void)keyboardWillShow:(NSNotification *)notification {
  float duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
  UIViewAnimationCurve curve = (UIViewAnimationCurve) [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
  UIViewAnimationOptions curveOption = (UIViewAnimationOptions) (curve << 16);
  [UIView animateWithDuration:duration
                        delay:0
                      options:curveOption
                   animations:^{
                     inputViewTopConstrain.constant = 40;
                     [[self view] layoutIfNeeded];
                   } completion:NULL];

}


- (IBAction)cancelButtonTapped:(id)sender {
  Event *event = [ProtoHelper textInputResponseWithState:TextInputResponseEventStateCancelled text:plainText.text];
  [[EventCenter defaultCenter] sendEvent:event withTag:0];
  [self dismissInputView];
}


- (IBAction)sendButtonTapped:(id)sender {
  [self dismissInputView];
  Event *event = [ProtoHelper textInputResponseWithState:TextInputResponseEventStateEnded text:plainText.text];
  [[EventCenter defaultCenter] sendEvent:event withTag:0];
}

- (void)dismissInputView {
  [plainText resignFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView {
  Event *event = [ProtoHelper textInputResponseWithState:TextInputResponseEventStateChanged text:plainText.text];
  [[EventCenter defaultCenter] sendEvent:event withTag:0];
}


- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
