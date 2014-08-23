//
// Created by Manh Tuan Cao on 8/20/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "BonjourManager.h"

#define kServiceType @"_irpc._tcp."
//#define kHostIP @"192.168.1.186"
//#define kHostIP @"127.0.0.1"



@interface BonjourManager () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
@end

@implementation BonjourManager {
  NSNetServiceBrowser *_browser;
  int runningNetServiceCallsCount;
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
    runningNetServiceCallsCount = 0;
    foundAllService = NO;
  }
  return self;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didFindService:(NSNetService *)aService moreComing:(BOOL)more {
  NSNetService *remoteService = aService;
  remoteService.delegate = self;
  [remoteService resolveWithTimeout:10];
  [_discoveredServices addObject:remoteService];
  runningNetServiceCallsCount++;
  foundAllService = !more;
  if (foundAllService && [self.delegate respondsToSelector:@selector(bonjourManagerFinishedDiscoveringServices:)]) {
    [self.delegate bonjourManagerFinishedDiscoveringServices:_discoveredServices];
  }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didRemoveService:(NSNetService *)aService moreComing:(BOOL)more {
  [_discoveredServices removeAllObjects];
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


#pragma mark - NetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)aService {
  runningNetServiceCallsCount--;
  [_services addObject:aService];
  [self callFinishDelegateIfDone];
}

- (void)callFinishDelegateIfDone {
  if (foundAllService && runningNetServiceCallsCount == 0 && [self.delegate respondsToSelector:@selector(bonjourManagerDidFoundAndResolveServices:)]) {
    [self.delegate bonjourManagerDidFoundAndResolveServices:_services];
  }
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
  runningNetServiceCallsCount--;
  [self callFinishDelegateIfDone];
}

- (void)start {
  [_browser stop];
  [_discoveredServices removeAllObjects];
  [_services removeAllObjects];
  [_browser searchForServicesOfType:kServiceType inDomain:@""];
}

@end
