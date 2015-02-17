//
// Created by Manh Tuan Cao on 8/21/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GCDAsyncSocket;
@class EventCenter;
@class Event;

@protocol EventCenterDelegate <NSObject>
@optional
- (void)eventCenterDidConnectToService:(NSNetService *)netservice;

- (void)eventCenterDidDisconnectFromHost:(NSString *)hostName withError:(NSError *)error;
- (void)eventCenterFailedToConnectToHost:(NSString *)hostName withError:(NSError *)error;
- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event;

- (void)eventCenterDidStartUSBConnection;
- (void)eventCenterDidStopUSBConnectionWithError:(NSError *)error;
@end

@interface EventCenter : NSObject
@property(nonatomic, weak) id <EventCenterDelegate> delegate;

- (BOOL)isActive;

- (BOOL)connectToService:(NSNetService *)netService;
- (BOOL)disconnect;

- (void)sendEvent:(Event *)event withTag:(u_int8_t)tag;

- (void)connectToHost:(NSString *)address;

- (void)startServer;
- (void)stopServer;

- (BOOL)isUSBConnected;
@end
