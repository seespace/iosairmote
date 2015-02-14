//
//  WSInstructionController.h
//  Airmote+
//
//  Created by Long Nguyen on 2/12/15.
//  Copyright (c) 2015 Long Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBTableViewPageController.h"
#import "IAConnection.h"

@interface WSInstructionController : MBBasePageController <IAConnectionDelegate>

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end
