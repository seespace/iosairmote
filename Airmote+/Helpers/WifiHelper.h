//
// Created by Manh Tuan Cao on 8/26/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WifiHelper : NSObject
+(NSString *)currentConnectedWiFiSSID;

/**
* @return YES if connected to a WiFi with SDID in following format "InAiRxxxx", x stands for a digit
*/
+(BOOL)isConnectedToInAiRWiFi;
@end