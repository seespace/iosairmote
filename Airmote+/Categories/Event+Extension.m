//
// Created by Manh Tuan Cao on 8/20/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "Event+Extension.h"


@implementation Event (Extension)
+ (NSData *)dataFromEvent:(Event *)event
{
    SInt32 length = (SInt32) htonl(event.data.length);

    NSMutableData *data = [NSMutableData dataWithBytes:&length length: sizeof(length)];
    [data appendData:event.data];

    return data;
}
@end