//
//  ProtoHelper.h
//  Airmote+
//
//  Created by Long Nguyen on 7/3/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ProtocolBuffers/ProtocolBuffers.h>
#import "Proto.pb.h"

@interface ProtoHelper : NSObject

- (instancetype)init;

+ (ProtoHelper *)sharedHelper;

+ (SInt64)now;

+ (Event *)parseFromData:(NSData *)data;

+ (Device *)currentDevice;

+ (Phase)phaseFromUITouchPhase:(UITouchPhase)phase;

+ (GestureEventState)stateFromUIGestureRecognizerState:
    (UIGestureRecognizerState)state;

+ (GestureEventSwipeDirection)directionFromUISwipeGestureRecognizerDirection:
    (UISwipeGestureRecognizerDirection)direction;

// Event Generator

+ (Event *)deviceEventWithTimestamp:(SInt64)timestamp
                               type:(DeviceEventType)type;

+ (Event *)touchEventWithTimestamp:(SInt64)timestamp
                         locationX:(Float32)locationX
                         locationY:(Float32)locationY
                    trackareaWidth:(Float32)width
                   trackareaHeight:(Float32)height
                             phase:(Phase)phase;

+ (Event *)motionEventWithTimestamp:(SInt64)timestamp
                               type:(MotionEventType)type;

+ (Event *)keypressEventWithTimestamp:(SInt64)timestamp
                                state:(KeypressEventState)state
                              keycode:(SInt32)keycode;

+ (Event *)tapGestureWithTimestamp:(SInt64)timestamp
                         locationX:(Float32)locationX
                         locationY:(Float32)locationY
                    trackareaWidth:(Float32)width
                   trackareaHeight:(Float32)height
                             state:(GestureEventState)state
                             count:(SInt32)tapCount;

+ (Event *)panGestureWithTimestamp:(SInt64)timestamp
                         locationX:(Float32)locationX
                         locationY:(Float32)locationY
                    trackareaWidth:(Float32)width
                   trackareaHeight:(Float32)height
                             state:(GestureEventState)state
                      translationX:(Float32)translationX
                      translationY:(Float32)translationY
                         velocityX:(Float32)velocityX
                         velocityY:(Float32)velocityY;

+ (Event *)swipeGestureWithTimestamp:(SInt64)timestamp
                           locationX:(Float32)locationX
                           locationY:(Float32)locationY
                      trackareaWidth:(Float32)width
                     trackareaHeight:(Float32)height
                               state:(GestureEventState)state
                           direction:(GestureEventSwipeDirection)direction;

+ (Event *)longpressGestureWithTimestamp:(SInt64)timestamp
                               locationX:(Float32)locationX
                               locationY:(Float32)locationY
                          trackareaWidth:(Float32)width
                         trackareaHeight:(Float32)height
                                   state:(GestureEventState)state
                                duration:(SInt64)duration;

+ (Event *)oauthResponseWithCode:(NSString *)code
                          target:(NSString *)target;

+ (Event *)setupCodeRequest;

+ (Event *)setupRenameRequestWithName:(NSString *)name;

+ (Event *)setupWifiScanRequest;

+ (Event *)setupWifiConnectRequestWithSSID:(NSString *)ssid
                                  password:(NSString *)password;

@end
