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
#import "InstructionViewController.h"

@implementation TrackPadViewController {
  Event *_oauthEvent;
  __weak IBOutlet UIView *inputView;
  __weak IBOutlet NSLayoutConstraint *inputViewTopConstrain;
  __weak IBOutlet UITextView *plainText;
  __weak IBOutlet NSLayoutConstraint *bottomControlsConstrain;
}

static const uint8_t kMotionShakeTag = 6;

@synthesize trackpadView = _trackpadView;
@synthesize webViewController = _webViewController;

- (void)viewDidLoad {
  [super viewDidLoad];
  [[IAConnection sharedConnection] setDelegate:self];

  [self.navigationController setNavigationBarHidden:YES];
  _trackpadView.viewController = self;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didFinishWifiSetup:)
                                               name:kInAirDeviceDidConnectToWifiNotification
                                             object:nil];
}


- (BOOL)shouldConnectAutomatically
{
  return YES;
}

- (void)didStartScanning
{
  [SVProgressHUD showWithStatus:@"Scanning..."];
}

-(void)didStartConnecting
{
  [SVProgressHUD showWithStatus:@"Connecting..."];
}


- (void)didConnect:(NSString *)hostName
{
  NSString *message = [NSString stringWithFormat:@"Connected to %@", hostName];
  [SVProgressHUD showSuccessWithStatus:message];
}


- (void)didFoundServices:(NSArray *)foundServices
{
  [SVProgressHUD dismiss];
  [self showActionSheetForServices:foundServices];
}


- (void)didFailToConnect:(NSError *)error
{
  switch (error.code) {
    case IAConnectionErrorServicesNotFound:
    case IAConnectionErrorDiscoveryTimedOut:
    case IAConnectionErrorDidNotSearch:
    case IAConnectionErrorServiceNotResolved:
    case IAConnectionErrorSocketInvalidData:
    case IAConnectionErrorWifiNotAvailable:
    case IAConnectionErrorFailToConnectSocket:
      [SVProgressHUD showErrorWithStatus:[error localizedFailureReason]];
      break;

    case IAConnectionErrorSocketDisconnected:
      [SVProgressHUD showErrorWithStatus:@"Connection is lost!"];
      break;

    case IAConnectionErrorFailToSendEvent:
      NSLog(@"Failed to send event");
      break;

    default:
      DDLogError(@"ERROR: %@", [error localizedFailureReason]);
      break;
  }
}


- (void)didReceiveEvent:(Event *)event
{
  NSLog(@"%@", event);

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

-(void)viewDidAppear:(BOOL)animated
{
  [IAConnection sharedConnection].delegate = self;
}

- (void)showInputView {
  plainText.text = @"";
  [plainText becomeFirstResponder];
}

#pragma mark - AppDidBecomeActive


- (void)reconnectToServiceIfNeeded {
  [[IAConnection sharedConnection] start];
}

#pragma mark - Action sheets


- (void)showActionSheetForServices:(NSArray *) services {
  _actionSheet = [[UIActionSheet alloc] init];
  [_actionSheet setTitle:@"Choose a device"];
  [_actionSheet setDelegate:self];

  for (NSNetService *service in services) {
    NSString *title = service.name;
    [_actionSheet addButtonWithTitle:title];
  }

  [_actionSheet addButtonWithTitle:@"Cancel"];
  _actionSheet.cancelButtonIndex = services.count;

  [_actionSheet showInView:self.view];
}

#pragma mark - ActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex != actionSheet.cancelButtonIndex) {
    [[IAConnection sharedConnection] connectToServiceAtIndex:(NSUInteger) buttonIndex];
  }
}

#pragma mark - AlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if ([alertView.title isEqualToString:@"OAuth"]) {
    if (buttonIndex != alertView.cancelButtonIndex) {
      [self processOAuthRequest];
    }
  }
  _oauthEvent = nil;
}

#pragma mark -
#pragma mark Motion

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
  if (motion == UIEventSubtypeMotionShake) {
    Event *ev = [ProtoHelper motionEventWithTimestamp:(SInt64) (event.timestamp * 1000)
                                                 type:MotionEventTypeShake];
    [[IAConnection sharedConnection] sendEvent:ev withTag:kMotionShakeTag];
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

  self.webViewController = [[WebViewController alloc] init];
  if (self.navigationController.topViewController != self.webViewController) {
    OAuthRequestEvent *event = [_oauthEvent getExtension:[OAuthRequestEvent event]];
    self.webViewController.URL = [NSURL URLWithString:event.authUrl];
    self.webViewController.delegate = self;
    self.webViewController.oauthEvent = _oauthEvent;
    [self.webViewController load];

    [self.navigationController pushViewController:self.webViewController animated:YES];
  }
}

#pragma mark - Privates


- (void)startWifiSetupWorkFlow {
  InstructionViewController *instructionViewController = [[InstructionViewController alloc] init];
  UINavigationController *navigationVC = [[UINavigationController alloc] initWithRootViewController:instructionViewController];
  navigationVC.navigationBarHidden = YES;
  [self.navigationController presentViewController:navigationVC
                                          animated:YES
                                        completion:NULL];
//  [self.navigationController transitionFromViewController:<#(UIViewController *)fromViewController#> toViewController:<#(UIViewController *)toViewController#> duration:<#(NSTimeInterval)duration#> options:<#(UIViewAnimationOptions)options#> animations:<#(void (^)(void))animations#> completion:<#(void (^)(BOOL finished))completion#>];
}



//- (WebViewController *)webViewController {
//  if (_webViewController == nil) {
//    _webViewController = [[WebViewController alloc] init];
//  }
//
//  return _webViewController;
//}

#pragma mark - DidFinishWifiSetup

- (void)didFinishWifiSetup:(id)didFinishWifiSetup
{
  [[IAConnection sharedConnection] setDelegate:self];
}


- (void)didStopConnection
{
  [SVProgressHUD dismiss];
}


#pragma mark - Show/Hide Keyboard


- (void)keyboardWillHide:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  float duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
  UIViewAnimationCurve curve = (UIViewAnimationCurve) [userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
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
  NSDictionary *userInfo = [notification userInfo];
  float duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
  UIViewAnimationCurve curve = (UIViewAnimationCurve) [userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
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
  [[IAConnection sharedConnection] sendEvent:event withTag:0];
  [self dismissInputView];
}


- (IBAction)sendButtonTapped:(id)sender {
  [self dismissInputView];
  Event *event = [ProtoHelper textInputResponseWithState:TextInputResponseEventStateEnded text:plainText.text];
  [[IAConnection sharedConnection] sendEvent:event withTag:0];
}
- (IBAction)settingsButtonTapped:(id)sender {
  [self startWifiSetupWorkFlow];
}

- (void)dismissInputView {
  [plainText resignFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView {
  Event *event = [ProtoHelper textInputResponseWithState:TextInputResponseEventStateChanged text:plainText.text];
  [[IAConnection sharedConnection] sendEvent:event withTag:0];
}

- (IBAction)moreButtonTapped:(id)sender {
  [self toggleControlsView];
}

- (void)toggleControlsView
{
  [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:20 options:0
                   animations:^{
                     bottomControlsConstrain.constant = bottomControlsConstrain.constant == 0 ? -43 : 0;
                     [self.view layoutIfNeeded];
                   } completion:NULL];
}

- (IBAction)screenModeButtonTapped:(id)sender {
  [[IAConnection sharedConnection] sendEvent:[ProtoHelper functionEventResponseWithState:FunctionEventKeyF4] withTag:0];
}

- (IBAction)refreshButtonTapped:(id)sender {
  [[IAConnection sharedConnection] stop];
  [[IAConnection sharedConnection] resetStates];
  [[IAConnection sharedConnection] start];
  [self toggleControlsView];
}
@end
