//
//  TrackPadViewController.h
//  Airmote+
//
//  Created by Long Nguyen on 11/6/13.
//  Copyright (c) 2013 Long Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCDAsyncSocket.h"
#import "GCDAsyncUdpSocket.h"
#import "WebViewController.h"
#import "IAConnection.h"
#import "JDStatusBarNotification.h"
#import "WifiSetupController.h"

@class TrackPadView;
@interface TrackPadViewController : UIViewController <UIActionSheetDelegate, UIGestureRecognizerDelegate, UIWebViewDelegate, NSNetServiceDelegate, UITextViewDelegate, IAConnectionDelegate, UITextFieldDelegate>

@property(nonatomic, strong) UIActionSheet *actionSheet;
@property(nonatomic, strong) UIAlertView *ipAlertView;
@property(nonatomic, strong) WifiSetupController *setupController;

@property (strong, nonatomic) IBOutlet TrackPadView *trackpadView;
@property (strong, nonatomic) IBOutlet WebViewController *webViewController;

- (void)reconnectToServiceIfNeeded;

- (void)dismissControlsBarIfNeeded;
@end
