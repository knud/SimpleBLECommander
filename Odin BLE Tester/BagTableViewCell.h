//
//  BagTableViewCell.h
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-01-01.
//  Copyright © 2018 Envisas Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BagTableViewCell : UITableViewCell

@property (weak, nonatomic) CBPeripheral *peripheral;

@end
