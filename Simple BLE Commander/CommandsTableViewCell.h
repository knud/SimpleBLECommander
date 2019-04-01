/*!
 * @file CommandsTableViewCell.h
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

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface CommandsTableViewCell : UITableViewCell

@property (nonatomic, assign) NSInteger commandID;

@end
