/*!
 * @file CommandResultController.h
 * @author Steven Knudsen
 * @date 2018-04-01
 * @brief The BLE command controller command result controller.
 *
 * This file is part of the Simple BLE Commander example.
 *
 * Copyright (C) 2019 by Steven Knudsen
 *
 * This software may be modified and distributed under the terms
 * of the MIT license.  See the LICENSE file for details.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CommandResultController : UITableViewController

@property (strong, nonatomic) NSString *commandName;
@property (strong, nonatomic) NSString *commandResult;

@end

NS_ASSUME_NONNULL_END
