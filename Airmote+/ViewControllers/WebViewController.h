//
//  WebViewController.h
//  Airmote+
//
//  Created by Long Nguyen on 12/24/13.
//  Copyright (c) 2013 Long Nguyen. All rights reserved.
//

#import "JBWebViewController.h"
#import "IAConnection.h"

@class OAuthRequestEvent;
@class Event;

@interface WebViewController : JBWebViewController <IAConnectionDelegate>

@property(nonatomic, strong) Event *oauthEvent;
@property(nonatomic, strong) Event *webViewEvent;
@end
