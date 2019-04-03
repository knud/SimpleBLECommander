/*!
 * @file CommandsController.m
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

#import "CommandsController.h"
#import "CommandsTableViewCell.h"
#import "CommandResultController.h"
#import "BLEDefines.h"
#import "SimpleCommand.h"

@interface CommandsController ()
{
  NSMutableArray<SimpleCommand *> *commands;
  NSMutableData *bleReceiverBuffer;
  int bleDataCount;
  bool dataAvailable;
  bool recStartFound;
  bool recEndFound;
  // use this to keep from disconnecting the peripheral
  bool seguedToCommandResult;

  CommandsTableViewCell *currentCommandCell;
}
@end

@implementation CommandsController

@synthesize ble;
@synthesize peripheral;
@synthesize service;


- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSLog(@"CommandsController using peripheral %@",self.peripheral.name);
  
  // safe to initialize as nothing could have possibly been received yet
  recStartFound = false;
  recEndFound = false;
  
  currentCommandCell = nil;
  
  ble = [BLE sharedInstance];
  ble.delegate = self;
  
  bleReceiverBuffer=[[NSMutableData alloc] init];
  bleDataCount = 0;
  dataAvailable = false;
  
  // set up the commands
  commands = [[NSMutableArray<SimpleCommand *> alloc] init];
 
  [commands addObject:[[SimpleCommand alloc] initWith:NO_COMMAND argument:@"000" error:NULL]];
  [commands addObject:[[SimpleCommand alloc] initWith:FAST_BLINK argument:@"000" error:NULL]];
  [commands addObject:[[SimpleCommand alloc] initWith:SLOW_BLINK argument:@"000" error:NULL]];
  [commands addObject:[[SimpleCommand alloc] initWith:ALT_BLINK argument:@"000" error:NULL]];
  [commands addObject:[[SimpleCommand alloc] initWith:OFF argument:@"000" error:NULL]];
  [commands addObject:[[SimpleCommand alloc] initWith:ABORT argument:@"000" error:NULL]];
  
  [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
  if (self.peripheral)
    [ble connectPeripheral:self.peripheral];
}

- (void) viewWillAppear:(BOOL)animated
{
  ble.delegate = self;
  seguedToCommandResult = false;
}

- (void) viewDidDisappear:(BOOL)animated
{
  if (ble.activePeripheral)
  {
    if(ble.activePeripheral.state == CBPeripheralStateConnected && !seguedToCommandResult)
    {
      NSLog(@"Disconnecting peripheral...");
      [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
    }
  }
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
  return [commands count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  currentCommandCell = (CommandsTableViewCell *) cell;
  [self invokeCommand:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSString *cellIdentifier = @"CommandCell";
  
  CommandsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
  
  if (cell == nil) {
    cell = [[CommandsTableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:cellIdentifier];
  }
  SimpleCommand *cmd = [commands objectAtIndex:indexPath.row];
  
  [cell.textLabel setText:cmd->name];
  [cell.detailTextLabel setText:@""];
  [cell setCommandID:indexPath.row];

  return cell;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"commandResultSegue"]) {
    seguedToCommandResult = true;

    // Get the new view controller using [segue destinationViewController].
    CommandResultController *commandsController = [segue destinationViewController];
    [commandsController setCommandName:[[currentCommandCell textLabel] text] ];
    NSString *result = [[NSString alloc] initWithData:bleReceiverBuffer encoding:NSUTF8StringEncoding];
    NSLog(@"bleReceiveBuffer command result %@",result);
    [commandsController setCommandResult:result ];
  }
}



#pragma mark - UI Action

- (void)invokeCommand:(NSInteger)index {

  SimpleCommand * command = [commands objectAtIndex:index];
  NSData *commandData = [command bleFormat];

  [self.navigationItem.backBarButtonItem setEnabled:NO];
  
  CBUUID *uuid = [CBUUID UUIDWithString:@SIMPLE_COMMAND_INVOKE_CHARACTERISTIC_UUID];

  [self.ble write:commandData toUUID:uuid];
}

#pragma mark - BLE delegate

// When connected, this will be called
-(void) bleDidConnect
{
  NSLog(@"->Connected");
  
  CBUUID *commandServiceUUID = [CBUUID UUIDWithString:@SIMPLE_COMMAND_SERVICE_UUID];
  NSArray<CBUUID *> *serviceUUIDs = [NSArray arrayWithObjects:commandServiceUUID, nil];
  [self.ble findServicesFrom:self.peripheral services:serviceUUIDs];
}

- (void)bleDidDisconnect
{
  NSLog(@"->Disconnected");
}

-(void) bleServicesFound;
{
  NSLog(@"->bleServicesFound");
  if (self.ble.activePeripheral)
  {
    if (self.ble.activePeripheral.services)
    {
      unsigned long numServices = [self.ble.activePeripheral.services count];
      NSLog(@" %lu services found for %@",numServices,self.ble.activePeripheral.name);
      CBUUID *commandServiceUUID = [CBUUID UUIDWithString:@SIMPLE_COMMAND_SERVICE_UUID];
      for (int i = 0; i < numServices; i++)
      {
        CBService *s = [self.ble.activePeripheral.services objectAtIndex:i];
        NSLog(@"\t service UUID %@",s.UUID.UUIDString);
        if ([s.UUID.UUIDString isEqual:commandServiceUUID.UUIDString])
        {
          self.service = s;
          CBUUID *commandSpareCharacteristicUUID = [CBUUID UUIDWithString:@SIMPLE_COMMAND_SPARE_CHARACTERISTIC_UUID];
          CBUUID *commandInvokeCharacteristicUUID = [CBUUID UUIDWithString:@SIMPLE_COMMAND_INVOKE_CHARACTERISTIC_UUID];
          CBUUID *commandResponseCharacteristicUUID = [CBUUID UUIDWithString:@SIMPLE_COMMAND_RESPONSE_CHARACTERISTIC_UUID];
          NSArray<CBUUID *> *characteristicUUIDs = [NSArray arrayWithObjects:commandSpareCharacteristicUUID,commandInvokeCharacteristicUUID,commandResponseCharacteristicUUID, nil];
          NSLog(@"  ->findCharacteristicsFrom");
          [self.ble findCharacteristicsFrom:self.peripheral characteristicUUIDs:(NSArray<CBUUID *> *)characteristicUUIDs];
          return;
        }
      }
    }
  }
}

-(void) bleServiceCharacteristicsFound
{
  NSLog(@"->bleServiceCharacteristicsFound");
  CBUUID *commandSpareCharacteristicUUID = [CBUUID UUIDWithString:@SIMPLE_COMMAND_SPARE_CHARACTERISTIC_UUID];
  CBUUID *commandInvokeCharacteristicUUID = [CBUUID UUIDWithString:@SIMPLE_COMMAND_INVOKE_CHARACTERISTIC_UUID];
  CBUUID *commandResponseCharacteristicUUID = [CBUUID UUIDWithString:@SIMPLE_COMMAND_RESPONSE_CHARACTERISTIC_UUID];
  for (int i=0; i < self.service.characteristics.count; i++)
  {
    CBCharacteristic *c = [service.characteristics objectAtIndex:i];
    NSLog(@"Found characteristic %@",c.UUID.UUIDString);
    if (c.properties & CBCharacteristicPropertyRead)
      printf("  has read\n");
    if (c.properties & CBCharacteristicPropertyWrite)
      printf("  has write\n");
    if (c.properties & CBCharacteristicPropertyWriteWithoutResponse)
      printf("  has write without response\n");
    if (c.properties & CBCharacteristicPropertyNotify)
      printf("  has notify\n");
    if (c.properties & CBCharacteristicPropertyIndicate)
      printf("  has indicate\n");
    if (c.properties & CBCharacteristicPropertyBroadcast)
      printf("  has broadcast\n");
    if (c.properties & CBCharacteristicPropertyExtendedProperties)
      printf("  has extended properties\n");
    if (c.properties & CBCharacteristicPropertyNotifyEncryptionRequired)
      printf("  has notify encryption requires\n");
    if (c.properties & CBCharacteristicPropertyIndicateEncryptionRequired)
      printf("  has indicate encryption required\n");
    if (c.properties & CBCharacteristicPropertyAuthenticatedSignedWrites)
      printf("  has authenticated signed writes\n");
    
    // Ignore the spare for now...
    if ([c.UUID.UUIDString isEqual:commandSpareCharacteristicUUID.UUIDString]) {
      NSLog(@"Spare characterisitc");
    }
    
    if ([c.UUID.UUIDString isEqual:commandResponseCharacteristicUUID.UUIDString])
    {
      NSLog(@"Response characterisitc");
      // enable notification for this characteristic on the peripheral
      [self.ble.activePeripheral setNotifyValue:YES forCharacteristic:c];
    }
    
    if ([c.UUID.UUIDString isEqual:commandInvokeCharacteristicUUID.UUIDString])
    {
      NSLog(@"Invoke characterisitc");
    }
  }
}

-(void) commandTimer:(NSTimer *)timer
{
  // reset the right bar button
  [self.navigationController.navigationItem.backBarButtonItem setEnabled:YES];
}

-(void) bleHaveDataFor:(CBCharacteristic *)characteristic
{
  // paranoid check
  if (characteristic.value) {
    if ([characteristic.value length] > 0)
    {

      // Either get the first chunk of data that will indicate how much is to follow,
      // or keep adding to the receive buffer until all the expected data has arrived.
      // TODO should have a timeout in case the data transfer is interrupted or otherwise
      // fails.
      if (!dataAvailable) {
        NSString *cv = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"bleHaveDataFor received %@",cv);
        NSRange prefixRange = [cv rangeOfString:@"dataAvailable" options:(NSAnchoredSearch | NSCaseInsensitiveSearch)];
        if (prefixRange.length > 0) {
          // new data is available
          NSString *countStr = [cv substringFromIndex:(prefixRange.length+1)];
          [bleReceiverBuffer setLength:0];
          bleDataCount = [countStr intValue];
        }
        dataAvailable = true;
      } else {
        NSString *cv = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"bleHaveDataFor received %ld bytes",(unsigned long)[characteristic.value length]);
        NSLog(@"bleHaveDataFor received %@",cv);
        [bleReceiverBuffer appendData:characteristic.value];
        NSLog(@" --------- received %lu bytes",(unsigned long)[bleReceiverBuffer length]);
        bleDataCount -= [characteristic.value length];
        if (bleDataCount <= 0) {
          NSLog(@"got all data");
          [self.navigationController.navigationItem.backBarButtonItem setEnabled:YES];
          dataAvailable = false;
          // prep for segue to response screen and segue
          [self performSegueWithIdentifier:@"commandResultSegue" sender:currentCommandCell];
        }
      }
    }
  }
}

@end
