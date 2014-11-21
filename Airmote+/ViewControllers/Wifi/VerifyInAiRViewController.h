//
//  VerifyInAiRViewController.h
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/20/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IAConnection.h"

@interface VerifyInAiRViewController : UIViewController <IAConnectionDelegate>
@property (nonatomic, copy) NSString *confirmationCode;
@end
