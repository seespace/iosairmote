//
// Created by Manh Tuan Cao on 11/18/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "IAConnection.h"
#import "Proto.pb.h"
#import "Reachability.h"
#import "WifiHelper.h"

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

  NSString *lastConnectedWifi;
  Reachability *reachability;
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
    reachability = [Reachability reachabilityForLocalWiFi];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionDidChange:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    [reachability startNotifier];
  }
  return self;
}


-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [reachability stopNotifier];
  reachability = nil;
}

- (void)connectionDidChange:(NSNotification *)notification
{
  NSString *currentSSID = [WifiHelper currentConnectedWiFiSSID];
  if (lastConnectedWifi != nil && ![currentSSID isEqualToString:lastConnectedWifi]) {
    [self stop];
    [self resetStates];
    [self start];
  }

  lastConnectedWifi = currentSSID;
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
  NSError *error = [self errorWithCode:IAConnectionErrorDidNotSearch withReason:@"Cannot start scanning"];
  [self notifyError:error];
}


- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
  DDLogDebug(@"netServiceBrowserDidStopSearch");
  isScanning = NO;
  [timeOutTimer invalidate];
  if ([foundServices count] == 0) {
    NSError *error = [self errorWithCode:IAConnectionErrorServicesNotFound withReason:@"Devices not found"];
    [self notifyError:error];
  }

}

-(NSError *) errorWithCode:(IAConnectionError) errorCode withReason:(NSString *) reason {
  return [NSError errorWithDomain:kIAConnectionErrorDomain code:errorCode userInfo:@{NSLocalizedFailureReasonErrorKey: reason}];
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

  if (!self.isConnected && ! self.isProcessing ) {
    BOOL wifiChanged = lastConnectedWifi != nil && ![lastConnectedWifi isEqualToString:[WifiHelper currentConnectedWiFiSSID]];
    if (wifiChanged) {
      [self stop];
      [self resetStates];
    }
    DDLogDebug(@"Should start IAConnection");
    if ([self.delegate respondsToSelector:@selector(shouldConnectAutomatically)] && [self.delegate shouldConnectAutomatically]) {
      [self start];
      lastConnectedWifi = [WifiHelper currentConnectedWiFiSSID];
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
    timeOutTimer = [NSTimer scheduledTimerWithTimeInterval:kMaxScanningDuration
                                                    target:self
                                                  selector:@selector(timerFired:)
                                                  userInfo:nil
                                                   repeats:NO];
  } else {
    DDLogDebug(@"Failed to scan because no wifi available");
    NSError *error = [self errorWithCode:IAConnectionErrorWifiNotAvailable withReason:@"Wifi is not available"];
    [self notifyError:error];
  }
}


- (void)notifyError:(NSError *)error
{
  if ([self.delegate respondsToSelector:@selector(didFailToConnect:)]) {
    [self.delegate didFailToConnect:error];
  }
}


- (void)timerFired:(NSTimer *)timer
{
  [browser stop];
  if ([self.delegate respondsToSelector:@selector(didFailToConnect:)]) {
    NSError *error = [self errorWithCode:IAConnectionErrorDiscoveryTimedOut withReason:@"Scanning timed out."];
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
    [eventCenter connectToService:currentService];

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

  if (self.isConnected || self.isProcessing) {
    return;
  }

  [self startScanningServices];
}



- (void)stop
{
  DDLogDebug(@"STOP connection");
  if (timeOutTimer != nil) {
    [timeOutTimer invalidate];
    timeOutTimer = nil;
  }
  browser.delegate = nil;
  eventCenter.delegate = nil;
  currentService.delegate = nil;

  [eventCenter disconnect];
  [currentService stop];
  [browser stop];

  browser = nil;
  currentService = nil;
  eventCenter = nil;

  isConnecting = NO;
  isScanning = NO;
  isScanning = NO;
  if ([self.delegate respondsToSelector:@selector(didStopConnection)]) {
    [self.delegate didStopConnection];
  }
}

- (void)connectToHost:(NSString *)ipAddress
{
  isConnecting = YES;
  currentService = [[NSNetService alloc] initWithDomain:@"tv.inair" type:kManualIPAddress name:ipAddress port:0];
  [eventCenter connectToHost:ipAddress];
}


- (void)resetStates
{
  DDLogDebug(@"Resetting states");
  [foundServices removeAllObjects];
  foundAllServices = NO;
  currentService = nil;

  lastConnectedWifi = nil;
  browser = [[NSNetServiceBrowser alloc] init];
  browser.delegate = self;

  eventCenter = [[EventCenter alloc] init];
  eventCenter.delegate = self;
}


- (void)sendEvent:(Event *)event withTag:(u_int8_t)tag
{
  DDLogDebug(@"Sending Event: %@", event);
  if (eventCenter.isActive) {
    [eventCenter sendEvent:event withTag:tag];
//    lastActiveTime = [NSDate date];
  } else {
    DDLogError(@"Cannot send event, event center is not connected");
    NSString *errorReason = [NSString stringWithFormat:@"Failed to send event: %@", event.description];
    NSError *error = [self errorWithCode:IAConnectionErrorFailToSendEvent withReason:errorReason];
    [self notifyError:error];
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
      [eventCenter connectToService:currentService];
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
  NSError *error = [NSError errorWithDomain:kIAConnectionErrorDomain code:IAConnectionErrorServiceNotResolved userInfo:errorDict];
  [self notifyError:error];
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
    [eventCenter connectToService:currentService];
    if ([self.delegate respondsToSelector:@selector(didStartConnecting)]) {
      [self.delegate didStartConnecting];
    }
  } else {
    DDLogError(@"ERROR: Trying to connect to another host while connecting to %@", currentService.hostName);
  }
}

- (void)eventCenterDidConnectToService:(NSNetService *)netService
{
  DDLogDebug(@"Did connect to host name %@", netService);
  isConnecting = NO;
  if ([netService.hostName isEqualToString:currentService.hostName] || [netService.type isEqualToString:kManualIPAddress]) {
    if ([self.delegate respondsToSelector:@selector(didConnect:)]) {
      [self.delegate didConnect:currentService.name];
    }
  }
}

- (void)eventCenterDidDisconnectFromHost:(NSString *)hostName withError:(NSError *)err
{
  DDLogError(@"Event did disconnect from host: %@ - Error %@", hostName, err);
  isConnecting = NO;
  NSError *error = [NSError errorWithDomain:kIAConnectionErrorDomain code:IAConnectionErrorSocketDisconnected userInfo:[err userInfo]];
  [self notifyError:error];
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
  NSError *tmpError = [NSError errorWithDomain:kIAConnectionErrorDomain
                                          code:IAConnectionErrorFailToConnectSocket
                                      userInfo:[error userInfo]];
  [self notifyError:tmpError];
  [self invalidateCurrentService];
}

@end