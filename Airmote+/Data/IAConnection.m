 //
// Created by Manh Tuan Cao on 11/18/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "IAConnection.h"
#import "Proto.pb.h"

#define kServiceType @"_irpc._tcp."

@implementation IAConnection
{
  NSNetServiceBrowser *browser;
  BOOL foundAllServices;
  NSMutableArray *foundServices;
  NSTimer *timeOutTimer;
  EventCenter *eventCenter;
  NSNetService *currentService;
}

#pragma mark - Init

- (id)init
{
  self = [super init];
  if (self) {
    browser = [[NSNetServiceBrowser alloc] init];
    foundServices = [[NSMutableArray alloc] init];
    browser.delegate = self;
    foundAllServices = NO;
    eventCenter = [[EventCenter alloc] init];
    eventCenter.delegate = self;
  }
  return self;
}


+ (IAConnection *)sharedConnection
{
  static IAConnection *_connection = nil;

  @synchronized (self) {
    if (_connection == nil) {
      _connection = [[self alloc] init];
    }
  }

  return _connection;
}

#pragma mark - Getters

-(NSArray *)foundServices
{
  return foundServices;
}

#pragma mark - NetServiceBrowserDelegate


-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing
{
  NSLog(@"Domain: %@", domainString);
  
}


-(void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
  NSLog(@"");
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing
{
  NSLog(@"");
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didFindService:(NSNetService *)aService moreComing:(BOOL)more
{
  [timeOutTimer invalidate];
  [foundServices addObject:aService];
  foundAllServices = !more;
  if (foundAllServices)
  {
    if ([self.delegate respondsToSelector:@selector(didFoundServices:)]) {
      [self.delegate didFoundServices:foundServices];
    }
//    [browser stop];

    if (foundServices.count == 1) {
      if (! [self.delegate respondsToSelector:@selector(shouldConnectAutomatically)] || [self.delegate shouldConnectAutomatically]) {

        if (currentService) {
          currentService.delegate = nil;
          [currentService stop];
        }
        currentService = foundServices[0];
        currentService.delegate = self;
        [currentService resolveWithTimeout:30];

      } else {

      }

    }
  }

}



- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didRemoveService:(NSNetService *)aService moreComing:(BOOL)more
{
  [foundServices removeObject:aService];
  if (!more && [foundServices count] == 0) {
    //TODO handle error
//    if ([self.delegate respondsToSelector:@selector(bonjourManagerServiceNotFound)]) {
//      [self.delegate bonjourManagerServiceNotFound];
//    }

  }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
{
  [timeOutTimer invalidate];
  [self notifyError:IAConnectionErrorDidNotSearch userInfo:nil];
}

- (void)notifyError:(int)errorCode userInfo:(NSDictionary *)userInfo
{
  if ([self.delegate respondsToSelector:@selector(didFailToConnect:)]) {
    NSError *error = [NSError errorWithDomain:kIAConnectionErrorDomain code:IAConnectionErrorDidNotSearch userInfo:userInfo];
    [self.delegate didFailToConnect:error];
  }
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
  NSLog(@"Stop searching");
  [timeOutTimer invalidate];
  //TODO handle no services found
}

- (void)timerFired:(NSTimer *)timer
{
//  [browser stop];
  if ([self.delegate respondsToSelector:@selector(didFailToConnect:)]) {
    NSError *error = [NSError errorWithDomain:kIAConnectionErrorDomain code:IAConnectionErrorDiscoveryTimedOut userInfo:nil];
    [self.delegate didFailToConnect:error];
  }
}


- (BOOL)isConnected
{
  return [eventCenter isActive];
}

- (void)start
{
  if (timeOutTimer != nil) {
    [timeOutTimer invalidate];
    timeOutTimer = nil;
  }

  timeOutTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];

//  [browser stop];
  [foundServices removeAllObjects];

//  [browser searchForBrowsableDomains];
  [browser searchForServicesOfType:kServiceType inDomain:@"local."];
}


#pragma mark - NetServiceDelegate

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
  [self notifyError:IAConnectionErrorServiceNotResolved userInfo:nil];
  currentService = nil;
}


- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
  if (currentService != sender) {
    NSLog(@"ERROR: unexpected service resolved");

    [eventCenter connectToHost:currentService.hostName];

//    [self notifyError:IAConnectionError userInfo:<#(NSDictionary *)userInfo#>];
  }
}

- (void)eventCenterDidConnectToHost:(NSString *)hostName
{
  if ([hostName isEqualToString:currentService.hostName]) {
    if ([self.delegate respondsToSelector:@selector(didConnect:)]) {
      [self.delegate didConnect:currentService.hostName];
    }
  }
}

- (void)eventCenterDidDisconnectFromHost:(NSString *)hostName withError:(NSError *)error
{
  [self notifyError:IAConnectionErrorSocketLost userInfo:nil];

}

- (void)eventCenter:(EventCenter *)eventCenter1 receivedEvent:(Event *)event
{
  if ([self.delegate respondsToSelector:@selector(didReceiveEvent:)]) {
    [self.delegate didReceiveEvent:event];
  }
}

@end