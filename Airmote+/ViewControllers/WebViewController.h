//
//  WebViewController.h
//  Airmote+
//
//  Created by Long Nguyen on 12/24/13.
//  Copyright (c) 2013 Long Nguyen. All rights reserved.
//

#import "JBWebViewController.h"

@class OAuthRequestEvent;
@class Event;

@interface WebViewController : JBWebViewController

@property(nonatomic, strong) Event *oauthEvent;
@end
