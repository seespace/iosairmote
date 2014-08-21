//
//  WebViewController.m
//  Airmote+
//
//  Created by Long Nguyen on 12/24/13.
//  Copyright (c) 2013 Long Nguyen. All rights reserved.
//

#import "WebViewController.h"
#import "EventCenter.h"
#import "ProtoHelper.h"
#import "DDURLParser.h"

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
    [self clearCookies];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)load {
    [super load];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




- (void)processOAuthResponse:(NSString *)code
{
    Event *ev = [ProtoHelper oauthResponseWithCode:code target:_oauthEvent.replyTo];

    [_eventCenter sendEvent:ev withTag:kOAuthTag];
    _oauthEvent = nil;
    [self clear];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [super webViewDidFinishLoad:webView];

}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL.host isEqualToString:@"localhost"])
    {
        [self.navigationController popViewControllerAnimated:YES];
        DDURLParser *parser = [[DDURLParser alloc] initWithURLString:request.URL.absoluteString];
        NSString *code = [parser valueForVariable:@"code"];
        NSString *verifier = [parser valueForVariable:@"oauth_verifier"];

        if (verifier != nil)
        {
            [self processOAuthResponse:verifier];
        } else
        {
            [self processOAuthResponse:code];
        }

        return NO;
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
