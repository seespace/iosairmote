//
// Created by Manh Tuan Cao on 8/21/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <netinet/in.h>
#import <netinet/tcp.h>
#import "EventCenter.h"
#import "Proto.pb.h"
#import "ProtoHelper.h"
#import "Event+Extension.h"
#import "IAConnection.h"

static const int kServicePort = 8989;
static const uint8_t kSessionStartTag = 9;
//static const uint8_t kSessionEndTag = 10;

#define DEBUG NO

@implementation EventCenter {
  NSNetService *lastConnectedService;
  GCDAsyncSocket *_usbSocket;
  GCDAsyncSocket *_wifiSocket;
  GCDAsyncSocket *_serverSocket;
}

- (id)init {
  self = [super init];
  if (self) {
    _wifiSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    _serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
  }

  return self;
}

- (void)startServer {
  if (_serverSocket.isConnected) {
    return;
  }

  NSError *error = nil;
  if (![_serverSocket acceptOnPort:kServicePort error:&error]) {
    NSLog(@"Could not listen on port %d. Error: %@", kServicePort, error);
  } else {
    NSLog(@"Listening on port %d", kServicePort);
  }
}

- (void)stopServer {
  [_serverSocket disconnect];
}


- (BOOL)isActive {
  return (_wifiSocket != nil && _wifiSocket.isConnected) || (_usbSocket != nil);
}

- (BOOL)connectToService:(NSNetService *)netService {
  NSError *err = nil;


  DDLogDebug(@"Connecting to host: %@", netService);

  if ([netService.addresses count] > 0) {

    if (![_wifiSocket connectToAddress:netService.addresses[0] withTimeout:10 error:&err]) {

      if ([self.delegate respondsToSelector:@selector(eventCenterFailedToConnectToHost:withError:)]) {
        [self.delegate eventCenterFailedToConnectToHost:netService.hostName withError:err];
      }

      return NO;
    }
  }

  lastConnectedService = netService;
  return YES;
}

- (BOOL)disconnect {
  _wifiSocket.delegate = nil;
  [_wifiSocket disconnect];
  _wifiSocket.delegate = self;
  return NO;
}

- (void)sendEvent:(Event *)event withTag:(u_int8_t)tag {
  NSData *data = [Event dataFromEvent:event];
  if (_usbSocket != nil) {
    [_usbSocket writeData:data withTimeout:0 tag:tag];
  } else {
    [_wifiSocket writeData:data withTimeout:0 tag:tag];
  }
}

- (void)disconnect:(GCDAsyncSocket *)socket {
  socket.delegate = nil;
  [socket disconnect];
  socket.delegate = self;
}

#pragma mark -
#pragma mark Socket methods

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
  NSLog(@"Did read data");

  if (data.length < 4) {
    if (DEBUG) {
      [sock readDataWithTimeout:-1 tag:0];
    } else {
      [self disconnect:sock];
    }

    return;
  }

  NSData *lengthData = [data subdataWithRange:NSMakeRange(0, 4)];
  int length = CFSwapInt32BigToHost(*(int *) ([lengthData bytes]));
  if (length > data.length) {
    NSLog(@"ERROR: Length value is bigger than actual data length");
    if (DEBUG) {
      [sock readDataWithTimeout:-1 tag:0];
    } else {
      [self disconnect:sock];
    }
    return;
  }

  NSData *msg = [data subdataWithRange:NSMakeRange(4, length)];

  Event *event = [ProtoHelper parseFromData:msg];

  if (self.delegate && [self.delegate respondsToSelector:@selector(eventCenter:receivedEvent:)]) {
    [self.delegate eventCenter:self receivedEvent:event];
  }
  [sock readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
  if (sock == _wifiSocket) {
    [self wifiSocketDidDisconnectWithError:error];
  }
  if (sock == _usbSocket) {
    [self usbSocketDidDisconnectWithError:error];
  }
}

#pragma mark - Server Socket Methods

- (void)usbSocketDidDisconnectWithError:(NSError *)error {
  _usbSocket = nil;

  if (self.delegate && [self.delegate respondsToSelector:@selector(eventCenterDidStopUSBConnectionWithError:)]) {
    [self.delegate eventCenterDidStopUSBConnectionWithError:error];
  }
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
  DDLogDebug(@"New socket %@", newSocket);
  [newSocket readDataWithTimeout:-1 tag:0];

//  if (_usbSocket != nil) {
//    [_usbSocket disconnect];
//  }

  _usbSocket = newSocket;

  // TCP_NO_DELAY
  [_usbSocket performBlock:^{
      int fd = [_usbSocket socketFD];
      int on = 1;
      if (setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (char *) &on, sizeof(on)) == -1) {
        DDLogDebug(@"Could not set sock opt TCP_NODELAY: %s", strerror(errno));
      }
  }];

  if (self.delegate && [self.delegate respondsToSelector:@selector(eventCenterDidStartUSBConnection)]) {
    [self.delegate eventCenterDidStartUSBConnection];
  }
}

#pragma mark - Wifi Socket Methods

- (void)wifiSocketDidDisconnectWithError:(NSError *)error {
  if (self.delegate && [self.delegate respondsToSelector:@selector(eventCenterDidDisconnectFromHost:withError:)]) {
    [self.delegate eventCenterDidDisconnectFromHost:lastConnectedService.hostName withError:error];
  }
  lastConnectedService = nil;
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
  NSLog(@"Connected to %@", host);
  // TCP_NO_DELAY
  [_wifiSocket performBlock:^{
      int fd = [_wifiSocket socketFD];
      int on = 1;
      if (setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (char *) &on, sizeof(on)) == -1) {
        DDLogDebug(@"Could not set sock opt TCP_NODELAY: %s", strerror(errno));
      }
  }];

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:host forKey:@"host"];
  [defaults setInteger:port forKey:@"port"];

  // Register this device
  [self registerDevice];

  [_wifiSocket readDataWithTimeout:-1 tag:0];
  if (self.delegate && [self.delegate respondsToSelector:@selector(eventCenterDidConnectToService:)]) {
    [self.delegate eventCenterDidConnectToService:lastConnectedService];
  }
}


#pragma mark - Handshake

- (void)registerDevice {
  Event *event = [ProtoHelper deviceEventWithTimestamp:[ProtoHelper now] type:DeviceEventTypeRegister];
  DDLogDebug(@"Sending Event: %@", event);
  [self sendEvent:event withTag:kSessionStartTag];
}

- (void)connectToHost:(NSString *)address {
  NSError *err = nil;

  lastConnectedService = [[NSNetService alloc] initWithDomain:@"tv.inair" type:kManualIPAddress name:address port:0];

  DDLogDebug(@"Connecting to host: %@", address);

  if ([address length] > 0) {

    if (![_wifiSocket connectToHost:address onPort:kServicePort withTimeout:10 error:&err]) {
      if ([self.delegate respondsToSelector:@selector(eventCenterFailedToConnectToHost:withError:)]) {
        [self.delegate eventCenterFailedToConnectToHost:address withError:err];
      }
    }
  }
}

- (BOOL)isUSBConnected {
  return _usbSocket != nil && _usbSocket.isConnected;
}
@end
