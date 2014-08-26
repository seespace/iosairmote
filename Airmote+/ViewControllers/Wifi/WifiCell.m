//
//  WifiCell.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/20/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "WifiCell.h"

@implementation WifiCell {
  __weak IBOutlet UIImageView *signalStrengthImageView;
  __weak IBOutlet UILabel *wifiNameLabel;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    // Initialization code
  }
  return self;
}

- (void)awakeFromNib {
  // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  [super setSelected:selected animated:animated];

  // Configure the view for the selected state
}

- (void)configureCellWithName:(NSString *)name andSignalLevel:(int)signalLevel {
  wifiNameLabel.text = name;
  signalLevel = MAX(0, MIN(3, signalLevel));
  signalStrengthImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%d", signalLevel + 1]];
}

@end
