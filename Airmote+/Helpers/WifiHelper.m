//
// Created by Manh Tuan Cao on 8/26/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "WifiHelper.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@implementation WifiHelper {

}
+ (NSString *)currentConnectedWiFiSSID {
    NSArray *ifs = (__bridge_transfer NSArray *) CNCopySupportedInterfaces();
    NSLog(@"Supported interfaces: %@", ifs);
    NSDictionary *info;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer NSDictionary *) CNCopyCurrentNetworkInfo((__bridge CFStringRef) ifnam);
        NSLog(@"%@ => %@", ifnam, info);
        if (info && [info count]) {
            break;
        }
    }


    return info[@"SSID"];
}

+ (BOOL)isConnectedToInAiRWiFi {
  NSString *currentWifiSDID = [WifiHelper currentConnectedWiFiSSID];
  if ([currentWifiSDID rangeOfString:@"InAir"].location != NSNotFound)
  {
    return YES;
  }

  return NO;
}


@end