//
// Created by Manh Tuan Cao on 8/20/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "BonjourManager.h"

#define kServiceType @"_irpc._tcp."
//#define kHostIP @"192.168.1.186"
//#define kHostIP @"127.0.0.1"



@interface BonjourManager () <NSNetServiceBrowserDelegate>
@property(nonatomic, strong) NSMutableArray *services;
@property(nonatomic, strong) NSMutableArray *hosts;
@end

@implementation BonjourManager
{
    NSNetServiceBrowser *_browser;

}

- (id)init
{
    self = [super init];
    if (self)
    {
        _browser = [[NSNetServiceBrowser alloc] init];
        _browser.delegate = self;
        _services = [[NSMutableArray alloc] init];
        _hosts = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didFindService:(NSNetService *)aService moreComing:(BOOL)more
{
    [_services addObject:aService];

    NSNetService *remoteService = aService;
    remoteService.delegate = self;
    [remoteService resolveWithTimeout:10];

    if (!more && self.delegate && [self.delegate respondsToSelector:@selector(bonjourManagerDidFoundServices:)])
    {
        [self.delegate bonjourManagerDidFoundServices:_services];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didRemoveService:(NSNetService *)aService moreComing:(BOOL)more
{
    [_services removeObject:aService];
}

- (void)netServiceDidResolveAddress:(NSNetService *)aService
{
    NSLog(@"Found %@", [aService hostName]);
    if (![aService.hostName isEqualToString:@""])
    {
        [_hosts addObject:aService.hostName];
    }
    if (_hosts.count == _services.count && self.delegate && [self.delegate respondsToSelector:@selector(bonjourManagerDidResolveHostNames:)])
    {
        [self.delegate bonjourManagerDidResolveHostNames:_hosts];
    }

}

- (void)start
{
    [_browser searchForServicesOfType:kServiceType inDomain:@""];
}

@end