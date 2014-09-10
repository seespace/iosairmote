//
//  ViewController.h
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
@class TrackPadView;
@interface ViewController : UIViewController <UIActionSheetDelegate, UIGestureRecognizerDelegate, UIWebViewDelegate, BonjourManagerDelegate, EventCenterDelegate, NSNetServiceDelegate>

@property(nonatomic, strong) UIActionSheet *actionSheet;

@property(strong, nonatomic) IBOutlet TrackPadView *trackpadView;
@property(strong, nonatomic) IBOutlet WebViewController *webViewController;

- (void)reconnectToServiceIfNeeded;
@end
