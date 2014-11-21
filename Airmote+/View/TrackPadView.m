//
// Created by Manh Tuan Cao on 8/21/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "TrackPadView.h"
#import "ProtoHelper.h"
#import "TrackPadViewController.h"

static const uint8_t kTouchBeganTag = 2;
static const uint8_t kTouchMovedTag = 3;
static const uint8_t kTouchEndedTag = 4;
static const uint8_t kTouchCancelledTag = 5;
static const uint8_t kGestureStateChanged = 11;


@implementation TrackPadView
{

}
- (void)awakeFromNib
{
        // Gesture

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandle:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.cancelsTouchesInView = NO;
    [self addGestureRecognizer:tapGesture];

    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandle:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.cancelsTouchesInView = NO;
    [self addGestureRecognizer:doubleTapGesture];

    [tapGesture requireGestureRecognizerToFail:doubleTapGesture];

    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressHandle:)];
    [self addGestureRecognizer:longPressGesture];

    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandle:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeLeft.cancelsTouchesInView = NO;
    [self addGestureRecognizer:swipeLeft];

    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandle:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRight.cancelsTouchesInView = NO;
    [self addGestureRecognizer:swipeRight];

    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandle:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    swipeDown.cancelsTouchesInView = NO;
    [self addGestureRecognizer:swipeDown];

    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandle:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUp.cancelsTouchesInView = NO;
    [self addGestureRecognizer:swipeUp];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandle:)];
    pan.maximumNumberOfTouches = 1;
    pan.cancelsTouchesInView = NO;
    [self addGestureRecognizer:pan];
  
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchHandle:)];
    [self addGestureRecognizer:pinch];

    [pan requireGestureRecognizerToFail:longPressGesture];
    
//    [tapGesture requireGestureRecognizerToFail:pinch];
//    [pan requireGestureRecognizerToFail:pinch];

    pinch.delegate = pan.delegate = tapGesture.delegate = doubleTapGesture.delegate = swipeDown.delegate = swipeUp.delegate = swipeUp.delegate = swipeDown.delegate = pan.delegate = self;
}


#pragma mark -
#pragma mark Touches


- (void)sendTouch:(UITouch *)touch withEvent:(UIEvent *)event tag:(uint8_t)tag
{
    CGPoint location = [touch locationInView:self];
    Event *ev = [ProtoHelper touchEventWithTimestamp:event.timestamp * 1000
                                           locationX:location.x
                                           locationY:location.y
                                      trackareaWidth:self.frame.size.width
                                     trackareaHeight:self.frame.size.height
                                               phase:[ProtoHelper phaseFromUITouchPhase:touch.phase]];

    [[IAConnection sharedConnection] sendEvent:ev withTag:tag];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![[IAConnection sharedConnection] isConnected])
    {
      if (! [[IAConnection sharedConnection] isProcessing]) {
        [self.viewController reconnectToServiceIfNeeded];
      } else {
        NSLog(@"ERROR: Trying to connect when it's connecting.");
      }

      return;
    }

    [self sendTouch:[touches anyObject] withEvent:event tag:kTouchBeganTag];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self sendTouch:[touches anyObject] withEvent:event tag:kTouchMovedTag];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self sendTouch:[touches anyObject] withEvent:event tag:kTouchEndedTag];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self sendTouch:[touches anyObject] withEvent:event tag:kTouchCancelledTag];
}


#pragma mark -
#pragma mark - Gesture Handlers

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)pinchHandle:(UIPinchGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:self];
    Event *ev = [ProtoHelper pinchGestureWithTimestamp:[ProtoHelper now]
                                             locationX:location.x
                                             locationY:location.y
                                        trackareaWidth:self.frame.size.width
                                       trackareaHeight:self.frame.size.height
                                                 state:[ProtoHelper stateFromUIGestureRecognizerState:sender.state]
                                                 scale:sender.scale
                                              velocity:sender.velocity];
    
    [[IAConnection sharedConnection] sendEvent:ev withTag:kGestureStateChanged];
}

- (void)tapHandle:(UITapGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:self];
    Event *ev = [ProtoHelper tapGestureWithTimestamp:[ProtoHelper now]
                                           locationX:location.x
                                           locationY:location.y
                                      trackareaWidth:self.frame.size.width
                                     trackareaHeight:self.frame.size.height
                                               state:[ProtoHelper stateFromUIGestureRecognizerState:sender.state]
                                               count:(int) sender.numberOfTapsRequired];

    [[IAConnection sharedConnection] sendEvent:ev withTag:kGestureStateChanged];
}

- (void)panHandle:(UIPanGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:self];
    CGPoint translation = [sender translationInView:self];
    CGPoint velocity = [sender velocityInView:self];
    Event *ev = [ProtoHelper panGestureWithTimestamp:[ProtoHelper now]
                                           locationX:location.x
                                           locationY:location.y
                                      trackareaWidth:self.frame.size.width
                                     trackareaHeight:self.frame.size.height
                                               state:[ProtoHelper stateFromUIGestureRecognizerState:sender.state]
                                        translationX:translation.x
                                        translationY:translation.y
                                           velocityX:velocity.x
                                           velocityY:velocity.y];

    [[IAConnection sharedConnection] sendEvent:ev withTag:kGestureStateChanged];
}

- (void)swipeHandle:(UISwipeGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:self];
    Event *ev = [ProtoHelper swipeGestureWithTimestamp:[ProtoHelper now]
                                             locationX:location.x
                                             locationY:location.y
                                        trackareaWidth:self.frame.size.width
                                       trackareaHeight:self.frame.size.height
                                                 state:[ProtoHelper stateFromUIGestureRecognizerState:sender.state]
                                             direction:[ProtoHelper directionFromUISwipeGestureRecognizerDirection:sender.direction]];

    [[IAConnection sharedConnection] sendEvent:ev withTag:kGestureStateChanged];
}

- (void)longPressHandle:(UILongPressGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:self];
    Event *ev = [ProtoHelper longpressGestureWithTimestamp:[ProtoHelper now]
                                                 locationX:location.x
                                                 locationY:location.y
                                            trackareaWidth:self.frame.size.width
                                           trackareaHeight:self.frame.size.height
                                                     state:[ProtoHelper stateFromUIGestureRecognizerState:sender.state]
                                                  duration:0];

    [[IAConnection sharedConnection] sendEvent:ev withTag:kGestureStateChanged];
}
@end