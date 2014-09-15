//
// Created by Manh Tuan Cao on 8/20/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "BonjourManager.h"

#define kServiceType @"_irpc._tcp."
//#define kHostIP @"192.168.1.186"
//#define kHostIP @"127.0.0.1"



@interface BonjourManager () <NSNetServiceBrowserDelegate>
@end

@implementation BonjourManager {
  NSNetServiceBrowser *_browser;
  BOOL foundAllService;
  NSMutableArray *_services;
  NSMutableArray *_discoveredServices;
}

- (id)init {
  self = [super init];
  if (self) {
    _browser = [[NSNetServiceBrowser alloc] init];
    _browser.delegate = self;
    _services = [[NSMutableArray alloc] init];
    _discoveredServices = [[NSMutableArray alloc] init];
    foundAllService = NO;
  }
  return self;
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing
{
  NSLog(@"didFindDomain");
}

-(void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
  NSLog(@"netServiceBrowserWillSearch");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didFindService:(NSNetService *)aService moreComing:(BOOL)more {
  [_discoveredServices addObject:aService];
  foundAllService = !more;
  if (foundAllService && [self.delegate respondsToSelector:@selector(bonjourManagerFinishedDiscoveringServices:)]) {
    [self.delegate bonjourManagerFinishedDiscoveringServices:_discoveredServices];
    [_browser stop];
  }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didRemoveService:(NSNetService *)aService moreComing:(BOOL)more {
  [_discoveredServices removeObject:aService];
  if (!more && [_discoveredServices count] == 0) {
    if ([self.delegate respondsToSelector:@selector(bonjourManagerServiceNotFound)]) {
      [self.delegate bonjourManagerServiceNotFound];
    }

  }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict {
  if ([self.delegate respondsToSelector:@selector(bonjourManagerServiceNotFound)]) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [self.delegate bonjourManagerServiceNotFound];
    });

  }
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser {
  NSLog(@"Stop searching");
}


- (void)start {
  [_browser stop];
  [_discoveredServices removeAllObjects];
  [_services removeAllObjects];
  [_browser searchForServicesOfType:kServiceType inDomain:@""];
}

@end
