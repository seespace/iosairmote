//
//  WebViewController.h
//  Airmote+
//
//  Created by Long Nguyen on 12/24/13.
//  Copyright (c) 2013 Long Nguyen. All rights reserved.
//

#import "PBWebViewController.h"

@class EventCenter;
@class OAuthRequestEvent;
@class Event;

@interface WebViewController : PBWebViewController

@property (strong, nonatomic) id<UIWebViewDelegate> delegate;

@property(nonatomic, weak) EventCenter *eventCenter;
@property(nonatomic, strong) Event *oauthEvent;
@end
