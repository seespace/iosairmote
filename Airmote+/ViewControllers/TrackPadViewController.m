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
#import "NSString+IPAddress.h"
#import "JDStatusBarNotification+Extension.h"
#import "WifiSetupController.h"

#define kIPAddressAlertTitle @"Manual Connect"

@implementation TrackPadViewController {
  Event *_oauthEvent;
  __weak IBOutlet UIView *inputView;
  __weak IBOutlet NSLayoutConstraint *inputViewTopConstrain;
  __weak IBOutlet UITextView *plainText;
  __weak IBOutlet NSLayoutConstraint *bottomControlsConstrain;
  __weak IBOutlet UIPageControl *pageControl;
  NSString *lastManuallyConnectedIP;
}

static const uint8_t kMotionShakeTag = 6;

@synthesize ipAlertView = _ipAlertView;
@synthesize trackpadView = _trackpadView;
@synthesize webViewController = _webViewController;
@synthesize setupController = _setupController;

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
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appWillBecomeInactive:) name:UIApplicationWillResignActiveNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification
                                             object:nil];


  bottomControlsConstrain.constant = -54;

  [JDStatusBarNotification inAirInit];
}

- (void)viewWillAppear:(BOOL)animated {
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
    // app already launched
  } else {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    // This is the first launch ever

    [self startWifiSetup];
  }
}

- (void)startWifiSetup {
  _setupController = [[WifiSetupController alloc] init];
  _setupController.dataSource = _setupController;
  [self presentViewController:_setupController animated:YES completion:nil];
}

- (void)appWillBecomeInactive:(NSNotification *)notification {
  [SVProgressHUD dismiss];
  [JDStatusBarNotification dismiss];
//  [[IAConnection sharedConnection] stopServer];
}

- (void)appDidBecomeActive:(NSNotification *)notification {
  [[IAConnection sharedConnection] startServer];
}

- (void)appDidEnterBackground:(NSNotification *)notification {
  [[IAConnection sharedConnection] stopServer];
}

- (BOOL)shouldConnectAutomatically {
  return YES;
}

- (void)didStartScanning {
//  [SVProgressHUD showWithStatus:@"Scanning..."];
  [JDStatusBarNotification showWithStatus:@"Scanning..."];
  [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleGray];
}

- (void)didStartConnecting {
//  [SVProgressHUD showWithStatus:@"Connecting..."];
  [JDStatusBarNotification showWithStatus:@"Connecting..."];
  [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleGray];
}


- (void)didConnect:(NSString *)hostName {
  NSString *message = [NSString stringWithFormat:@"Connected to %@", hostName];
//  [SVProgressHUD showSuccessWithStatus:message];
  [JDStatusBarNotification showSuccessWithStatus:message dismissAfter:kAnimationSlow];
}


- (void)didFoundServices:(NSArray *)foundServices {
  if (foundServices.count > 0) {
    [JDStatusBarNotification dismiss];
    [self showActionSheetForServices:foundServices];
  } else {
    [JDStatusBarNotification showErrorWithStatus:@"No InAiR devices found"];
  }
}


- (void)didFailToConnect:(NSError *)error {
  switch (error.code) {
    case IAConnectionErrorServicesNotFound:
    case IAConnectionErrorDiscoveryTimedOut:
    case IAConnectionErrorDidNotSearch:
    case IAConnectionErrorServiceNotResolved:
    case IAConnectionErrorSocketInvalidData:
    case IAConnectionErrorWifiNotAvailable:
    case IAConnectionErrorFailToConnectSocket:
      [JDStatusBarNotification showErrorWithStatus:[error localizedFailureReason]];
      [self showActionSheetForServices:[[IAConnection sharedConnection] foundServices]];

      break;

    case IAConnectionErrorSocketDisconnected:
//      [JDStatusBarNotification showWithStatus:@"Connection is lost!" styleName:@"InAirError"];
      [JDStatusBarNotification showErrorWithStatus:[error localizedDescription]];
      break;

    case IAConnectionErrorFailToSendEvent:
      NSLog(@"Failed to send event");
      break;

    default:
      DDLogError(@"ERROR: %@", [error localizedFailureReason]);
      break;
  }
}


- (void)didReceiveEvent:(Event *)event {
  NSLog(@"%@", event);

  switch (event.type) {
    case EventTypeOauthRequest:
      [self processOAuthRequest:event];
      break;

    case EventTypeTextInputRequest:
      [self showInputView];
      break;

    case EventTypeWebviewRequest:
      [self processWebViewRequest:event];
      break;
    default:
      break;
  }

}

- (void)didStartUSBConnection {
  [JDStatusBarNotification showUSBConnection];
}

- (void)didStopUSBConnection:(NSError *)error {
  [JDStatusBarNotification dismissAfter:kAnimationFast];
  if (_setupController != nil) {
    [self dismissViewControllerAnimated:true completion:nil];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [IAConnection sharedConnection].delegate = self;
//  [self didStartUSBConnection];
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


- (void)showActionSheetForServices:(NSArray *)services {

  if ([_actionSheet isVisible]) {
    return;
  }

  _actionSheet = [[UIActionSheet alloc] init];
  [_actionSheet setTitle:@"Choose a device"];
  [_actionSheet setDelegate:self];

  for (NSNetService *service in services) {
    NSString *title = service.name;
    [_actionSheet addButtonWithTitle:title];
  }

  [_actionSheet addButtonWithTitle:@"Other"];

  [_actionSheet addButtonWithTitle:@"Cancel"];
  _actionSheet.cancelButtonIndex = services.count + 1;

  [_actionSheet showInView:self.view];
}

#pragma mark - ActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex != actionSheet.cancelButtonIndex) {
    if (buttonIndex == actionSheet.numberOfButtons - 2) {
      _ipAlertView = [[UIAlertView alloc] initWithTitle:kIPAddressAlertTitle
                                                message:@"Please enter your InAir box IP Address."
                                               delegate:self
                                      cancelButtonTitle:@"Done"
                                      otherButtonTitles:nil];
      _ipAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
      UITextField *textField = [_ipAlertView textFieldAtIndex:0];
      textField.placeholder = @"192.168.1.1";
      textField.returnKeyType = UIReturnKeyGo;
      textField.delegate = self;
      [_ipAlertView show];
    } else {
      [[IAConnection sharedConnection] connectToServiceAtIndex:(NSUInteger) buttonIndex];
    }
  } else {
    [JDStatusBarNotification showErrorWithStatus:@"No Connection"];
  }
}

#pragma mark - AlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if ([alertView.title isEqualToString:@"OAuth"]) {
    if (buttonIndex != alertView.cancelButtonIndex) {
      [self processOAuthRequest];
    }
  } else if ([alertView.title isEqualToString:kIPAddressAlertTitle]) {
    NSString *ipaddress = [alertView textFieldAtIndex:0].text;

//    if ([ipaddress length] == 0 || ![ipaddress isValidIPAddress]) {
//      UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                          message:@"Invalid IP Address. Please try again."
//                                                         delegate:nil
//                                                cancelButtonTitle:@"OK"
//                                                otherButtonTitles:nil];
//      [alertView show];
//    } else {
    [alertView dismissWithClickedButtonIndex:0 animated:true];
    [[IAConnection sharedConnection] stop];
    [[IAConnection sharedConnection] resetStates];
    [[IAConnection sharedConnection] connectToHost:ipaddress];
//    }
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
#pragma mark WebView

- (void)processWebViewRequest:(Event *)ev {
  _oauthEvent = nil;

  WebViewRequestEvent *event = [ev getExtension:[WebViewRequestEvent event]];

  if (self.webViewController == nil) {
    self.webViewController = [[WebViewController alloc] initWithUrl:[NSURL URLWithString:event.url]];
    self.webViewController.oauthEvent = nil;
    self.webViewController.webViewEvent = ev;
    [self.webViewController showFromController:self];
  } else if (self.webViewController.presentingViewController == nil) {
    self.webViewController.oauthEvent = nil;
    self.webViewController.webViewEvent = ev;
    [self.webViewController navigateToURL:[NSURL URLWithString:event.url]];
    [self.webViewController showFromController:self];
  } else {
    // busy
  }
}

#pragma mark -
#pragma mark OAuth

- (void)processOAuthRequest:(Event *)event {
  _oauthEvent = event;

  [self processOAuthRequest];
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"OAuth" message:@"InAir would like to open webview for OAuth authentication." delegate:self cancelButtonTitle:@"Don't Allow" otherButtonTitles:@"OK", nil];
//    [alertView show];
}

- (void)processOAuthRequest {
  if (_oauthEvent == nil) {
    return;
  }

  OAuthRequestEvent *event = [_oauthEvent getExtension:[OAuthRequestEvent event]];
  if (self.webViewController == nil) {
    self.webViewController = [[WebViewController alloc] initWithUrl:[NSURL URLWithString:event.authUrl]];
    self.webViewController.oauthEvent = _oauthEvent;
    [self.webViewController showFromController:self];
  } else if (self.webViewController.presentingViewController == nil) {
    self.webViewController.oauthEvent = _oauthEvent;
    [self.webViewController navigateToURL:[NSURL URLWithString:event.authUrl]];
    [self.webViewController showFromController:self];
  } else {
    // busy
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

- (void)didFinishWifiSetup:(id)didFinishWifiSetup {
  [[IAConnection sharedConnection] setDelegate:self];
}


- (void)didStopConnection {
  [SVProgressHUD dismiss];
}

#pragma mark - TextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  if ([_ipAlertView textFieldAtIndex:0] == textField) {
    NSString *ipaddress = [_ipAlertView textFieldAtIndex:0].text;
    [_ipAlertView dismissWithClickedButtonIndex:0 animated:true];
    [[IAConnection sharedConnection] stop];
    [[IAConnection sharedConnection] resetStates];
    [[IAConnection sharedConnection] connectToHost:ipaddress];
  }
  return YES;
}


#pragma mark - Show/Hide Keyboard


- (void)keyboardWillHide:(NSNotification *)notification {
  if (!plainText.isFirstResponder)
    return;

  NSDictionary *userInfo = [notification userInfo];
  float duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
  UIViewAnimationCurve curve = (UIViewAnimationCurve) [userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
  UIViewAnimationOptions curveOption = (UIViewAnimationOptions) (curve << 16);
  [UIView animateWithDuration:duration
                        delay:0
                      options:curveOption
                   animations:^{
                     inputViewTopConstrain.constant = -inputView.frame.size.height - 20;
                     [[self view] layoutIfNeeded];

                   } completion:NULL];
}

- (void)keyboardWillShow:(NSNotification *)notification {
  if (!plainText.isFirstResponder)
    return;

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
  [self startWifiSetup];
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

- (void)toggleControlsView {
  [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:20 options:0
                   animations:^{
                     bottomControlsConstrain.constant = bottomControlsConstrain.constant == 0 ? -54 : 0;
                     [self.view layoutIfNeeded];
                   } completion:NULL];
}

- (IBAction)infoButtonTapped:(id)sender {
  JBWebViewController *infoViewController = [[JBWebViewController alloc] initWithUrl:[NSURL URLWithString:kHelpURL]];
  [infoViewController showFromController:self];
}

- (IBAction)fastForwardButtonTapped:(id)sender {
  [[IAConnection sharedConnection] sendEvent:[ProtoHelper functionEventResponseWithState:FunctionEventKeyMediaFastForward] withTag:0];

}

- (IBAction)playPauseButtonTapped:(id)sender {
  [[IAConnection sharedConnection] sendEvent:[ProtoHelper functionEventResponseWithState:FunctionEventKeyMediaPlay] withTag:0];
}

- (IBAction)rewindButtonTapped:(id)sender {
  [[IAConnection sharedConnection] sendEvent:[ProtoHelper functionEventResponseWithState:FunctionEventKeyMediaRewind] withTag:0];
}


- (IBAction)screenModeButtonTapped:(id)sender {
  [[IAConnection sharedConnection] sendEvent:[ProtoHelper functionEventResponseWithState:FunctionEventKeyF4] withTag:0];
}

- (IBAction)refreshButtonTapped:(id)sender {
  [self toggleControlsView];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [[IAConnection sharedConnection] stop];
    [[IAConnection sharedConnection] resetStates];
    [[IAConnection sharedConnection] start];
  });
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGFloat pageWidth = scrollView.frame.size.width;
  float fractionalPage = scrollView.contentOffset.x / pageWidth;
  NSInteger page = lround(fractionalPage);
  pageControl.currentPage = page; // you need to have a **iVar** with getter for pageControl
}

- (void)dismissControlsBarIfNeeded {
  if (bottomControlsConstrain.constant == 0.0) {
    [self toggleControlsView];
  }
}
@end
