//
// Created by Manh Tuan Cao on 8/21/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GCDAsyncSocket;
@class EventCenter;
@class Event;

@protocol EventCenterDelegate <NSObject>

@required
- (void)eventCenterDidConnect;

- (void)eventCenterDidDisconnectWithError:(NSError *)error;

- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event;
@end

@interface EventCenter : NSObject
@property(nonatomic, strong) GCDAsyncSocket *socket;
@property(nonatomic, weak) id <EventCenterDelegate> delegate;

- (BOOL)isActive;

- (BOOL)connectToHost:(NSString *)hostname;

- (void)sendEvent:(Event *)event withTag:(u_int8_t)tag;
@end