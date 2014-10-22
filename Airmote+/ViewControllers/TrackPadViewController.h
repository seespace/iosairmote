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
#import "BonjourManager.h"
#import "EventCenter.h"

#define kWifiSetupKey @"enable_wifi_setup"
@class TrackPadView;
@interface TrackPadViewController : UIViewController <UIActionSheetDelegate, UIGestureRecognizerDelegate, UIWebViewDelegate, BonjourManagerDelegate, EventCenterDelegate, NSNetServiceDelegate, UITextViewDelegate>

@property(nonatomic, strong) UIActionSheet *actionSheet;

@property(strong, nonatomic) IBOutlet TrackPadView *trackpadView;
@property(strong, nonatomic) IBOutlet WebViewController *webViewController;

- (void)reconnectToServiceIfNeeded;
@end
