//
// Created by Long Nguyen on 2/11/15.
// Copyright (c) 2015 Long Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JDStatusBarNotification.h"

@interface JDStatusBarNotification (Extension)
+ (void)inAirInit;
+ (JDStatusBarView*)showErrorWithStatus:(NSString *)status;
//+ (JDStatusBarView*)showSuccessWithStatus:(NSString *)status;
@end
