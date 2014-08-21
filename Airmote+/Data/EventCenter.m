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

static const int kServicePort = 8989;
static const uint8_t kSessionStartTag = 9;
//static const uint8_t kSessionEndTag = 10;

@implementation EventCenter
{

}

- (id)init
{
    self = [super init];
    if (self)
    {
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

    return self;
}


- (BOOL)isActive
{
    return (_socket != nil && _socket.isConnected);
}

- (BOOL)connectToHost:(NSString *)hostname
{
    NSError *err = nil;

    if (![_socket connectToHost:hostname onPort:kServicePort withTimeout:3 error:&err])
    {
        NSLog(@"Could not connect to %@. Error: %@", hostname, err);
        return NO;
    }

    return YES;
}

- (void)sendEvent:(Event *)event withTag:(u_int8_t)tag
{
    NSData *data = [Event dataFromEvent:event];
    [_socket writeData:data withTimeout:0 tag:tag];
}


#pragma mark -
#pragma mark Socket methods

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSLog(@"New socket %@", newSocket);
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"Did read data");

    NSData *msg = [data subdataWithRange:NSMakeRange(4, data.length - 4)];

    Event *event = [ProtoHelper parseFromData:msg];

    if (self.delegate && [self.delegate respondsToSelector:@selector(eventCenter:receivedEvent:)])
    {
        [self.delegate eventCenter:self receivedEvent:event];
    }
    [_socket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"Connected to %@", host);

    // TCP_NO_DELAY
    [_socket performBlock:^{
        int fd = [_socket socketFD];
        int on = 1;
        if (setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (char *) &on, sizeof(on)) == -1)
        {
            NSLog(@"Could not set sock opt TCP_NODELAY: %s", strerror(errno));
        }
    }];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:host forKey:@"host"];
    [defaults setInteger:port forKey:@"port"];

    // Register this device
    [self registerDevice];

    [_socket readDataWithTimeout:-1 tag:0];
    if (self.delegate && [self.delegate respondsToSelector:@selector(eventCenterDidConnect)])
    {
        [self.delegate eventCenterDidConnect];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(eventCenterDidDisconnectWithError:)])
    {
        [self.delegate eventCenterDidDisconnectWithError:error];
    }
}


#pragma mark - Handshake

- (void)registerDevice
{
    Event *ev = [ProtoHelper deviceEventWithTimestamp:[ProtoHelper now] type:DeviceEventTypeRegister];
    NSData *data = [Event dataFromEvent:ev];
    [_socket writeData:data withTimeout:0 tag:kSessionStartTag];
}

@end