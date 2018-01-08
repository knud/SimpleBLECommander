//
//  ConfigurationControllerTableViewController.m
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-01-01.
//  Copyright © 2018 TechConficio. All rights reserved.
//

#import "BagController.h"
#import "BagTableViewCell.h"
#import "BLEDefines.h"

#import "AccessPointsController.h"

@interface BagController ()

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
  CBUUID *serviceUUID = [CBUUID UUIDWithString:serviceUUIDStr];
  self.targetPeripheralServices = [NSArray arrayWithObjects:serviceUUID, nil];
  self.scanningForPeripherals = false;
  self.currentPeripheral = -1;

  busyBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:nil action:nil];
  activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [busyBarButton setCustomView:activityIndicator];

  [self.navigationItem.rightBarButtonItem setCustomView:activityIndicator];
  refreshBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshBags:)];
  [self navigationItem].rightBarButtonItem = refreshBarButton;
  [self.navigationItem.rightBarButtonItem setEnabled:false];

  
  ble = [[BLE alloc] init];
  [ble controlSetup];
  ble.delegate = self;
  
  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;
  
  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) viewWillAppear:(BOOL)animated
{
  ble.delegate = self;
}
- (void)didReceiveMemoryWarning {
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


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSLog(@"cellForRowAtIndexPath");

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
  
  return cell;
}


 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
   if ([[segue identifier] isEqualToString:@"accessPointsSegue"]) {
     NSLog(@"[BagController] accessPointsSegue ");
     // Get the new view controller using [segue destinationViewController].
     AccessPointsController *apc = [segue destinationViewController];
     
     BagTableViewCell *cell = (BagTableViewCell *) sender;
     
     [apc setBle:self.ble];
     [apc setPeripheral:cell.peripheral];
     if (ble.activePeripheral)
       if(ble.activePeripheral.state == CBPeripheralStateConnected)
         [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
   }
 // Pass the selected object to the new view controller.
 }

#pragma mark - UI actions

- (IBAction)refreshBags:(id)sender {
  NSLog(@"refreshBags");
  [self navigationItem].rightBarButtonItem = busyBarButton;

  [self.bags removeAllObjects];
  [activityIndicator startAnimating];

  [self scanForPeripherals];
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

#pragma mark - BLE actions

- (void) scanForPeripherals
{
  self.scanningForPeripherals = true;
  if (ble.activePeripheral)
    if(ble.activePeripheral.state == CBPeripheralStateConnected)
    {
      [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
      return;
    }
  
  if (ble.peripherals)
    ble.peripherals = nil;

  [ble findBLEPeripherals:2];
  
  [NSTimer scheduledTimerWithTimeInterval:(float)2.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
  
}

-(void) connectionTimer:(NSTimer *)timer
{

  NSLog(@"connectionTimer");
  // reset the right bar button
  [activityIndicator stopAnimating];
  [self navigationItem].rightBarButtonItem = refreshBarButton;

  if (ble.peripherals.count > 0) {
    self.currentPeripheral = 0;

    // connect and check each peripheral for our services
    [ble connectPeripheral:[ble.peripherals objectAtIndex:self.currentPeripheral]];
//    NSLog(@"reload data");
//    [self.tableView reloadData];
  } else {
  }
}

#pragma mark - BLE delegate

// When connected, this will be called
-(void) bleDidConnect
{
  NSLog(@"->Connected");
//  NSArray<CBService *> *services = [[ble.peripherals objectAtIndex:0] services];
//  NSLog(@"found %lu services",(unsigned long)services.count);

  if (self.currentPeripheral >= 0)
    [ble findServicesFrom:[ble.peripherals objectAtIndex:self.currentPeripheral] services:self.targetPeripheralServices];
//  // send reset
//  UInt8 buf[] = {0x04, 0x00, 0x00};
//  NSData *data = [[NSData alloc] initWithBytes:buf length:3];
//  [ble write:data];
  
  // Schedule to read RSSI every 1 sec.
//  rssiTimer = [NSTimer scheduledTimerWithTimeInterval:(float)1.0 target:self selector:@selector(readRSSITimer:) userInfo:nil repeats:YES];
}

NSTimer *rssiTimer;

- (void)bleDidDisconnect
{
  NSLog(@"->Disconnected");
  
  if (self.scanningForPeripherals) {
    self.scanningForPeripherals = false;
    [self scanForPeripherals];
  }

  if (self.currentPeripheral < ble.peripherals.count)
  {
    NSLog(@"current peripheral %ld",(long)self.currentPeripheral);
    [ble connectPeripheral:[ble.peripherals objectAtIndex:self.currentPeripheral]];
  } else
    self.currentPeripheral = -1;

  // TODO need this?
//  [rssiTimer invalidate];
}

// When RSSI is changed, this will be called
-(void) bleDidUpdateRSSI:(NSNumber *) rssi
{
//  lblRSSI.text = rssi.stringValue;
}

-(void) readRSSITimer:(NSTimer *)timer
{
  [ble readRSSI];
}

// When data is comming, this will be called
-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
  NSLog(@"Length: %d", length);
  
  // parse data, all commands are in 3-byte
//  for (int i = 0; i < length; i+=3)
//  {
//    NSLog(@"0x%02X, 0x%02X, 0x%02X", data[i], data[i+1], data[i+2]);
//
//    if (data[i] == 0x0A)
//    {
//      if (data[i+1] == 0x01)
//        swDigitalIn.on = true;
//      else
//        swDigitalIn.on = false;
//    }
//    else if (data[i] == 0x0B)
//    {
//      UInt16 Value;
//
//      Value = data[i+2] | data[i+1] << 8;
//      lblAnalogIn.text = [NSString stringWithFormat:@"%d", Value];
//    }
//  }
}

-(void) bleServicesFound;
{
  if (self.currentPeripheral >= 0)
  {
    CBPeripheral *p = [ble.peripherals objectAtIndex:self.currentPeripheral];
    if (p.services)
    {
      long numServices = [p.services count];
      NSLog(@"%ld services found", numServices);
      if (p.services.count > 0)
      {
        [self.bags addObject:p];
        [self.tableView reloadData];
      }
    }
    // check the next peripheral
    self.currentPeripheral++;
    if (ble.activePeripheral)
      if(ble.activePeripheral.state == CBPeripheralStateConnected)
        [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
  }
}

-(void) bleFindPeripheralsFinished
{
  self.scanningForPeripherals = false;
}

@end
