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
  bool seguedToCommandResult;
  
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
  
  // use this to keep from disconnecting the peripheral
  seguedToCommandResult = false;
  
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
  CommandsTableViewCell *cc = (CommandsTableViewCell *) cell;
  [self invokeCommand:indexPath.row];
//  [self performSegueWithIdentifier:@"commandSegue" sender:cell];
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
//  if ([[segue identifier] isEqualToString:@"commandsSegue"]) {
//    // Get the new view controller using [segue destinationViewController].
//    CommandsController *commandsController = [segue destinationViewController];
//
//    PeripheralsTableViewCell *cell = (PeripheralsTableViewCell *) sender;
//
//    [commandsController setPeripheral:cell.peripheral];
//
//    // Paranoia. Should never be connected.
//    if (ble.activePeripheral)
//      if(ble.activePeripheral.state == CBPeripheralStateConnected)
//        [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
//  }
}


#pragma mark - UI Action

- (void)invokeCommand:(NSInteger)index {
  //  CBUUID *commandServiceUUID = [CBUUID UUIDWithString:@SIMPLE_COMMAND_SERVICE_UUID];
  //  NSArray<CBUUID *> *serviceUUIDs = [NSArray arrayWithObjects:commandServiceUUID, nil];
  //  [self.ble findServicesFrom:self.peripheral services:serviceUUIDs];
  //      // enable notification for this characteristic on the peripheral
  //      [self.ble.activePeripheral setNotifyValue:YES forCharacteristic:c];

  SimpleCommand * command = [commands objectAtIndex:index];
  NSData *commandData = [command bleFormat];

  [self.navigationItem.backBarButtonItem setEnabled:NO];
  //
  // Provide mechanism failure to return data
  // TODO replace hard-coded seconds above and below with proper programmtic value
//  [NSTimer scheduledTimerWithTimeInterval:(float)12.0 target:self selector:@selector(commandTimer:) userInfo:nil repeats:NO];
  
  
  CBUUID *uuid = [CBUUID UUIDWithString:@SIMPLE_COMMAND_INVOKE_CHARACTERISTIC_UUID];
//  NSData *cmdData = [commandString dataUsingEncoding:NSUTF8StringEncoding];
//  NSLog(@"commandString = %@",commandString);
  [self.ble write:commandData toUUID:uuid];
  
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//  if ([[segue identifier] isEqualToString:@"configurationSegue"]) {
//    NSLog(@"[CommandsController] configurationSegue ");
//    // Get the new view controller using [segue destinationViewController].
//    ConfigurationController *cc = [segue destinationViewController];
//    seguedToCommandResult = true;
//    [cc setPeripheral:self.peripheral];
//  }
//}
//
#pragma mark - UI actions

- (IBAction)configure:(id)sender {
  NSLog(@"configure");
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

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
    
    // TODO should probably check that notifying worked before sending commands
    if ([c.UUID.UUIDString isEqual:commandInvokeCharacteristicUUID.UUIDString])
    {
      NSLog(@"Invoke characterisitc");
      
      //      // enable notification for this characteristic on the peripheral
      //      [self.ble.activePeripheral setNotifyValue:YES forCharacteristic:c];
      
      // We need a list of commands, so issue an inventory command
      // TODO replace hard-coded seconds above and below with proper programmtic value
      //      EnvisasCommand * inventoryCommand = [[EnvisasCommand alloc] initWith:INVENTORY argument:@"010" error:NULL];
      //      NSArray<NSString *> *commandStrings = [inventoryCommand commandStrings];
      //
      //      [self.navigationItem.backBarButtonItem setEnabled:NO];
      //
      // Provide mechanism failure to return data
      // TODO replace hard-coded seconds above and below with proper programmtic value
      //      [NSTimer scheduledTimerWithTimeInterval:(float)12.0 target:self selector:@selector(commandTimer:) userInfo:nil repeats:NO];
      //
      
      // TODO could move this into a method to handle command strings?
      //      CBUUID *uuid = [CBUUID UUIDWithString:@SIMPLE_COMMAND_INVOKE_CHARACTERISTIC_UUID];
      //      for (int i = 0; i < [commandStrings count]; i++) {
      //        NSString *cmdStr = [commandStrings objectAtIndex:i];
      //        NSData *cmdData = [cmdStr dataUsingEncoding:NSUTF8StringEncoding];
      //        NSLog(@"cmdStr = %@",cmdStr);
      //        [self.ble write:cmdData toUUID:uuid];
      //        /*[NSThread sleepForTimeInterval:0.05];*/
      //      }
    }
  }
}

-(void) commandTimer:(NSTimer *)timer
{
//  [invokeCommandControl endRefreshing];
  // reset the right bar button
  [self.navigationController.navigationItem.backBarButtonItem setEnabled:YES];
}

-(void) bleHaveDataFor:(CBCharacteristic *)characteristic
{
  // paranoid check
  if (characteristic.value) {
    if ([characteristic.value length] > 0)
    {
      if (!dataAvailable) {
        NSString *cv = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"bleHaveDataFor received %@",cv);
        NSRange prefixRange = [cv rangeOfString:@"dataAvailable" options:(NSAnchoredSearch | NSCaseInsensitiveSearch)];
        if (prefixRange.length > 0) {
          // new data is available
          NSString *countStr = [cv substringFromIndex:(prefixRange.length+1)];
          NSLog(@"countStr %@",countStr);
          [bleReceiverBuffer setLength:0];
          bleDataCount = [countStr intValue];
          // ask for some data
          //                  [self.ble.activePeripheral readValueForCharacteristic:characteristic];
        }
        dataAvailable = true;
        //        [self.ble.activePeripheral readValueForCharacteristic:characteristic];
      } else {
        NSString *cv = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"bleHaveDataFor received %ld bytes",[characteristic.value length]);
        NSLog(@"bleHaveDataFor received %@",cv);
        //        [bleReceiverBuffer setLength:0];
        [bleReceiverBuffer appendData:characteristic.value];
        NSLog(@" --------- received %lu bytes",(unsigned long)[bleReceiverBuffer length]);
        bleDataCount -= [characteristic.value length];
        if (bleDataCount <= 0) {
          NSLog(@"got all data");
          [self parseResponse:bleReceiverBuffer];
          [self.navigationController.navigationItem.backBarButtonItem setEnabled:YES];
          dataAvailable = false;
        }
      }
      //      if (bleDataCount <= 0) {
      //        NSString *cv = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
      //        NSLog(@"bleHaveDataFor received %@",cv);
      //        NSRange prefixRange = [cv rangeOfString:@"dataAvailable" options:(NSAnchoredSearch | NSCaseInsensitiveSearch)];
      //        if (prefixRange.length > 0) {
      //          // new data is available
      //          NSString *countStr = [cv substringFromIndex:(prefixRange.length+1)];
      //          NSLog(@"countStr %@",countStr);
      //          [bleReceiverBuffer setLength:0];
      //          bleDataCount = [countStr intValue];
      //          // ask for some data
      //          [self.ble.activePeripheral readValueForCharacteristic:characteristic];
      //        }
      //      } else {
      //        [bleReceiverBuffer appendData:characteristic.value];
      //        bleDataCount -= [characteristic.value length];
      //
      //        if (bleDataCount > 0) {
      //          // ask for more data
      //          [self.ble.activePeripheral readValueForCharacteristic:characteristic];
      //        } else {
      //          NSLog(@" --------- received %lu bytes",(unsigned long)[bleReceiverBuffer length]);
      //          [self parseResponse:bleReceiverBuffer];
      //          [scanContentsControl endRefreshing];
      //          [self.navigationController.navigationItem.backBarButtonItem setEnabled:YES];
      //        }
      //      }
    }
  }
}

// TODO Yes, I know that hard coding the key strings is a no-no, but we are maintaining
// API definitions between two different code bases and there is not much motivation
// to make it better when my iOS examples are throw-away
- (void) parseResponse:(NSData *)response
{
  // We expect 3 JSON messages in the response, so have to first carve them out
  NSData * commandResponse;
  NSData * commandEnd;
  NSData * commandResult;
  
  NSString *temp = [[NSString alloc] initWithData:bleReceiverBuffer encoding:NSUTF8StringEncoding];
  NSLog(@" temp string = %@",temp);
  // Each message returned by the reader, command response, command end, and command result,
  // has as it's last KV pair the coreid. The "data" part of the message may contain a JSON
  // string, so we have to ignore it, which is done by skipping to the coreid KV
  NSString *startStr = @"{\"name";
  NSString *lastKVStr = @"coreid";
  NSString *endStr = @"\"}";
  NSRange currentRange = {0, [temp length]};
  for (int jsonMsgs = 0; jsonMsgs < 1; jsonMsgs++) {
    // find the start of the JSON message
    NSRange startRange = [temp rangeOfString:startStr options:NSLiteralSearch range:currentRange];
    NSLog(@"name range %lu %lu",(unsigned long)startRange.location,(unsigned long)startRange.length);
    if (startRange.length <= 0) {
      NSLog(@"Parse error; no starting {\"name");
      return;
    }
    currentRange.location = startRange.location + startRange.length;
    currentRange.length = [temp length] - currentRange.location;
    
    // find the "coreid" key
    NSRange coreidRange = [temp rangeOfString:lastKVStr options:NSLiteralSearch range:currentRange];
    NSLog(@"core id range %lu %lu",(unsigned long)coreidRange.location,(unsigned long)coreidRange.length);
    if (coreidRange.length <= 0) {
      NSLog(@"Parse error; no closing coreid key");
      return;
    }
    currentRange.location = coreidRange.location + coreidRange.length;
    currentRange.length = [temp length] - currentRange.location;
    
    // finally, find the end of the JSON message
    NSRange endRange = [temp rangeOfString:endStr options:NSLiteralSearch range:currentRange];
    NSLog(@"end range %lu %lu",(unsigned long)endRange.location,(unsigned long)endRange.length);
    if (endRange.length <= 0) {
      NSLog(@"Parse error; no closing }");
      return;
    }
    currentRange.location = endRange.location + endRange.length;
    currentRange.length = [temp length] - currentRange.location;
    // grab the data
    NSRange subDataRange = {startRange.location, endRange.location + endRange.length - startRange.location};
    NSData *tempData = [response subdataWithRange:subDataRange];
    NSLog(@"subDataRange = %ld len %ld",subDataRange.location, subDataRange.length);
    if (jsonMsgs == 0) commandResponse = [NSData dataWithData:tempData];
    if (jsonMsgs == 1) commandEnd = [NSData dataWithData:tempData];
    if (jsonMsgs == 2) commandResult = [NSData dataWithData:tempData];
  }
  
  // TODO for now, check only the response data
  // TODO should probably refactor this method
  NSError *error;
  NSDictionary *respDict = [NSJSONSerialization JSONObjectWithData:commandResponse options:kNilOptions error:&error];
  if (error)
  {
    NSLog(@"response is not JSON");
    if ([error code] == NSPropertyListReadCorruptError)
      NSLog(@"Error code is NSPropertyListReadCorruptError");
  }
  else {
    if ([NSJSONSerialization isValidJSONObject:respDict])
    {
      NSLog(@"got a valid JSON object");
      // "name" key always refers to a string, so no need to check
      NSString *name = [respDict valueForKey:@"name"];
      NSLog(@"name = %@",name);
      
      // check for commands list
      if ([name compare:@"inventory"] == 0) {
        // inventory messages are either JSON arrays or strings
        NSObject *value = [respDict valueForKey:@"data"];
        if (value != nil && value != [NSNull null]) {
          if ([value isKindOfClass:[NSString class]])
          {
            NSString *invString = (NSString *) value;
            NSLog(@"invString = %@",invString);
            NSData *dataData = [invString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:dataData options:kNilOptions error:&error];
            if (error)
            {
              NSLog(@"data is not JSON");
              if ([error code] == NSPropertyListReadCorruptError)
                NSLog(@"Error code is NSPropertyListReadCorruptError");
            }
            NSLog(@"data is JSON");
            NSObject *commandsValue = [dataDict valueForKey:@"commands"];
            if (commandsValue != nil && commandsValue != [NSNull null]) {
              NSLog(@"check for commands");
              if ([commandsValue isKindOfClass:[NSArray class]])
              {
                NSLog(@"commands parses to commands array");
                NSArray *data = (NSArray *) commandsValue;
                [commands removeAllObjects];
                NSLog(@"data contains %d commands:",[data count]);
                for (int i=0; i < [data count]; i++)
                {
                  [commands addObject:[data objectAtIndex:i]];
                  NSLog(@"  %@",[data objectAtIndex:i]);
                }
                [self.tableView reloadData];
              }
            }
            //            if ([invString componentsSeparatedByString:@"end"] == 0)
            //            {
            //              NSLog(@"No more commands...");
            //              return;
            //            }
          }
          //          NSLog(@"check for array");
          //          if ([value isKindOfClass:[NSArray class]])
          //          {
          //            NSLog(@"commands parses to array");
          //            NSArray *data = (NSArray *) value;
          //            [commands removeAllObjects];
          //            NSLog(@"data contains :");
          //            for (int i=0; i < [data count]; i++)
          //            {
          //              [commands addObject:[data objectAtIndex:i]];
          //              NSLog(@"  %@",[data objectAtIndex:i]);
          //            }
          //            [self.tableView reloadData];
          //          } // if array
        }
      } // name is "inventory"
      
    }
  }
}

@end
