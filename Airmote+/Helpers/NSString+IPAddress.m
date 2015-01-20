//
//  NSString+IPAddress.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 1/15/15.
//  Copyright (c) 2015 Long Nguyen. All rights reserved.
//

#import "NSString+IPAddress.h"
#import "arpa/inet.h"
@implementation NSString (IPAddress)
- (BOOL)isValidIPAddress
{
  const char *utf8 = [self UTF8String];
  int success;
  
  struct in_addr dst;
  success = inet_pton(AF_INET, utf8, &dst);
  if (success != 1) {
    struct in6_addr dst6;
    success = inet_pton(AF_INET6, utf8, &dst6);
  }
  
  return success == 1;
}

@end
