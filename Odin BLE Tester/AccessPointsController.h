//
//  AccessPointsTableViewController.h
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-01-03.
//  Copyright © 2018 Envisas Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface AccessPointsController : UITableViewController <BLEDelegate>

@property (weak, nonatomic) BLE *ble;
@property (weak, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBService *service;

@end
