//
//  WifiCell.h
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/20/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WifiCell : UITableViewCell
- (void)configureCellWithName:(NSString *)name andSignalLevel:(int)signalLevel;
@end
