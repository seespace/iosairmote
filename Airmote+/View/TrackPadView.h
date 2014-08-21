//
// Created by Manh Tuan Cao on 8/21/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ViewController;
@class EventCenter;


@interface TrackPadView : UIView
@property (nonatomic, weak) EventCenter *eventCenter;

//As we only use TrackPadView in ViewController class this should be OK
@property (nonatomic, weak) ViewController *viewController;
@end