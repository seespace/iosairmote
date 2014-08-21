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
}

static const uint8_t kTouchBeganTag = 2;
static const uint8_t kTouchMovedTag = 3;
static const uint8_t kTouchEndedTag = 4;
static const uint8_t kTouchCancelledTag = 5;

static const uint8_t kMotionShakeTag = 6;


static const uint8_t kGestureStateChanged = 11;

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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:@"applicationDidBecomeActive" object:nil];

    // Webview
    _webViewController = [[WebViewController alloc] init];
    [self.navigationController setNavigationBarHidden:YES];

    // Gesture

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandle:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.cancelsTouchesInView = NO;
    [_trackpadView addGestureRecognizer:tapGesture];

    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandle:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.cancelsTouchesInView = NO;
    [_trackpadView addGestureRecognizer:doubleTapGesture];

    [tapGesture requireGestureRecognizerToFail:doubleTapGesture];

    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressHandle:)];
    [_trackpadView addGestureRecognizer:longPressGesture];

    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandle:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeLeft.cancelsTouchesInView = NO;
    [_trackpadView addGestureRecognizer:swipeLeft];

    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandle:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRight.cancelsTouchesInView = NO;
    [_trackpadView addGestureRecognizer:swipeRight];

    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandle:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    swipeDown.cancelsTouchesInView = NO;
    [_trackpadView addGestureRecognizer:swipeDown];

    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandle:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUp.cancelsTouchesInView = NO;
    [_trackpadView addGestureRecognizer:swipeUp];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandle:)];
    pan.maximumNumberOfTouches = 1;
    pan.cancelsTouchesInView = NO;
    [_trackpadView addGestureRecognizer:pan];

    [pan requireGestureRecognizerToFail:longPressGesture];

    pan.delegate = tapGesture.delegate = doubleTapGesture.delegate = swipeDown.delegate = swipeUp.delegate = swipeUp.delegate = swipeDown.delegate = pan.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES];
}

#pragma mark -
#pragma mark Auto reconnect when become active

- (void)applicationDidBecomeActive
{
    if (!_eventCenter.isActive && !_serverSelectorDisplayed)
    {
        [self chooseServerWithMessage:@"Choose a device"];
    }
}

#pragma mark -
#pragma mark Bonjour Bonjour ;)


- (void)bonjourManagerDidResolveHostNames:(NSArray *)hosts
{
    if (!_serverSelectorDisplayed)
    {
        [self chooseServerWithMessage:@"Choose a device"];
    }
}

- (void)bonjourManagerDidFoundServices:(NSArray *)services
{
    _services = services;
    if (!_serverSelectorDisplayed)
    {
        [self chooseServerWithMessage:@"Choose a device"];
    }

}

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
        if (service.addresses.count > 0)
        {
            NSString *address = [self getStringFromAddressData:[service.addresses objectAtIndex:0]];
            [self connectToHost:address];
        }
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
        NSNetService *service = (NSNetService *) [_services objectAtIndex:buttonIndex];
        if (service.addresses.count > 0)
        {
            NSString *address = [self getStringFromAddressData:[service.addresses objectAtIndex:0]];
            [self connectToHost:address];
        }
    }
}

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
    _eventCenter.delegate = self;
    BOOL canStartConnection = [_eventCenter connectToHost:hostname];
    if (canStartConnection)
    {
        [SVProgressHUD showWithStatus:@"Connecting" maskType:SVProgressHUDMaskTypeBlack];
    }
}


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
#pragma mark Touches


- (void)sendTouch:(UITouch *)touch withEvent:(UIEvent *)event tag:(uint8_t)tag
{
    CGPoint location = [touch locationInView:self.view];
    Event *ev = [ProtoHelper touchEventWithTimestamp:event.timestamp * 1000
                                           locationX:location.x
                                           locationY:location.y
                                      trackareaWidth:self.view.frame.size.width
                                     trackareaHeight:self.view.frame.size.height
                                               phase:[ProtoHelper phaseFromUITouchPhase:touch.phase]];

    [_eventCenter sendEvent:ev withTag:tag];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![_eventCenter isActive])
    {
        [self applicationDidBecomeActive];
        return;
    }

    [self sendTouch:[touches anyObject] withEvent:event tag:kTouchBeganTag];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self sendTouch:[touches anyObject] withEvent:event tag:kTouchMovedTag];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self sendTouch:[touches anyObject] withEvent:event tag:kTouchEndedTag];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self sendTouch:[touches anyObject] withEvent:event tag:kTouchCancelledTag];
}


#pragma mark -
#pragma mark - Gesture Handlers

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)tapHandle:(UITapGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:sender.view];
    Event *ev = [ProtoHelper tapGestureWithTimestamp:[ProtoHelper now]
                                           locationX:location.x
                                           locationY:location.y
                                      trackareaWidth:sender.view.frame.size.width
                                     trackareaHeight:sender.view.frame.size.height
                                               state:[ProtoHelper stateFromUIGestureRecognizerState:sender.state]
                                               count:(int) sender.numberOfTapsRequired];

    [_eventCenter sendEvent:ev withTag:kGestureStateChanged];
}

- (void)panHandle:(UIPanGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:sender.view];
    CGPoint translation = [sender translationInView:sender.view];
    CGPoint velocity = [sender velocityInView:sender.view];
    Event *ev = [ProtoHelper panGestureWithTimestamp:[ProtoHelper now]
                                           locationX:location.x
                                           locationY:location.y
                                      trackareaWidth:sender.view.frame.size.width
                                     trackareaHeight:sender.view.frame.size.height
                                               state:[ProtoHelper stateFromUIGestureRecognizerState:sender.state]
                                        translationX:translation.x
                                        translationY:translation.y
                                           velocityX:velocity.x
                                           velocityY:velocity.y];

    [_eventCenter sendEvent:ev withTag:kGestureStateChanged];
}

- (void)swipeHandle:(UISwipeGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:sender.view];
    Event *ev = [ProtoHelper swipeGestureWithTimestamp:[ProtoHelper now]
                                             locationX:location.x
                                             locationY:location.y
                                        trackareaWidth:sender.view.frame.size.width
                                       trackareaHeight:sender.view.frame.size.height
                                                 state:[ProtoHelper stateFromUIGestureRecognizerState:sender.state]
                                             direction:[ProtoHelper directionFromUISwipeGestureRecognizerDirection:sender.direction]];

    [_eventCenter sendEvent:ev withTag:kGestureStateChanged];
}

- (void)longPressHandle:(UILongPressGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:sender.view];
    Event *ev = [ProtoHelper longpressGestureWithTimestamp:[ProtoHelper now]
                                                 locationX:location.x
                                                 locationY:location.y
                                            trackareaWidth:sender.view.frame.size.width
                                           trackareaHeight:sender.view.frame.size.height
                                                     state:[ProtoHelper stateFromUIGestureRecognizerState:sender.state]
                                                  duration:0];

    [_eventCenter sendEvent:ev withTag:kGestureStateChanged];
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
