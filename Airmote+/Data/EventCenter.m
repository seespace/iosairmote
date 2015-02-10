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

@implementation EventCenter {
  NSNetService *lastConnectedService;
  GCDAsyncSocket *_clientSocket;
}

- (id)init {
  self = [super init];
  if (self) {
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    _server = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
  }

  return self;
}

- (void)startServer {
  NSError *error = nil;
  if (![_server acceptOnPort:kServicePort error:&error]) {
    NSLog(@"Could not listen on port %d. Error: %@", kServicePort, error);
  } else {
    NSLog(@"Listening on port %d", kServicePort);
  }
}

- (void)stopServer {
  [_server disconnect];
}


- (BOOL)isActive {
  return (_socket != nil && _socket.isConnected) || (_clientSocket != nil);
}

- (BOOL)connectToService:(NSNetService *)netService {
  NSError *err = nil;


  DDLogDebug(@"Connecting to host: %@", netService);

  if ([netService.addresses count] > 0) {

    if (![_socket connectToAddress:netService.addresses[0] withTimeout:10 error:&err]) {

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
  _socket.delegate = nil;
  [_socket disconnect];
  _socket.delegate = self;
  return NO;
}

- (void)sendEvent:(Event *)event withTag:(u_int8_t)tag {
  NSData *data = [Event dataFromEvent:event];
  if (_clientSocket != nil) {
    [_clientSocket writeData:data withTimeout:0 tag:tag];
  } else {
    [_socket writeData:data withTimeout:0 tag:tag];
  }
}

#pragma mark -
#pragma mark Socket methods

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
  if (sock == _socket) {
    [self wifiSocketDidReadData:data withTag:tag];
  }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
  if (sock == _socket) {
    [self wifiSocketDidDisconnectWithError:error];
  }
  if (sock == _server) {
    [self lightningSocketDidDisconnectWithError:error];
  }
}

#pragma mark - Server Socket Methods

- (void)lightningSocketDidDisconnectWithError:(NSError *)error {
  _clientSocket = nil;
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
  NSLog(@"New socket %@", newSocket);
  [newSocket readDataWithTimeout:-1 tag:0];

  if (_clientSocket != nil) {
    [_clientSocket disconnect];
  }

  _clientSocket = newSocket;

  // TCP_NO_DELAY
  [_clientSocket performBlock:^{
    int fd = [_clientSocket socketFD];
    int on = 1;
    if (setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (char *) &on, sizeof(on)) == -1) {
      NSLog(@"Could not set sock opt TCP_NODELAY: %s", strerror(errno));
    }
  }];
}

#pragma mark - Wifi Socket Methods

- (void)wifiSocketDidReadData:(NSData *)data withTag:(long)tag {
  NSLog(@"Did read data");

  if (data.length < 4) {
    return;
  }

  NSData *lengthData = [data subdataWithRange:NSMakeRange(0, 4)];
  int length = CFSwapInt32BigToHost(*(int *) ([lengthData bytes]));
  if (length > data.length) {
    NSLog(@"ERROR: Length value is bigger than actual data length");
    return;
  }

  NSData *msg = [data subdataWithRange:NSMakeRange(4, length)];

  Event *event = [ProtoHelper parseFromData:msg];

  if (self.delegate && [self.delegate respondsToSelector:@selector(eventCenter:receivedEvent:)]) {
    [self.delegate eventCenter:self receivedEvent:event];
  }
  [_socket readDataWithTimeout:-1 tag:0];
}

- (void)wifiSocketDidDisconnectWithError:(NSError *)error {
  if (self.delegate && [self.delegate respondsToSelector:@selector(eventCenterDidDisconnectFromHost:withError:)]) {
    [self.delegate eventCenterDidDisconnectFromHost:lastConnectedService.hostName withError:error];
  }
  lastConnectedService = nil;
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
  NSLog(@"Connected to %@", host);
  // TCP_NO_DELAY
  [_socket performBlock:^{
      int fd = [_socket socketFD];
      int on = 1;
      if (setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (char *) &on, sizeof(on)) == -1) {
        NSLog(@"Could not set sock opt TCP_NODELAY: %s", strerror(errno));
      }
  }];

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:host forKey:@"host"];
  [defaults setInteger:port forKey:@"port"];

  // Register this device
  [self registerDevice];

  [_socket readDataWithTimeout:-1 tag:0];
  if (self.delegate && [self.delegate respondsToSelector:@selector(eventCenterDidConnectToService:)]) {
    [self.delegate eventCenterDidConnectToService:lastConnectedService];
  }
}


#pragma mark - Handshake

- (void)registerDevice {
  Event *ev = [ProtoHelper deviceEventWithTimestamp:[ProtoHelper now] type:DeviceEventTypeRegister];
  NSData *data = [Event dataFromEvent:ev];
  [_socket writeData:data withTimeout:0 tag:kSessionStartTag];
}

- (void)connectToHost:(NSString *)address {
  NSError *err = nil;

  lastConnectedService = [[NSNetService alloc] initWithDomain:@"tv.inair" type:kManualIPAddress name:address port:0];

  DDLogDebug(@"Connecting to host: %@", address);

  if ([address length] > 0) {

    if (![_socket connectToHost:address onPort:kServicePort withTimeout:10 error:&err]) {
      if ([self.delegate respondsToSelector:@selector(eventCenterFailedToConnectToHost:withError:)]) {
        [self.delegate eventCenterFailedToConnectToHost:address withError:err];
      }
    }
  }
}
@end
