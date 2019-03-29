/*!
 * @file BLEUtils.h
 * @author Steven Knudsen
 * @date 2018-03-19
 * @brief Some utils for BLE.
 *
 * This file is part of the Simple BLE Commander example.
 *
 * Copyright (C) 2019 by Steven Knudsen
 *
 * This software may be modified and distributed under the terms
 * of the MIT license.  See the LICENSE file for details.
 */

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface BLEUtils : NSObject

+ (NSString *) CBUUIDToString:(CBUUID *) cbuuid;
+ (UInt16) swapBytes:(UInt16) word;
+ (BOOL) equal:(NSUUID *) UUID1 UUID2:(NSUUID *) UUID2;
+ (BOOL) equalCBUUIDs:(CBUUID *) UUID1 UUID2:(CBUUID *) UUID2;
+ (NSString *) centralManagerStateToString:(int) state;

@end

