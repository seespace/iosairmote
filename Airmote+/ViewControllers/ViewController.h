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

@interface ViewController : UIViewController <GCDAsyncSocketDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate, UIWebViewDelegate, BonjourManagerDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSString *hostName;
@property (nonatomic, strong) NSString *hostIP;
@property (nonatomic) NSInteger hostPort;

@property (nonatomic, strong) UIActionSheet *actionSheet;


@property (strong, nonatomic) IBOutlet UIView *trackpadView;
@property (strong, nonatomic) IBOutlet WebViewController *webViewController;

@end
