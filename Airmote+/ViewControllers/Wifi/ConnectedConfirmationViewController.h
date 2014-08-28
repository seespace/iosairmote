//
//  ConnectedConfirmationViewController.h
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/28/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol ConfirmationViewDelegate <NSObject>
-(void) didConnectedToTheSameNetworkWithInAirDevice;
@end

@interface ConnectedConfirmationViewController : UIViewController
@property (nonatomic, copy) NSString *networkSSID;
@property (nonatomic, weak)  id<ConfirmationViewDelegate> delegate;
@end
