//
// Created by Manh Tuan Cao on 8/21/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TrackPadViewController;

@interface TrackPadView : UIView
//As we only use TrackPadView in TrackPadViewController class this should be OK
@property (nonatomic, weak) TrackPadViewController *viewController;
@end