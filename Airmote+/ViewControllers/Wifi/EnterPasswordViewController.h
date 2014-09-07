//
//  EnterPasswordViewController.h
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/20/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventCenter.h"

@interface EnterPasswordViewController : UIViewController <EventCenterDelegate, UITextFieldDelegate>

@property(nonatomic, copy) NSString *networkSSID;
@end
