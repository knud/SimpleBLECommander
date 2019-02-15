//
//  BagController.m
//
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-01-01.
//  Copyright © 2018 Envisas Inc. All rights reserved.
//

#import "BagController.h"
#import "BagTableViewCell.h"
#import "BLEDefines.h"

#import "BagContentsController.h"

@interface BagController ()
{
  CBUUID *targetPeripheralService;
  bool scanningForPeripherals;
  UIActivityIndicatorView *activityIndicator;
  UIBarButtonItem *refreshBarButton;
  UIBarButtonItem *busyBarButton;
}

@end

@implementation BagController

@synthesize ble;

- (void)viewDidLoad {
  [super viewDidLoad];

  // "bags" are just the peripherals we find and display in the table.
  self.bags = [[NSMutableArray alloc] init];

  // Make a list of services that a peripheral has to have for us to care.
  // Only have the one to date...
  NSString *serviceUUIDStr = @ENVISAS_COMMAND_SERVICE_UUID;
  targetPeripheralService = [CBUUID UUIDWithString:serviceUUIDStr];
  scanningForPeripherals = false;

  busyBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:nil action:nil];
  activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [busyBarButton setCustomView:activityIndicator];

  [self.navigationItem.rightBarButtonItem setCustomView:activityIndicator];
  refreshBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshBags:)];
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
  return [self.bags count];
}

// TODO placeholder. Might do somthing interesting later...
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellIdentifier = @"BagCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
  
  if (cell == nil) {
    cell = [[BagTableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:cellIdentifier];
  }

  // Configure the cell...

  CBPeripheral *peripheral = [self.bags objectAtIndex:indexPath.row];
  
  [cell.textLabel setText:peripheral.name];
  [cell.detailTextLabel setText:[peripheral.identifier UUIDString]];
  BagTableViewCell *bcell = (BagTableViewCell *) cell;
  [bcell setPeripheral:peripheral];
  if(scanningForPeripherals) {
    [bcell setUserInteractionEnabled:NO];
  } else {
    [bcell setUserInteractionEnabled:YES];
  }

  return cell;
}


 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
   if ([[segue identifier] isEqualToString:@"bagContentsSegue"]) {
     NSLog(@"[BagController] bagContentsSegue ");
     // Get the new view controller using [segue destinationViewController].
     BagContentsController *bcc = [segue destinationViewController];
     
     BagTableViewCell *cell = (BagTableViewCell *) sender;
     
     [bcc setPeripheral:cell.peripheral];

     // Paranoia. Should never be connected.
     if (ble.activePeripheral)
       if(ble.activePeripheral.state == CBPeripheralStateConnected)
         [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
   }
 }

#pragma mark - UI actions

- (IBAction)refreshBags:(id)sender {
  NSLog(@"refreshBags");
  [self navigationItem].rightBarButtonItem = busyBarButton;

  [self.bags removeAllObjects];
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
  
  [self.bags removeAllObjects];
  [self.tableView reloadData];

  [ble findPeripherals:4];
  
  [NSTimer scheduledTimerWithTimeInterval:(float)6.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
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
          [self.bags addObject:p];
          [self.tableView reloadData];
        }
      }
    }
  }
}

// When connected, this will be called
//-(void) bleDidConnect
//{
//}

- (void)bleDidDisconnect
{
  NSLog(@"->Disconnected");
}

// When RSSI is changed, this will be called
//-(void) bleDidUpdateRSSI:(NSNumber *) rssi
//{
//}

//-(void) readRSSITimer:(NSTimer *)timer
//{
//  [ble readRSSI];
//}

@end
