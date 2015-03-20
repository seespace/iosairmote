//
//  WebViewController.m
//  Airmote+
//
//  Created by Long Nguyen on 12/24/13.
//  Copyright (c) 2013 Long Nguyen. All rights reserved.
//

#import "WebViewController.h"
#import "ProtoHelper.h"
#import "DDURLParser.h"
#import "IAConnection.h"

static const uint8_t kOAuthTag = 12;
static const uint8_t kWebViewTag = 13;

@interface WebViewController () {
  BOOL _success;
  UIWebView *_webView;
}

@end

@implementation WebViewController

- (id)initWithUrl:(NSURL *)url {
  if (self = [super initWithUrl:url]) {
    _success = NO;
  }
  return self;
}

- (void)clearCookies {
  NSHTTPCookie *cookie;
  NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  for (cookie in [storage cookies]) {
    [storage deleteCookie:cookie];
  }
  [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)viewDidLoad {
  [super viewDidLoad];
  [self clearCookies];
  // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:NO];

  [IAConnection sharedConnection].delegate = self;
}


- (void)viewWillDisappear:(BOOL)animated {
  [self.navigationController setNavigationBarHidden:YES];
  [self.navigationController setToolbarHidden:YES];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


#pragma mark IAConnection

- (void)didReceiveEvent:(Event *)ev {
  switch (ev.type) {
    case EventTypeWebviewRequest:
      // navigate to new URL, maybe
      break;
    case EventTypeWebviewResponse: {
      _webViewEvent = ev;
      WebViewResponseEvent *event = [ev getExtension:[WebViewResponseEvent event]];
      [self triggerJavascript:@"newMessage" withData:event.data];
      break;
    };
    default:
      break;
  }
}

- (void)processOAuthResponse:(NSString *)code withQueryString:(NSString *)query {
  Event *ev = [ProtoHelper oauthResponseWithCode:code query:query target:_oauthEvent.replyTo];

  [[IAConnection sharedConnection] sendEvent:ev withTag:kOAuthTag];
  _oauthEvent = nil;
}

- (void)processWebViewResponse:(NSString *)data {
  Event *ev = [ProtoHelper webviewResponseWithData:data target:_webViewEvent.replyTo];
  DDLogDebug(@"%@", data);
  [[IAConnection sharedConnection] sendEvent:ev withTag:kWebViewTag];
}

#pragma mark JS

- (void)injectJavascript:(NSString *)resource {
  NSString *jsPath = [[NSBundle mainBundle] pathForResource:resource ofType:@"js"];
  NSString *js = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:NULL];

  [_webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)triggerJavascript:(NSString *)event withData:(NSString *)data {
  [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"InAir.emit('%@', '%@');", event, data]];
}

#pragma mark WebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
  [super webViewDidStartLoad:webView];
//  [self injectJavascript:@"inair"];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  [super webViewDidFinishLoad:webView];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  [super webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];

  if ([request.URL.host isEqualToString:@"oauth.inair.tv"]) {
    DDURLParser *parser = [[DDURLParser alloc] initWithURLString:request.URL.absoluteString];
    NSString *code = [parser valueForVariable:@"code"];
    NSString *verifier = [parser valueForVariable:@"oauth_verifier"];

    if (verifier != nil) {
      [self processOAuthResponse:verifier withQueryString:request.URL.query];
    } else {
      [self processOAuthResponse:code withQueryString:request.URL.query];
    }

    // dismiss
    _success = YES;
    [self dismiss];
  } else {
    // these need to match the values defined in your JavaScript
    NSString *appScheme = @"inair";

    // ignore legit webview requests so they load normally
    if ([request.URL.scheme isEqualToString:appScheme]) {
      // get the action from the path
      NSString *action = request.URL.host;
      // deserialize the request JSON
      NSString *jsonDictString = [request.URL.fragment stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];

      if (jsonDictString.length > 0) {
        [self processWebViewResponse:jsonDictString];
      }

      // look at the actionType and do whatever you want here
      if ([action isEqualToString:@"close"]) {
        [self dismiss];
      }

      // make sure to return NO so that your webview doesn't try to load your made-up URL
      return NO;
    }
  }

  _webView = webView;

  return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  [super webView:webView didFailLoadWithError:error];
  NSLog(@"%@", error);
  _oauthEvent = nil;
}

#pragma mark Dismiss

- (void)dismiss {
  [self dismissViewControllerAnimated:YES completion:^{
    if (!_success) {
      Event *ev = [ProtoHelper oauthResponseWithCode:@"" query:@"" target:_oauthEvent.replyTo];
      [[IAConnection sharedConnection] sendEvent:ev withTag:kOAuthTag];
    }
    _oauthEvent = nil;
  }];
}

@end
