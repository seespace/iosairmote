//
// Created by Manh Tuan Cao on 11/18/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "IAConnection.h"
#import "Proto.pb.h"
#import "Reachability.h"

#define kServiceType @"_irpc._tcp."

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
  if ([self.delegate respondsToSelector:@selector(didStartScanning)]) {
    [self.delegate didStartScanning];
  }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didFindService:(NSNetService *)aService moreComing:(BOOL)more
{
  [timeOutTimer invalidate];
  [foundServices addObject:aService];
  foundAllServices = !more;
  if (foundAllServices) {
    
    if (foundServices.count > 1) {
      if  ([self.delegate respondsToSelector:@selector(didFoundServices:)]) {
        [self.delegate didFoundServices:foundServices];
      }
    } else if (foundServices.count == 1) {
      if (![self.delegate respondsToSelector:@selector(shouldConnectAutomatically)] || [self.delegate shouldConnectAutomatically]) {
        [self connectToService:foundServices[0]];
      }
    }
    
    [browser stop];
    isScanning = NO;
  }
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didRemoveService:(NSNetService *)aService moreComing:(BOOL)more
{
  [foundServices removeObject:aService];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
{
  [timeOutTimer invalidate];
  [self notifyError:IAConnectionErrorDidNotSearch userInfo:nil];
  isScanning = NO;
}


- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
  [timeOutTimer invalidate];
  if ([foundServices count] == 0) {
    [self notifyError:IAConnectionErrorServicesNotFound userInfo:nil];
  }
  isScanning = NO;
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
  if (! self.isConnected && ! self.isProcessing) {
    [self start];
  }
}


#pragma mark - Private methods
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
    return;
  }
  
  if ([service.name isEqualToString:currentService.name]) {
    [eventCenter connectToHost:currentService.hostName];
    isConnecting = YES;
  } else {
    if (currentService) {
      currentService.delegate = nil;
      [currentService stop];
    }
    currentService = service;
    currentService.delegate = self;
    [currentService resolveWithTimeout:30];
    isResolving = YES;
  }

  if ([self.delegate respondsToSelector:@selector(didStartConnecting)]) {
    [self.delegate didStartConnecting];
  }
}



- (BOOL)isProcessing
{
  return isConnecting || isScanning || isResolving;
}

- (BOOL)isConnected
{
  return [eventCenter isActive];
}

- (void)start
{
  if (foundServices.count > 0) {
    [self reconnect];
  }

  if (timeOutTimer != nil) {
    [timeOutTimer invalidate];
    timeOutTimer = nil;
  }

  timeOutTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];

  browser.delegate = nil;
  [browser stop];

  browser.delegate = self;
  [foundServices removeAllObjects];
  foundAllServices = NO;

  currentService.delegate = nil;
  [currentService stop];
//  currentService = nil;

  if ([Reachability reachabilityForLocalWiFi].isReachableViaWiFi) {
    [browser searchForServicesOfType:kServiceType inDomain:@"local."];
    isScanning = YES;

  } else {
    [self notifyError:IAConnectionErrorWifiNotAvailable userInfo:nil];
  }
}

- (void)sendEvent:(Event *)event withTag:(u_int8_t)tag
{
  if (eventCenter.isActive) {
    [eventCenter sendEvent:event withTag:tag];
//    lastActiveTime = [NSDate date];
  } else {
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
  if ([self isConnected] || [self isProcessing])  {
    //TODO do we need to notify?
    return;
  }

  if (currentService != nil) {
    if (currentService.hostName != nil) {
      [eventCenter connectToHost:currentService.hostName];
      isConnecting = YES;
      if ([self.delegate respondsToSelector:@selector(didStartConnecting)]) {
        [self.delegate didStartConnecting];
      }
    } else {
      [self connectToService:currentService];
    }
  }
  else {
    BOOL shouldStartConnect = YES;
    if (foundServices != nil && foundServices.count > 0) {
      if (foundServices.count == 1) {
        [self connectToServiceAtIndex:0];
        shouldStartConnect = NO;
      } else if (foundServices.count > 1) {
        if ([self.delegate respondsToSelector:@selector(didFoundServices:)]) {
          [self.delegate didFoundServices:foundServices];
          shouldStartConnect = NO;
        }
      }
    }

    if (shouldStartConnect) {
      [self start];
    }
  }
}


#pragma mark - NetServiceDelegate

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
  [self notifyError:IAConnectionErrorServiceNotResolved userInfo:errorDict];
  [self invalidateCurrentService];

  isResolving = NO;
}

- (void)invalidateCurrentService
{
  if (currentService) {
    [foundServices removeObject:currentService];
  }

  currentService = nil;
}


- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
  if (currentService == sender) {
    [eventCenter connectToHost:currentService.hostName];
    isConnecting = YES;
    if ([self.delegate respondsToSelector:@selector(didStartConnecting)]) {
      [self.delegate didStartConnecting];
    }
  } else {
    NSLog(@"ERROR: Trying to connect to another host while connecting to %@", currentService.hostName);
  }
  isResolving = NO;
}

- (void)eventCenterDidConnectToHost:(NSString *)hostName
{
  if ([hostName isEqualToString:currentService.hostName]) {
    if ([self.delegate respondsToSelector:@selector(didConnect:)]) {
      [self.delegate didConnect:currentService.hostName];
    }
  }
  isConnecting = NO;
}

- (void)eventCenterDidDisconnectFromHost:(NSString *)hostName withError:(NSError *)error
{
  [self notifyError:IAConnectionErrorSocketLost userInfo:nil];
  isConnecting = NO;
//  currentService = nil;
}

- (void)eventCenter:(EventCenter *)eventCenter1 receivedEvent:(Event *)event
{
  if ([self.delegate respondsToSelector:@selector(didReceiveEvent:)]) {
    [self.delegate didReceiveEvent:event];
  }
}

-(void)eventCenterFailedToConnectToHost:(NSString *)hostName withError:(NSError *)error
{
  [self notifyError:IAConnectionErrorFailToConnectSocket userInfo:[error userInfo]];
  [self invalidateCurrentService];
  isConnecting = NO;
}

@end