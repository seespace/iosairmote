//
// Created by Manh Tuan Cao on 9/7/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "WifiNetwork+Extension.h"


@implementation WifiNetwork (Extension)
- (BOOL)requiredPassword {
  return [self.capabilities.uppercaseString rangeOfString:@"WEP"].location != NSNotFound || [self.capabilities.uppercaseString rangeOfString:@"PSK"].location != NSNotFound ;
}

@end