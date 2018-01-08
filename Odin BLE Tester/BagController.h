//
//  ConfigurationControllerTableViewController.h
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-01-01.
//  Copyright © 2018 TechConficio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface BagController : UITableViewController <BLEDelegate>
{
  UIActivityIndicatorView *activityIndicator;
  UIBarButtonItem *refreshBarButton;
  UIBarButtonItem *busyBarButton;
}

- (void) scanForPeripherals;



@property (strong, nonatomic) BLE *ble;
@property NSMutableArray* bags;
@property NSArray<CBUUID *> *targetPeripheralServices;
@property NSInteger currentPeripheral;

@property bool scanningForPeripherals;

- (IBAction)refreshBags:(id)sender;

@end
