/*!
 * @file CommandsTableViewCell.m
 * @author Steven Knudsen
 * @date 2018-03-19
 * @brief The BLE command peripherals controller table view cell.
 *
 * This file is part of the Simple BLE Commander example.
 *
 * Copyright (C) 2019 by Steven Knudsen
 *
 * This software may be modified and distributed under the terms
 * of the MIT license.  See the LICENSE file for details.
 */

#import "CommandsTableViewCell.h"

/*!
 * @note So far this is a placeholder class, just in case we need to do something special
 */
@implementation CommandsTableViewCell

@synthesize commandID;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
