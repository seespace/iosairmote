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

@interface WebViewController () {
  BOOL _success;
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
//    [self clearCookies];
  // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:NO];
}


- (void)viewWillDisappear:(BOOL)animated {
  [self.navigationController setNavigationBarHidden:YES];
  [self.navigationController setToolbarHidden:YES];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


- (void)processOAuthResponse:(NSString *)code withQueryString:(NSString *)query {
  Event *ev = [ProtoHelper oauthResponseWithCode:code query:query target:_oauthEvent.replyTo];

  [[IAConnection sharedConnection] sendEvent:ev withTag:kOAuthTag];
  _oauthEvent = nil;
}

#pragma mark WebViewDelegate

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
  }

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
