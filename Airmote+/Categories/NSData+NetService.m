//
// Created by Manh Tuan Cao on 8/21/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <arpa/inet.h>
#import "NSData+NetService.h"


@implementation NSData (NetService)
- (NSString *)socketAddress
{
    struct sockaddr_in *socketAddress = nil;
    NSString *ipString = nil;

    socketAddress = (struct sockaddr_in *) [self bytes];
    ipString = [NSString stringWithFormat:@"%s",
                inet_ntoa(socketAddress->sin_addr)];
    return ipString;
}

@end