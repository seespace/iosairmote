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
#import "TrackPadView.h"
#import "NSData+NetService.h"


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

@synthesize trackpadView = _trackpadView;
@synthesize webViewController = _webViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];

    _bonjourManager = [[BonjourManager alloc] init];
    _bonjourManager.delegate = self;
    [_bonjourManager start];
    [SVProgressHUD showWithStatus:@"Scanning..." maskType:SVProgressHUDMaskTypeBlack];
    isResolvingServiceAddress = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:@"applicationDidBecomeActive" object:nil];

    // Webview
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

#pragma mark - BonjourManagerDelegate


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


#pragma mark - Action sheets
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
        NSString *address = [[service.addresses objectAtIndex:0] socketAddress];
        [self connectToHost:address];
    }
    else
    {
        service.delegate = self;
        [service resolveWithTimeout:10];
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

#pragma mark - AlertViewDelegate

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

#pragma mark - NetServiceDelegate

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog(@"Service is denied");
}


- (void)netServiceDidResolveAddress:(NSNetService *)service
{
    NSString *address = [[service.addresses objectAtIndex:0] socketAddress];
    [self connectToHost:address];
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

    if (self.navigationController.topViewController != self.webViewController)
    {
        OAuthRequestEvent *event = [_oauthEvent getExtension:[OAuthRequestEvent event]];
        self.webViewController.URL = [NSURL URLWithString:event.authUrl];
        self.webViewController.delegate = self;
        self.webViewController.eventCenter = _eventCenter;
        self.webViewController.oauthEvent = _oauthEvent;
        [self.webViewController load];

        [self.navigationController pushViewController:self.webViewController animated:YES];
    }
}


#pragma mark -
#pragma mark Others

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Privates


- (void)connectToHost:(NSString *)hostname
{
    
    _eventCenter.delegate = nil;
    
    _eventCenter = [EventCenter defaultCenter];
    _trackpadView.eventCenter = _eventCenter;
    _eventCenter.delegate = self;
    BOOL canStartConnection = [_eventCenter connectToHost:hostname];
    if (canStartConnection)
    {
        [SVProgressHUD showWithStatus:@"Connecting" maskType:SVProgressHUDMaskTypeBlack];
    }
}


- (WebViewController *)webViewController
{
    if (_webViewController == nil)
    {
        _webViewController = [[WebViewController alloc] init];
    }
    
    return _webViewController;
}

@end
