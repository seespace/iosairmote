//
//  WSNetworksController.h
//  Airmote+
//
//  Created by Long Nguyen on 2/13/15.
//  Copyright (c) 2015 Long Nguyen. All rights reserved.
//

#import "MBTableViewPageController.h"
#import "IAConnection.h"
#import "WifiNetwork+Extension.h"

@interface WSNetworksController : MBTableViewPageController <IAConnectionDelegate>

@property (strong, nonatomic) WifiNetwork *selectedNetwork;

@end
