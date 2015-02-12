//
// Created by Long Nguyen on 2/11/15.
// Copyright (c) 2015 Long Nguyen. All rights reserved.
//

#import "JDStatusBarNotification+Extension.h"

#define kErrorStyleName @"InAirError"
#define kUSBStyleName @"InAirUSB"

@implementation JDStatusBarNotification (Extension)
+ (void)inAirInit {
  [JDStatusBarNotification addStyleNamed:@"InAirLight"
                                 prepare:^JDStatusBarStyle *(JDStatusBarStyle *style) {
                                     style.barColor = RGBA(242, 242, 242, 0.9f);
                                     style.textColor = [UIColor blackColor];
                                     return style;
                                 }];

  [JDStatusBarNotification addStyleNamed:kErrorStyleName
                                 prepare:^JDStatusBarStyle *(JDStatusBarStyle *style) {
                                     style.barColor = RGBA(246, 71, 71, 1);
                                     style.textColor = [UIColor whiteColor];
                                     return style;
                                 }];

  [JDStatusBarNotification addStyleNamed:kUSBStyleName
                                 prepare:^JDStatusBarStyle *(JDStatusBarStyle *style) {
                                     style.barColor = RGBA(75, 119, 190, 1);
                                     style.textColor = [UIColor whiteColor];
                                     return style;
                                 }];

  [JDStatusBarNotification setDefaultStyle:^JDStatusBarStyle *(JDStatusBarStyle *style) {
      style.barColor = RGBA(242, 242, 242, 1);
      style.textColor = [UIColor blackColor];
      return style;
  }];
}

+ (JDStatusBarView *)showErrorWithStatus:(NSString *)status {
  return [JDStatusBarNotification showWithStatus:status styleName:kErrorStyleName];
}

+ (JDStatusBarView *)showUSBConnection {
  return [JDStatusBarNotification showWithStatus:@"USB Connection" styleName:kUSBStyleName];
}


@end
