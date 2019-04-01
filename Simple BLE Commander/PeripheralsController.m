/*!
 * @file PeripheralsController.m
 * @author Steven Knudsen
 * @date 2018-03-19
 * @brief The BLE command controller peripherals controller.
 *
 * This file is part of the Simple BLE Commander example.
 *
 * Copyright (C) 2019 by Steven Knudsen
 *
 * This software may be modified and distributed under the terms
 * of the MIT license.  See the LICENSE file for details.
 */

#import "PeripheralsController.h"
#import "PeripheralsTableViewCell.h"
#import "CommandsController.h"
#import "BLEDefines.h"

@interface PeripheralsController ()
{
  CBUUID *targetPeripheralService;
  bool scanningForPeripherals;
  UIActivityIndicatorView *activityIndicator;
  UIBarButtonItem *refreshBarButton;
  UIBarButtonItem *busyBarButton;
}

@end

@implementation PeripheralsController

@synthesize ble;

- (void)viewDidLoad {
  [super viewDidLoad];

  // "peripherals" are just the peripherals we find and display in the table.
  self.peripherals = [[NSMutableArray alloc] init];

  // Make a list of services that a peripheral has to have for us to care.
  // Only have the one to date...
  NSString *serviceUUIDStr = @SIMPLE_COMMAND_SERVICE_UUID;
  targetPeripheralService = [CBUUID UUIDWithString:serviceUUIDStr];
  scanningForPeripherals = false;

  busyBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:nil action:nil];
  activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [busyBarButton setCustomView:activityIndicator];

  [self.navigationItem.rightBarButtonItem setCustomView:activityIndicator];
  refreshBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshPeripherals:)];
  [self navigationItem].rightBarButtonItem = refreshBarButton;
  [self.navigationItem.rightBarButtonItem setEnabled:false];
  
  ble = [BLE sharedInstance];
  ble.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated
{
  ble.delegate = self;
}

- (void) viewWillDisappear:(BOOL)animated
{
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.peripherals count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  [self performSegueWithIdentifier:@"commandsSegue" sender:cell];
}

//- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(nonnull NSIndexPath *)indexPath
//{
//  NSLog(@"table cell accessory selected");
//  //  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellIdentifier = @"PeripheralCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
  
  if (cell == nil) {
    cell = [[PeripheralsTableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:cellIdentifier];
  }

  // Configure the cell...

  CBPeripheral *peripheral = [self.peripherals objectAtIndex:indexPath.row];
  
  [cell.textLabel setText:peripheral.name];
  [cell.detailTextLabel setText:[peripheral.identifier UUIDString]];
  PeripheralsTableViewCell *pc = (PeripheralsTableViewCell *) cell;
  [pc setPeripheral:peripheral];
  if(scanningForPeripherals) {
    [pc setUserInteractionEnabled:NO];
  } else {
    [pc setUserInteractionEnabled:YES];
  }

  return cell;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"commandsSegue"]) {
    // Get the new view controller using [segue destinationViewController].
    CommandsController *commandsController = [segue destinationViewController];
    
    PeripheralsTableViewCell *cell = (PeripheralsTableViewCell *) sender;
    
    [commandsController setPeripheral:cell.peripheral];
    
    // Paranoia. Should never be connected.
    if (ble.activePeripheral)
      if(ble.activePeripheral.state == CBPeripheralStateConnected)
        [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
  }
}

#pragma mark - UI actions

- (IBAction)refreshPeripherals:(id)sender {
  [self navigationItem].rightBarButtonItem = busyBarButton;

  [self.peripherals removeAllObjects];
  [activityIndicator startAnimating];

  [self scanForPeripherals];
}

#pragma mark - BLE actions

- (void) scanForPeripherals
{
  scanningForPeripherals = true;
  if (ble.activePeripheral)
    if(ble.activePeripheral.state == CBPeripheralStateConnected)
    {
      [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
      return;
    }
  
  if (ble.peripherals)
    ble.peripherals = nil;
  
  [self.peripherals removeAllObjects];
  [self.tableView reloadData];

  [ble findPeripherals:2];
  
  [NSTimer scheduledTimerWithTimeInterval:(float)2.5 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
}

-(void) connectionTimer:(NSTimer *)timer
{
  // reset the right bar button
  [activityIndicator stopAnimating];
  [self navigationItem].rightBarButtonItem = refreshBarButton;
  scanningForPeripherals = false;
  [self.tableView reloadData];
}

#pragma mark - BLE delegate methods

-(void) bleCentralManagerStateChanged:(CBManagerState) state
{
  switch(state)
  {
    case CBManagerStateUnsupported:
      NSLog(@"The platform/hardware doesn't support Bluetooth Low Energy.");
      break;
    case CBManagerStateUnauthorized:
      NSLog(@"The app is not authorized to use Bluetooth Low Energy.");
      break;
    case CBManagerStatePoweredOff:
      NSLog(@"Bluetooth is currently powered off.");
      [self.navigationItem.rightBarButtonItem setEnabled:false];
      break;
    case CBManagerStatePoweredOn:
      NSLog(@"Bluetooth is currently powered on.");
      [self.navigationItem.rightBarButtonItem setEnabled:true];
      break;
    case CBManagerStateUnknown:
      NSLog(@"Bluetooth manager unknown state.");
    default:
      break;
  }
}

-(void) bleFindPeripheralsFinished
{
  
  if (self.ble.peripherals) {
    for (int i = 0; i < [self.ble.peripherals count]; i++) {
      CBPeripheral *p = [self.ble.peripherals objectAtIndex:i];
      NSDictionary *ad = [self.ble.advertisingData objectAtIndex:i];
      NSString *deviceName = [ad valueForKey:CBAdvertisementDataLocalNameKey];
      if (deviceName)
      {
        if (([deviceName compare:@BLE_DEVICE_NAME1] == NSOrderedSame) ||
            ([deviceName compare:@BLE_DEVICE_NAME2] == NSOrderedSame) ) {
          NSLog(@"Got peripheral %@",deviceName);
          self.peripheral = p;
          [self.peripherals addObject:p];
          [self.tableView reloadData];
        }
      }
    }
  }
}

// When connected, this will be called
-(void) bleDidConnect
{
}

- (void)bleDidDisconnect
{
  NSLog(@"->Disconnected");
}

// When RSSI is changed, this will be called
-(void) bleDidUpdateRSSI:(NSNumber *) rssi
{
}

//-(void) readRSSITimer:(NSTimer *)timer
//{
//  [ble readRSSI];
//}

@end
