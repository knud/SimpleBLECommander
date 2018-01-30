//
//  BagController.h
//
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-01-01.
//  Copyright © 2018 Envisas Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface BagController : UITableViewController <BLEDelegate>

- (void) scanForPeripherals;

@property (strong, nonatomic) BLE *ble;
@property (weak, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBService *service;
@property NSMutableArray* bags;

- (IBAction)refreshBags:(id)sender;

@end
