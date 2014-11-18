//
// Created by Manh Tuan Cao on 11/18/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventCenter.h"

@class Event;

#define kIAConnectionErrorDomain @"InAir.Error"

enum IAConnectionError
{
  IAConnectionErrorDidNotSearch,
  IAConnectionErrorServicesNotFound,
  IAConnectionErrorDiscoveryTimedOut,
  IAConnectionErrorSocketInvalidData,
  IAConnectionErrorServiceNotResolved,
  IAConnectionErrorSocketLost,
  IAConnectionErrorFailToSendEvent
};

@protocol IAConnectionDelegate <NSObject>

@optional

-(void) didConnect:(NSString *) hostName;
-(void) didFoundServices:(NSArray *) foundServices;
-(void) didFailToConnect:(NSError *) error;

- (BOOL)shouldConnectAutomatically;
-(void) didReceiveEvent:(Event *) event;
@end

@interface IAConnection : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate, EventCenterDelegate>
@property (nonatomic, weak) id <IAConnectionDelegate> delegate;
@property (nonatomic, readonly) NSArray *foundServices;
+ (IAConnection *)sharedConnection;

-(BOOL) isConnected;
- (void) start;
//- (void) connect
- (void)sendEvent:(Event *)event withTag:(u_int8_t)tag;
//
//- (void) stop;
- (void) connectToServiceAtIndex:(NSUInteger) index;
//-(void) reconnect;

@end