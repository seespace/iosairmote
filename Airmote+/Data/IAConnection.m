//
// Created by Manh Tuan Cao on 11/18/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "IAConnection.h"
#import "Proto.pb.h"
#import "Reachability.h"

#define kServiceType @"_irpc._tcp."
#define kMaxScanningDuration 5.0
#define kMaxResolvingDuration 5.0

@implementation IAConnection
{
  NSNetServiceBrowser *browser;
  BOOL foundAllServices;
  NSMutableArray *foundServices;
  NSTimer *timeOutTimer;
  EventCenter *eventCenter;
  NSNetService *currentService;
  BOOL isConnecting;
  BOOL isResolving;
  BOOL isScanning;
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterBackground:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
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

- (NSArray *)foundServices
{
  return foundServices;
}

#pragma mark - NetServiceBrowserDelegate

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
  isScanning = YES;
  DDLogDebug(@"Start Scanning");
  if ([self.delegate respondsToSelector:@selector(didStartScanning)]) {
    [self.delegate didStartScanning];
  }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didFindService:(NSNetService *)aService moreComing:(BOOL)more
{
  DDLogDebug(@"Found services: %@", aService.name );
  [timeOutTimer invalidate];
  [foundServices addObject:aService];
  foundAllServices = !more;
  if (foundAllServices) {
    DDLogDebug(@"Found %d services", [foundServices count] );
    isScanning = NO;
    if (foundServices.count > 1) {
      if ([self.delegate respondsToSelector:@selector(didFoundServices:)]) {
        [self.delegate didFoundServices:foundServices];
      }
    } else if (foundServices.count == 1) {
        [self connectToService:foundServices[0]];
    }

    [browser stop];
  }
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didRemoveService:(NSNetService *)aService moreComing:(BOOL)more
{
  DDLogDebug(@"Removing service: %@", aService.name);
  [foundServices removeObject:aService];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
{
  DDLogDebug(@"NetServiceBrowser didNotSearch: %@", errorDict);
  isScanning = NO;
  [timeOutTimer invalidate];
  [self notifyError:IAConnectionErrorDidNotSearch userInfo:nil];
}


- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
  DDLogDebug(@"netServiceBrowserDidStopSearch");
  isScanning = NO;
  [timeOutTimer invalidate];
  if ([foundServices count] == 0) {
    [self notifyError:IAConnectionErrorServicesNotFound userInfo:nil];
  }

}


#pragma mark - App lifecycle

- (void)appWillEnterBackground:(NSNotification *)notification
{
  if ([eventCenter isActive]) {
    [eventCenter disconnect];
  }
}

- (void)appDidBecomeActive:(NSNotification *)notification
{
  DDLogDebug(@"App Enter foreground");
  if (!self.isConnected && !self.isProcessing) {
    DDLogDebug(@"Should start IAConnection");
    if ([self.delegate respondsToSelector:@selector(shouldConnectAutomatically)] && [self.delegate shouldConnectAutomatically]) {
      [self start];
    }

  }
}


#pragma mark - Private methods
- (void)startScanningServices
{

  if ([Reachability reachabilityForLocalWiFi].isReachableViaWiFi) {
    DDLogDebug(@"Start scanning for services");
    isScanning = YES;
    [browser searchForServicesOfType:kServiceType inDomain:@"local."];
  } else {
    DDLogDebug(@"Failed to scan because no wifi available");
    [self notifyError:IAConnectionErrorWifiNotAvailable userInfo:nil];
  }
}

- (void)notifyError:(int)errorCode userInfo:(NSDictionary *)userInfo
{
  if ([self.delegate respondsToSelector:@selector(didFailToConnect:)]) {
    NSError *error = [NSError errorWithDomain:kIAConnectionErrorDomain code:errorCode userInfo:userInfo];
    [self.delegate didFailToConnect:error];
  }
}


- (void)timerFired:(NSTimer *)timer
{
  [browser stop];
  if ([self.delegate respondsToSelector:@selector(didFailToConnect:)]) {
    NSError *error = [NSError errorWithDomain:kIAConnectionErrorDomain code:IAConnectionErrorDiscoveryTimedOut userInfo:nil];
    [self.delegate didFailToConnect:error];
  }
}


#pragma mark - Public methods

- (void)connectToService:(NSNetService *)service
{

  if (isConnecting) {
    DDLogError(@"Ignoring Connecting to service: %@", service.name);
    return;
  }

  DDLogDebug(@"Connecting to service: %@", service.name);

  if ([service.name isEqualToString:currentService.name]) {
    isConnecting = YES;
    [eventCenter connectToHost:currentService.hostName];

  } else {
    isResolving = YES;
    if (currentService) {
      currentService.delegate = nil;
      [currentService stop];
    }
    currentService = service;
    currentService.delegate = self;
    [currentService resolveWithTimeout:kMaxResolvingDuration];

  }

  if ([self.delegate respondsToSelector:@selector(didStartConnecting)]) {
    [self.delegate didStartConnecting];
  }
}


- (BOOL)isProcessing
{
  DDLogDebug(@"Connect: %@ - Scanning: %@ - Resolving: %@",
      isConnecting? @"YES" : @"NO",
      isScanning? @"YES" : @"NO",
      isResolving? @"YES" : @"NO");
  return isConnecting || isScanning || isResolving;
}

- (BOOL)isConnected
{
  return [eventCenter isActive];
}

- (void)start
{
  DDLogDebug(@"Starting IAConnection");
  if (foundServices.count > 0) {
    [self reconnect];
    return;
  }

  browser.delegate = nil;
  [browser stop];
  browser.delegate = self;

  currentService.delegate = nil;
  [currentService stop];

  [self resetStates];

  [self startScanningServices];
}


- (void)stop
{
  DDLogDebug(@"STOP connection");
  if (timeOutTimer != nil) {
    [timeOutTimer invalidate];
    timeOutTimer = nil;
  }

  [eventCenter disconnect];
  [currentService stop];
  [browser stop];
}

- (void)resetStates
{
  DDLogDebug(@"Resetting states");
  timeOutTimer = [NSTimer scheduledTimerWithTimeInterval:kMaxScanningDuration target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
  [foundServices removeAllObjects];
  foundAllServices = NO;
  currentService = nil;

}


- (void)sendEvent:(Event *)event withTag:(u_int8_t)tag
{
  DDLogDebug(@"Sending Event: ", event.description);
  if (eventCenter.isActive) {
    [eventCenter sendEvent:event withTag:tag];
//    lastActiveTime = [NSDate date];
  } else {
    DDLogError(@"Cannot send event, event center is not connected");
    [self notifyError:IAConnectionErrorFailToSendEvent userInfo:nil];
  }

}


- (void)connectToServiceAtIndex:(NSUInteger)index
{
  if (index < foundServices.count) {
    [self connectToService:foundServices[index]];
  }
}

- (void)reconnect
{

  if ([self isConnected] || [self isProcessing]) {

    //TODO do we need to notify?
    DDLogError(@"Attempting reconnect while is connected or isConnecting...");
    return;
  }

  DDLogDebug(@"Reconnecting.....");
  if (currentService != nil) {
    if (currentService.hostName != nil) {
      isConnecting = YES;
      [eventCenter connectToHost:currentService.hostName];
      if ([self.delegate respondsToSelector:@selector(didStartConnecting)]) {
        [self.delegate didStartConnecting];
      }
    } else {
      [self connectToService:currentService];
    }
  }
  else {
    BOOL shouldClearServices = YES;
    if (foundServices != nil && foundServices.count > 0) {
      if (foundServices.count == 1) {
        [self connectToServiceAtIndex:0];
        shouldClearServices = NO;
      } else if (foundServices.count > 1) {
        if ([self.delegate respondsToSelector:@selector(didFoundServices:)]) {
          [self.delegate didFoundServices:foundServices];
          shouldClearServices = NO;
        }
      }
    }

    if (shouldClearServices) {
      [foundServices removeAllObjects];
    }

//    if (shouldClearServices) {
//      [self start];
//    }
  }
}


#pragma mark - NetServiceDelegate

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
  DDLogError(@"Service: %@ DID Not resolve", sender.name);
  isResolving = NO;
  [self notifyError:IAConnectionErrorServiceNotResolved userInfo:errorDict];
  [self invalidateCurrentService];
}

- (void)invalidateCurrentService
{
  DDLogDebug(@"Invalidate current service");
  if (currentService) {
    [foundServices removeObject:currentService];
  }

  currentService = nil;
}


- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
  DDLogDebug(@"Did resolve service: %@ - IP Address: %@", sender.name, sender.addresses);
  isResolving = NO;
  if (currentService == sender) {
    isConnecting = YES;
    [eventCenter connectToHost:currentService.hostName];
    if ([self.delegate respondsToSelector:@selector(didStartConnecting)]) {
      [self.delegate didStartConnecting];
    }
  } else {
    DDLogError(@"ERROR: Trying to connect to another host while connecting to %@", currentService.hostName);
  }
}

- (void)eventCenterDidConnectToHost:(NSString *)hostName
{
  DDLogDebug(@"Did connect to host name", hostName);
  isConnecting = NO;
  if ([hostName isEqualToString:currentService.hostName]) {
    if ([self.delegate respondsToSelector:@selector(didConnect:)]) {
      [self.delegate didConnect:currentService.name];
    }
  }
}

- (void)eventCenterDidDisconnectFromHost:(NSString *)hostName withError:(NSError *)error
{
  DDLogError(@"Event did disconnect from host: %@ - Error %@", hostName, error);
  isConnecting = NO;
  [self notifyError:IAConnectionErrorSocketLost userInfo:nil];
//  currentService = nil;
}

- (void)eventCenter:(EventCenter *)eventCenter1 receivedEvent:(Event *)event
{
  DDLogDebug(@"Event center did received: %@", event);
  if ([self.delegate respondsToSelector:@selector(didReceiveEvent:)]) {
    [self.delegate didReceiveEvent:event];
  }
}

- (void)eventCenterFailedToConnectToHost:(NSString *)hostName withError:(NSError *)error
{
  DDLogDebug(@"Failed to connect to host: %@ - error: %@", hostName, error );
  isConnecting = NO;
  [self notifyError:IAConnectionErrorFailToConnectSocket userInfo:[error userInfo]];
  [self invalidateCurrentService];
}

@end