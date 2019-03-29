/*!
 * @file CommandsController.h
 * @author Steven Knudsen
 * @date 2018-03-19
 * @brief The BLE command controller commands controller.
 *
 * This file is part of the Simple BLE Commander example.
 *
 * Copyright (C) 2019 by Steven Knudsen
 *
 * This software may be modified and distributed under the terms
 * of the MIT license.  See the LICENSE file for details.
 */

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface CommandsController : UITableViewController <BLEDelegate>

@property (weak, nonatomic) BLE *ble;
@property (weak, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBService *service;

@end
