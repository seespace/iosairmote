//
//  ViewController.m
//  Airmote+
//
//  Created by Long Nguyen on 11/6/13.
//  Copyright (c) 2013 Long Nguyen. All rights reserved.
//

#import <netinet/in.h>
#import <arpa/inet.h>

#import "ViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "ProtoHelper.h"
#import "DDURLParser.h"
#import "TrackPadView.h"


@interface ViewController ()
{
    BOOL _serverSelectorDisplayed;

    Event *_oauthEvent;
    EventCenter *_eventCenter;
}

@end

@implementation ViewController
{
    NSArray *_services;
    BonjourManager *_bonjourManager;
    BOOL isResolvingServiceAddress;
}


static const uint8_t kMotionShakeTag = 6;



static const uint8_t kOAuthTag = 12;

@synthesize trackpadView = _trackpadView;
@synthesize webViewController = _webViewController;

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

    _oauthEvent = nil;

    _bonjourManager = [[BonjourManager alloc] init];
    _bonjourManager.delegate = self;
    [_bonjourManager start];
    [SVProgressHUD showWithStatus:@"Scanning..." maskType:SVProgressHUDMaskTypeBlack];
    isResolvingServiceAddress = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:@"applicationDidBecomeActive" object:nil];

    // Webview
    _webViewController = [[WebViewController alloc] init];
    [self.navigationController setNavigationBarHidden:YES];

    _trackpadView.viewController = self;

}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES];
}

#pragma mark -
#pragma mark Auto reconnect when become active

- (void)applicationDidBecomeActive
{
    [self reconnectToServiceIfNeeded];
}

- (void)reconnectToServiceIfNeeded
{
    if (!isResolvingServiceAddress && !_eventCenter.isActive && !_serverSelectorDisplayed)
    {
        if ([_services count])
        {
            [self chooseServerWithMessage:@"Choose a device"];
        }
        else
        {
            [_bonjourManager start];
            [SVProgressHUD showWithStatus:@"Scanning..." maskType:SVProgressHUDMaskTypeBlack];
            isResolvingServiceAddress = YES;
        }
    }
}

#pragma mark -
#pragma mark Bonjour Bonjour ;)

- (void)bonjourManagerServiceNotFound
{
    [SVProgressHUD showErrorWithStatus:@"Service not found"];
    isResolvingServiceAddress = NO;
}

- (void)bonjourManagerFinishedDiscoveringServices:(NSArray *)services
{
    [SVProgressHUD dismiss];
    isResolvingServiceAddress = NO;
    _services = services;
    if (!_serverSelectorDisplayed)
    {
        [self chooseServerWithMessage:@"Choose a device"];
    }
}


#pragma mark - Show action sheets
- (void)chooseServerWithMessage:(NSString *)message
{
    if (_services.count > 1)
    {
        _actionSheet = [[UIActionSheet alloc] init];
        [_actionSheet setDelegate:self];

        [_actionSheet setTitle:message];

        for (NSNetService *service in _services)
        {
            NSString *title = service.name;
            [_actionSheet addButtonWithTitle:title];
        }

        [_actionSheet addButtonWithTitle:@"Cancel"];
        _actionSheet.cancelButtonIndex = _services.count;

        [_actionSheet showInView:self.view];
        _serverSelectorDisplayed = YES;
    } else if (_services.count == 1)
    {
        NSNetService *service = (NSNetService *) [_services objectAtIndex:0];
        [self connectToService:service];
    } else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AirServer"
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Connect", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *alertTextField = [alert textFieldAtIndex:0];
        alertTextField.placeholder = @"inair.local or 127.0.0.1";
        [alert show];
    }
}

- (void)connectToService:(NSNetService *)service
{
    if (service.addresses.count > 0)
    {
        NSString *address = [self getStringFromAddressData:[service.addresses objectAtIndex:0]];
        [self connectToHost:address];
    }
    else
    {
        service.delegate = self;
        [service resolveWithTimeout:10];
    }
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog(@"Service is denied");
}


- (void)netServiceDidResolveAddress:(NSNetService *)service
{
    NSString *address = [self getStringFromAddressData:[service.addresses objectAtIndex:0]];
    [self connectToHost:address];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"AirServer"])
    {
        if (buttonIndex != alertView.cancelButtonIndex)
        {
            UITextField *alertTextField = [alertView textFieldAtIndex:0];
            [self connectToHost:alertTextField.text];
        }
    } else if ([alertView.title isEqualToString:@"OAuth"])
    {
        if (buttonIndex != alertView.cancelButtonIndex)
        {
            [self processOAuthRequest];
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        NSNetService *service = (NSNetService *) _services[buttonIndex];
        [self connectToService:service];
    }
    else
    {
        _serverSelectorDisplayed = NO;
    }
}

#pragma mark - Privates

- (NSString *)getStringFromAddressData:(NSData *)dataIn
{
    struct sockaddr_in *socketAddress = nil;
    NSString *ipString = nil;

    socketAddress = (struct sockaddr_in *) [dataIn bytes];
    ipString = [NSString stringWithFormat:@"%s",
                                          inet_ntoa(socketAddress->sin_addr)];
    return ipString;
}

- (void)connectToHost:(NSString *)hostname
{

    _eventCenter.delegate = nil;

    _eventCenter = [[EventCenter alloc] init];
    _trackpadView.eventCenter = _eventCenter;
    _eventCenter.delegate = self;
    BOOL canStartConnection = [_eventCenter connectToHost:hostname];
    if (canStartConnection)
    {
        [SVProgressHUD showWithStatus:@"Connecting" maskType:SVProgressHUDMaskTypeBlack];
    }
}

#pragma mark - EventCenterDelegate

- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event
{
    NSLog(@"%@", event);

    // process events
    switch (event.type)
    {
        case EventTypeOauthRequest:
            [self processOAuthRequest:event];
            break;

        default:
            break;
    }
}

- (void)eventCenterDidConnect
{
    [SVProgressHUD showSuccessWithStatus:@"Connected"];
}

- (void)eventCenterDidDisconnectWithError:(NSError *)error
{
    [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
    NSLog(@"Error: %@. Code: %ld", [error localizedDescription], (long) [error code]);
}

#pragma mark -
#pragma mark Motion

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        Event *ev = [ProtoHelper motionEventWithTimestamp:event.timestamp * 1000
                                                     type:MotionEventTypeShake];
        [_eventCenter sendEvent:ev withTag:kMotionShakeTag];
    }
}


#pragma mark -
#pragma mark OAuth

- (void)processOAuthRequest:(Event *)event
{
    if (_oauthEvent == nil)
    {
        _oauthEvent = event;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"OAuth" message:@"InAir would like to open webview for OAuth authentication." delegate:self cancelButtonTitle:@"Don't Allow" otherButtonTitles:@"OK", nil];
        [alertView show];
    }
}

- (void)processOAuthRequest
{
    if (_oauthEvent == nil)
    {
        return;
    }

    OAuthRequestEvent *event = [_oauthEvent getExtension:[OAuthRequestEvent event]];
    _webViewController.URL = [NSURL URLWithString:event.authUrl];
    _webViewController.delegate = self;
    [_webViewController load];

    if (_webViewController.navigationController == nil)
    {
        [self.navigationController pushViewController:_webViewController animated:YES];
    }
}

- (void)processOAuthResponse:(NSString *)code
{
    Event *ev = [ProtoHelper oauthResponseWithCode:code target:_oauthEvent.replyTo];

    [_eventCenter sendEvent:ev withTag:kOAuthTag];
    _oauthEvent = nil;
    [_webViewController clear];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{

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
    NSLog(@"%@", error);
    _oauthEvent = nil;
}

#pragma mark -
#pragma mark Others

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
