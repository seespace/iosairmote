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

@interface WebViewController ()

@end

@implementation WebViewController

@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)clearCookies
{
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies])
    {
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)viewDidLoad
{
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

- (void)load {
    [super load];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




- (void)processOAuthResponse:(NSString *)code withQueryString:(NSString *)query
{
    Event *ev = [ProtoHelper oauthResponseWithCode:code query:query target:_oauthEvent.replyTo];

    [[IAConnection sharedConnection] sendEvent:ev withTag:kOAuthTag];
    _oauthEvent = nil;
    [self clear];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [super webViewDidFinishLoad:webView];

}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL.host isEqualToString:@"oauth.inair.tv"])
    {
        [self.navigationController popViewControllerAnimated:YES];
        DDURLParser *parser = [[DDURLParser alloc] initWithURLString:request.URL.absoluteString];
        NSString *code = [parser valueForVariable:@"code"];
        NSString *verifier = [parser valueForVariable:@"oauth_verifier"];

        if (verifier != nil)
        {
            [self processOAuthResponse:verifier withQueryString:request.URL.query];
        } else
        {
            [self processOAuthResponse:code withQueryString:request.URL.query];
        }
    }

    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [super webView:webView didFailLoadWithError:error];
    NSLog(@"%@", error);
    _oauthEvent = nil;
}
@end
