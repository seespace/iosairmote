//
//  ProtoHelper.m
//  Airmote+
//
//  Created by Long Nguyen on 7/3/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "ProtoHelper.h"

@interface ProtoHelper ()

@property(nonatomic, strong) PBMutableExtensionRegistry *registry;

@end

@implementation ProtoHelper

static ProtoHelper *instance;

- (instancetype)init {
  if (self = [super init]) {
    self.registry = [PBMutableExtensionRegistry registry];
    [ProtoRoot registerAllExtensions:self.registry];
  }

  return self;
}

+ (void)ensureInitialized {
  [ProtoHelper sharedHelper];
}

+ (ProtoHelper *)sharedHelper {
  if (instance == nil) {
    instance = [[ProtoHelper alloc] init];
  }

  return instance;
}

+ (Event *)parseFromData:(NSData *)data {
  return [Event parseFromData:data extensionRegistry:instance.registry];
}

+ (SInt64)now {
  return (SInt64) ([[NSDate date] timeIntervalSince1970] * 1000);
}

+ (Phase)phaseFromUITouchPhase:(UITouchPhase)phase {
  switch (phase) {
    case UITouchPhaseBegan:
      return PhaseBegan;
      break;
    case UITouchPhaseMoved:
      return PhaseMoved;
      break;
    case UITouchPhaseStationary:
      return PhaseStationary;
      break;
    case UITouchPhaseCancelled:
      return PhaseCancelled;
    case UITouchPhaseEnded:
    default:
      return PhaseEnded;
      break;
  }
}

+ (GestureEventState)stateFromUIGestureRecognizerState:
    (UIGestureRecognizerState)state {
  switch (state) {
    case UIGestureRecognizerStateBegan:
      return GestureEventStateBegan;
      break;
    case UIGestureRecognizerStatePossible:
      return GestureEventStatePossible;
      break;
    case UIGestureRecognizerStateChanged:
      return GestureEventStateChanged;
      break;
    case UIGestureRecognizerStateCancelled:
      return GestureEventStateCancelled;
      break;
    case UIGestureRecognizerStateFailed:
      return GestureEventStateFailed;
      break;
    case UIGestureRecognizerStateEnded:
    default:
      return GestureEventStateEnded;
      break;
  }
}

+ (GestureEventSwipeDirection)directionFromUISwipeGestureRecognizerDirection:
    (UISwipeGestureRecognizerDirection)direction {
  [self ensureInitialized];

  switch (direction) {
    case UISwipeGestureRecognizerDirectionDown:
      return GestureEventSwipeDirectionDown;
      break;
    case UISwipeGestureRecognizerDirectionLeft:
      return GestureEventSwipeDirectionLeft;
    case UISwipeGestureRecognizerDirectionRight:
      return GestureEventSwipeDirectionRight;
    case UISwipeGestureRecognizerDirectionUp:
    default:
      return GestureEventSwipeDirectionUp;
      break;
  }
}

+ (Device *)currentDevice {
  DeviceBuilder *builder = [[DeviceBuilder alloc] init];
  builder.name = [[UIDevice currentDevice] name];
  builder.vendor = DeviceVendorIos;
  builder.productId = [NSString
      stringWithFormat:@"%@", [[UIDevice currentDevice] identifierForVendor]];
  builder.version = (SInt32) [[[[NSBundle mainBundle] infoDictionary]
      objectForKey:@"CFBundleVersion"] intValue];
  builder.hasKeyboard = YES;

  return [builder build];
}

+ (Event *)deviceEventWithTimestamp:(SInt64)timestamp
                               type:(DeviceEventType)type {

  [self ensureInitialized];

  Device *device = [self currentDevice];
  DeviceEvent *event = [[[[[DeviceEventBuilder alloc] init] setType:type]
      setDevice:device] build];

  // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.timestamp = timestamp;
  builder.type = EventTypeDevice;
  builder.trackingAreaWidth = builder.trackingAreaHeight = 0;
  [builder setExtension:[DeviceEvent event] value:event];

  return [builder build];
}

+ (Event *)touchEventWithTimestamp:(SInt64)timestamp
                         locationX:(Float32)locationX
                         locationY:(Float32)locationY
                    trackareaWidth:(Float32)width
                   trackareaHeight:(Float32)height
                             phase:(Phase)phase {

  [self ensureInitialized];

  TouchEventBuilder *eBuilder = [[TouchEventBuilder alloc] init];
  eBuilder.locationX = locationX;
  eBuilder.locationY = locationY;
  eBuilder.phase = phase;

  TouchEvent *event = [eBuilder build];

  // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.timestamp = timestamp;
  builder.trackingAreaWidth = width;
  builder.trackingAreaHeight = height;
  builder.type = EventTypeTouch;
  [builder setExtension:[TouchEvent event] value:event];

  return [builder build];
}

+ (Event *)motionEventWithTimestamp:(SInt64)timestamp
                               type:(MotionEventType)type {

  [self ensureInitialized];

  MotionEvent *event =
      [[[[MotionEventBuilder alloc] init] setType:MotionEventTypeShake] build];

  // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.timestamp = timestamp;
  builder.type = EventTypeMotion;
  builder.trackingAreaWidth = builder.trackingAreaHeight = 0;
  [builder setExtension:[MotionEvent event] value:event];

  return [builder build];
}

+ (Event *)keypressEventWithTimestamp:(SInt64)timestamp
                                state:(KeypressEventState)state
                              keycode:(SInt32)keycode {

  [self ensureInitialized];

  KeypressEvent *event = [[[[[KeypressEventBuilder alloc] init] setState:state]
      setKeycode:keycode] build];

  // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.timestamp = timestamp;
  builder.type = EventTypeKeypress;
  builder.trackingAreaWidth = builder.trackingAreaHeight = 0;
  [builder setExtension:[KeypressEvent event] value:event];

  return [builder build];
}

+ (Event *)tapGestureWithTimestamp:(SInt64)timestamp
                         locationX:(Float32)locationX
                         locationY:(Float32)locationY
                    trackareaWidth:(Float32)width
                   trackareaHeight:(Float32)height
                             state:(GestureEventState)state
                             count:(SInt32)tapCount {

  [self ensureInitialized];

  GestureEventBuilder *eBuilder = [[GestureEventBuilder alloc] init];
  eBuilder.locationX = locationX;
  eBuilder.locationY = locationY;
  eBuilder.state = state;
  eBuilder.type = GestureEventTypeTap;
  eBuilder.tapCount = tapCount;

  GestureEvent *event = [eBuilder build];

  // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.timestamp = timestamp;
  builder.trackingAreaWidth = width;
  builder.trackingAreaHeight = height;
  builder.type = EventTypeGesture;
  [builder setExtension:[GestureEvent event] value:event];

  return [builder build];
}

+ (Event *)panGestureWithTimestamp:(SInt64)timestamp
                         locationX:(Float32)locationX
                         locationY:(Float32)locationY
                    trackareaWidth:(Float32)width
                   trackareaHeight:(Float32)height
                             state:(GestureEventState)state
                      translationX:(Float32)translationX
                      translationY:(Float32)translationY
                         velocityX:(Float32)velocityX
                         velocityY:(Float32)velocityY {

  [self ensureInitialized];

  GestureEventBuilder *eBuilder = [[GestureEventBuilder alloc] init];
  eBuilder.locationX = locationX;
  eBuilder.locationY = locationY;
  eBuilder.state = state;
  eBuilder.type = GestureEventTypePan;

  eBuilder.panTranslationX = translationX;
  eBuilder.panTranslationY = translationY;
  eBuilder.panVelocityX = velocityX;
  eBuilder.panVelocityY = velocityY;

  GestureEvent *event = [eBuilder build];

  // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.timestamp = timestamp;
  builder.type = EventTypeGesture;
  builder.trackingAreaWidth = width;
  builder.trackingAreaHeight = height;
  [builder setExtension:[GestureEvent event] value:event];

  return [builder build];
}

+ (Event *)pinchGestureWithTimestamp:(SInt64)timestamp
                           locationX:(Float32)locationX
                           locationY:(Float32)locationY
                      trackareaWidth:(Float32)width
                     trackareaHeight:(Float32)height
                               state:(GestureEventState)state
                               scale:(Float32)scale
                            velocity:(Float32)velocity {
    
    [self ensureInitialized];
    
    GestureEventBuilder *eBuilder = [[GestureEventBuilder alloc] init];
    eBuilder.locationX = locationX;
    eBuilder.locationY = locationY;
    eBuilder.state = state;
    eBuilder.type = GestureEventTypePinch;
    
    eBuilder.pinchScale = scale;
    eBuilder.pinchVelocity = velocity;
    
    GestureEvent *event = [eBuilder build];
    
    // Build actual event
    EventBuilder *builder = [[EventBuilder alloc] init];
    builder.timestamp = timestamp;
    builder.type = EventTypeGesture;
    builder.trackingAreaWidth = width;
    builder.trackingAreaHeight = height;
    [builder setExtension:[GestureEvent event] value:event];
    
    return [builder build];
}

+ (Event *)swipeGestureWithTimestamp:(SInt64)timestamp
                           locationX:(Float32)locationX
                           locationY:(Float32)locationY
                      trackareaWidth:(Float32)width
                     trackareaHeight:(Float32)height
                               state:(GestureEventState)state
                           direction:(GestureEventSwipeDirection)direction {

  [self ensureInitialized];

  GestureEventBuilder *eBuilder = [[GestureEventBuilder alloc] init];
  eBuilder.locationX = locationX;
  eBuilder.locationY = locationY;
  eBuilder.state = state;
  eBuilder.type = GestureEventTypeSwipe;

  eBuilder.swipeDirection = direction;

  GestureEvent *event = [eBuilder build];

  // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.timestamp = timestamp;
  builder.trackingAreaWidth = width;
  builder.trackingAreaHeight = height;
  builder.type = EventTypeGesture;
  [builder setExtension:[GestureEvent event] value:event];

  return [builder build];
}

+ (Event *)longpressGestureWithTimestamp:(SInt64)timestamp
                               locationX:(Float32)locationX
                               locationY:(Float32)locationY
                          trackareaWidth:(Float32)width
                         trackareaHeight:(Float32)height
                                   state:(GestureEventState)state
                                duration:(SInt64)duration {

  [self ensureInitialized];

  GestureEventBuilder *eBuilder = [[GestureEventBuilder alloc] init];
  eBuilder.locationX = locationX;
  eBuilder.locationY = locationY;
  eBuilder.state = state;
  eBuilder.type = GestureEventTypeLongpress;

  eBuilder.pressDuration = duration;

  GestureEvent *event = [eBuilder build];

  // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.timestamp = timestamp;
  builder.trackingAreaWidth = width;
  builder.trackingAreaHeight = height;
  builder.type = EventTypeGesture;
  [builder setExtension:[GestureEvent event] value:event];

  return [builder build];
}

+ (Event *)oauthResponseWithCode:(NSString *)code
                          target:(NSString *)target {
  [self ensureInitialized];

  OAuthResponseEvent *event = [[[[OAuthResponseEventBuilder alloc] init] setAuthCode:code] build];

  // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.target = target;
  builder.timestamp = 0;
  builder.trackingAreaWidth = 0;
  builder.trackingAreaHeight = 0;
  builder.type = EventTypeOauthResponse;
  [builder setExtension:[OAuthResponseEvent event] value:event];

  return [builder build];
}

+ (Event *)setupCodeRequest {
  [self ensureInitialized];

  SetupRequestEvent *event = [[[[SetupRequestEventBuilder alloc] init] setPhase:SetupPhaseRequestCode] build];

  // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.timestamp = 0;
  builder.trackingAreaWidth = 0;
  builder.trackingAreaHeight = 0;
  builder.type = EventTypeSetupRequest;
  [builder setExtension:[SetupRequestEvent event] value:event];

  return [builder build];
}

+ (Event *)setupRenameRequestWithName:(NSString *)name {
  [self ensureInitialized];

  SetupRequestEvent *event = [[[[[SetupRequestEventBuilder alloc] init] setPhase:SetupPhaseRequestRename] setName:name] build];

  // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.timestamp = 0;
  builder.trackingAreaWidth = 0;
  builder.trackingAreaHeight = 0;
  builder.type = EventTypeSetupRequest;
  [builder setExtension:[SetupRequestEvent event] value:event];

  return [builder build];
}

+ (Event *)setupWifiScanRequest {
  [self ensureInitialized];

  SetupRequestEvent *event = [[[[SetupRequestEventBuilder alloc] init] setPhase:SetupPhaseRequestWifiScan] build];

  // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.timestamp = 0;
  builder.trackingAreaWidth = 0;
  builder.trackingAreaHeight = 0;
  builder.type = EventTypeSetupRequest;
  [builder setExtension:[SetupRequestEvent event] value:event];

  return [builder build];
}

+ (Event *)setupWifiConnectRequestWithSSID:(NSString *)ssid
                                  password:(NSString *)password {
  [self ensureInitialized];

  SetupRequestEvent *event = [[[[[[SetupRequestEventBuilder alloc] init]
      setPhase:SetupPhaseRequestWifiConnect]
      setSsid:ssid]
      setPassword:password]
      build];

  // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.timestamp = 0;
  builder.trackingAreaWidth = 0;
  builder.trackingAreaHeight = 0;
  builder.type = EventTypeSetupRequest;
  [builder setExtension:[SetupRequestEvent event] value:event];

  return [builder build];
}

+ (Event *)textInputResponseWithState:(TextInputResponseEventState)state
                                 text:(NSString *)text {
  [self ensureInitialized];
  
  TextInputResponseEvent *event = [[[[[TextInputResponseEventBuilder alloc] init]
       setState:state]
       setText:text]
       build];
  
  // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.timestamp = 0;
  builder.trackingAreaWidth = 0;
  builder.trackingAreaHeight = 0;
  builder.type = EventTypeTextInputResponse;
  [builder setExtension:[TextInputResponseEvent event] value:event];
  
  return [builder build];
}

+(Event *) functionEventResponseWithState:(FunctionEventKey) key {
  [self ensureInitialized];
  FunctionEvent *event = [[[[FunctionEventBuilder alloc] init] setKey:key] build];

    // Build actual event
  EventBuilder *builder = [[EventBuilder alloc] init];
  builder.timestamp = 0;
  builder.trackingAreaWidth = 0;
  builder.trackingAreaHeight = 0;
  builder.type = EventTypeFunctionEvent;
  [builder setExtension:[FunctionEvent event] value:event];

  return [builder build];
}
@end
