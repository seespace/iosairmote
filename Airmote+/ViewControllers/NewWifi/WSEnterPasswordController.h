//
//  WSEnterPasswordController.h
//  Airmote+
//
//  Created by Long Nguyen on 2/13/15.
//  Copyright (c) 2015 Long Nguyen. All rights reserved.
//

#import "MBTableViewPageController.h"
#import "WifiNetwork+Extension.h"
#import "IAConnection.h"
#import "ProtoHelper.h"

@interface WSEnterPasswordController : MBTableViewPageController <IAConnectionDelegate>

@property (strong, nonatomic) WifiNetwork *selectedNetwork;

- (id) initWithNetwork:(WifiNetwork *)network;

@end
