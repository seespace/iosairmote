//
// Created by Manh Tuan Cao on 8/20/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Proto.pb.h"

@interface Event (Extension)
+(NSData *) dataFromEvent:(Event *)event;
@end