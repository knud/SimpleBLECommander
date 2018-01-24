//
//  BagTableViewCell.m
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-01-01.
//  Copyright © 2018 Envisas Inc. All rights reserved.
//

#import "BagTableViewCell.h"

@implementation BagTableViewCell

@synthesize peripheral;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
