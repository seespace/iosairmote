//
// Created by Manh Tuan Cao on 11/18/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventCenter.h"

@class Event;

#define kIAConnectionErrorDomain @"InAir.Error"
#define kManualIPAddress @"Manual"

typedef NS_ENUM(NSInteger, IAConnectionError) {
  IAConnectionErrorWifiNotAvailable,
  IAConnectionErrorDidNotSearch,
  IAConnectionErrorServicesNotFound,
  IAConnectionErrorDiscoveryTimedOut,
  IAConnectionErrorSocketInvalidData,
  IAConnectionErrorServiceNotResolved,
  IAConnectionErrorSocketDisconnected,
  IAConnectionErrorFailToConnectSocket,
  IAConnectionErrorFailToSendEvent

};

@protocol IAConnectionDelegate <NSObject>

@optional

-(void) didStartScanning;
-(void) didStartConnecting;

-(void) didConnect:(NSString *) hostName;
-(void) didFoundServices:(NSArray *) foundServices;
-(void) didFailToConnect:(NSError *) error;

- (BOOL)shouldConnectAutomatically;
-(void) didReceiveEvent:(Event *) event;

- (void)didStopConnection;
@end

@interface IAConnection : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate, EventCenterDelegate>
@property (nonatomic, weak) id <IAConnectionDelegate> delegate;
@property (nonatomic, readonly) NSArray *foundServices;
+ (IAConnection *)sharedConnection;

-(BOOL)isProcessing;
-(BOOL) isConnected;
- (void) start;
- (void)sendEvent:(Event *)event withTag:(u_int8_t)tag;
- (void) connectToServiceAtIndex:(NSUInteger) index;
- (void) stop;
- (void) connectToHost:(NSString *) ipAddress;
- (void) resetStates;
- (void) startServer;
- (void) stopServer;

@end