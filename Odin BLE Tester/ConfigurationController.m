//
//  AccessPointsTableViewController.m
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-01-03.
//  Copyright © 2018 Envisas Inc. All rights reserved.
//

#import "ConfigurationController.h"
#import "AccessPointsController.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "PickerView.h"
#import "BLEDefines.h"
#import "EnvisasSupport/EnvisasAccessPointSecurity.h"
#import "EnvisasCommand.h"

@interface ConfigurationController ()
{
  NSMutableData *bleReceiverBuffer;
  int bleDataCount;
  bool recStartFound;
  bool recEndFound;
  bool haveCommandInvoke;
  bool haveCommandResponse;
  NSUInteger uptime;
  bool externalPower;
  NSUInteger lastSession;
  NSUInteger batteryLevel;
  NSUInteger timeUntilCharge;
}
@end

@implementation ConfigurationController

@synthesize ble;
@synthesize peripheral;
@synthesize service;


- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSLog(@"Configuration peripheral name is %@",self.peripheral.name);
  
  haveCommandInvoke = false;
  haveCommandResponse = false;

  uptime = 0;
  externalPower = false;
  lastSession = 0;
  batteryLevel = 0;
  timeUntilCharge = 0;

  // safe to initialize as nothing could have possibly been received yet
  recStartFound = false;
  recEndFound = false;;

  ble = [BLE sharedInstance];
  ble.delegate = self;

  bleReceiverBuffer=[[NSMutableData alloc] init];

  CBUUID *commandServiceUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_SERVICE_UUID];
  NSArray<CBUUID *> *serviceUUIDs = [NSArray arrayWithObjects:commandServiceUUID, nil];
  NSLog(@"  calling findServicesFrom");
  [self.ble findServicesFrom:self.peripheral services:serviceUUIDs];
}

- (void) viewDidDisappear:(BOOL)animated
{
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  if (section == 0)
    return @"Status";
  else
    return @"Internet Connection";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == 0)
    return 3;
  else
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  
  UITableViewCell *cell;
  NSString *cellIdentifier;
  
  if (indexPath.section == 0)
    cellIdentifier = @"StatusCell";
  else
    cellIdentifier = @"APCell";

  cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
  
  if (cell == nil) {
    cell = [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:cellIdentifier];
  }
  
//  NSString *ap = [accessPoints objectAtIndex:indexPath.row];
  
  if (indexPath.section == 0) {
    // status section
//    uptime = 0;
//    externalPower = false;
//    lastSession = 0;
//    batteryLevel = 0;
//    timeUntilCharge = 0;
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    if (indexPath.row == 0) {
      if (externalPower)
        cell.imageView.image = [UIImage imageNamed:@"battery_charge.png"];
      else {
        if (batteryLevel > 95)
          cell.imageView.image = [UIImage imageNamed:@"battery_full.png"];
        else if (batteryLevel > 50)
          cell.imageView.image = [UIImage imageNamed:@"battery_half.png"];
        else
          cell.imageView.image = [UIImage imageNamed:@"battery_low.png"];
      }
      label.text = [NSString stringWithFormat:@"%lu%%",(unsigned long) batteryLevel];
    }
    if (indexPath.row == 1) {
      if (externalPower) {
        cell.imageView.image = [UIImage imageNamed:@"396-power-plug.png"];
        label.text = @"External Power";
      }
      else {
        cell.imageView.image = [UIImage imageNamed:@"49-battery.png"];
        label.text = @"Battery";
      }
    }
    if (indexPath.row == 2) {
      cell.imageView.image = [UIImage imageNamed:@"310-alarm-clock.png"];
      label.text = @"Last session : 2 hours ago";
    }
  }
  else {
    // access point section
    cell.imageView.image = [UIImage imageNamed:@"55-wifi.png"];
    UILabel *label;
    
    label = (UILabel *)[cell viewWithTag:1];
    label.text = @"ubnt";
  }
  return cell;
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
#pragma mark - UI actions
*/
 #pragma mark - Navigation
 
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"accessPointsSegue"]) {
    NSLog(@"[ConfigurationController] accessPointsSegue ");
    // Get the new view controller using [segue destinationViewController].
    AccessPointsController *apc = [segue destinationViewController];
    [apc setPeripheral:self.peripheral];
  }
}


#pragma mark - BLE delegate

// When connected, this will be called
-(void) bleDidConnect
{
  NSLog(@"->Connected");
  
  CBUUID *commandServiceUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_SERVICE_UUID];
  NSArray<CBUUID *> *serviceUUIDs = [NSArray arrayWithObjects:commandServiceUUID, nil];
  NSLog(@"  calling findServicesFrom");
  [self.ble findServicesFrom:self.peripheral services:serviceUUIDs];
  
}

- (void)bleDidDisconnect
{
  NSLog(@"->Disconnected. Connecting to proper peripheral");
  if (self.peripheral)
    [ble connectPeripheral:self.peripheral];
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
      CBUUID *commandServiceUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_SERVICE_UUID];
      for (int i = 0; i < numServices; i++)
      {
        CBService *s = [self.ble.activePeripheral.services objectAtIndex:i];
        NSLog(@"\t service UUID %@",s.UUID.UUIDString);
        if ([s.UUID.UUIDString isEqual:commandServiceUUID.UUIDString])
        {
          self.service = s;
          CBUUID *commandSpareCharacteristicUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_SPARE_CHARACTERISTIC_UUID];
          CBUUID *commandInvokeCharacteristicUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_INVOKE_CHARACTERISTIC_UUID];
          CBUUID *commandResponseCharacteristicUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_RESPONSE_CHARACTERISTIC_UUID];
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
  CBUUID *commandSpareCharacteristicUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_SPARE_CHARACTERISTIC_UUID];
  CBUUID *commandInvokeCharacteristicUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_INVOKE_CHARACTERISTIC_UUID];
  CBUUID *commandResponseCharacteristicUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_RESPONSE_CHARACTERISTIC_UUID];
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
    if ([c.UUID.UUIDString isEqual:commandSpareCharacteristicUUID.UUIDString]) {}
    
    if ([c.UUID.UUIDString isEqual:commandInvokeCharacteristicUUID.UUIDString]) {
      haveCommandInvoke = true;
      [self.ble.activePeripheral setNotifyValue:YES forCharacteristic:c];
      
      EnvisasCommand * readerStatusCommand = [[EnvisasCommand alloc] initWith:READER_STATUS argument:NULL error:NULL];
      NSArray<NSString *> *commandStrings = [readerStatusCommand commandStrings];
      
      
      for (int i = 0; i < [commandStrings count]; i++) {
        NSString *cmdStr = [commandStrings objectAtIndex:i];
        NSData *cmdData = [cmdStr dataUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"cmdStr = %@",cmdStr);
        CBUUID *uuid = [CBUUID UUIDWithString:@ENVISAS_COMMAND_INVOKE_CHARACTERISTIC_UUID];
        [self.ble write:cmdData toUUID:uuid];
      }
    }
    if ([c.UUID.UUIDString isEqual:commandResponseCharacteristicUUID.UUIDString])
    {
      haveCommandResponse = true;
      [self.ble.activePeripheral setNotifyValue:YES forCharacteristic:c];
    }
  }
}

-(void) bleHaveDataFor:(CBCharacteristic *)characteristic
{
  // paranoid check
  if (characteristic.value) {
    if ([characteristic.value length] > 0)
    {
      if (bleDataCount <= 0) {
        NSString *cv = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        //        NSLog(@"bleHaveDataFor received %@",cv);
        NSRange prefixRange = [cv rangeOfString:@"dataAvailable" options:(NSAnchoredSearch | NSCaseInsensitiveSearch)];
        if (prefixRange.length > 0) {
          // new data is available
          NSString *countStr = [cv substringFromIndex:(prefixRange.length+1)];
          NSLog(@"countStr %@",countStr);
          [bleReceiverBuffer setLength:0];
          bleDataCount = [countStr intValue];
          // ask for some data
          [self.ble.activePeripheral readValueForCharacteristic:characteristic];
        }
      } else {
        [bleReceiverBuffer appendData:characteristic.value];
        bleDataCount -= [characteristic.value length];
        
        if (bleDataCount > 0) {
          // ask for more data
          [self.ble.activePeripheral readValueForCharacteristic:characteristic];
        } else {
          NSLog(@" --------- received %lu bytes",(unsigned long)[bleReceiverBuffer length]);
          NSString *resp = [[NSString alloc] initWithData:bleReceiverBuffer encoding:NSUTF8StringEncoding];
          NSLog(@"bleReceiveBuffer : %@",resp);
          [self parseResponse:bleReceiverBuffer];
        }
      }
    }
  }
}

// TODO Yes, I know that hard coding the key strings is a no-no, but we are maintaining
// API definitions between two different code bases and there is not much motivation
// to make it better when my iOS examples are throw-away
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
  // Each message returned by the reader, command response, command end, and command result,
  // has as it's last KV pair the coreid. The "data" part of the message may contain a JSON
  // string, so we have to ignore it, which is done by skipping to the coreid KV
  NSString *startStr = @"{\"name";
  NSString *lastKVStr = @"coreid";
  NSString *endStr = @"\"}";
  NSRange currentRange = {0, [temp length]};
  for (int jsonMsgs = 0; jsonMsgs < 3; jsonMsgs++) {
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
      
      if ([name compare:@"reader_status"] == 0) {
        // inventory messages are either JSON arrays or strings
        NSObject *value = [respDict valueForKey:@"data"];
        if (value != nil && value != [NSNull null]) {
          
          if ([value isKindOfClass:[NSDictionary class]]) {
            NSLog(@"status is NSDictionary");
//            NSString *dataStr = [respDict valueForKey:@"data"];
            NSDictionary *dataDict = [respDict valueForKey:@"data"];
            if ([NSJSONSerialization isValidJSONObject:respDict]) {
              NSLog(@"data is a dictionary");
              NSString *temp = [dataDict valueForKey:@"uptime"];
              uptime = [temp integerValue];
              temp = [dataDict valueForKey:@"externalpower"];
              if ([temp caseInsensitiveCompare:@"yes"] == NSOrderedSame)
                externalPower = true;
              else
                externalPower = false;
              temp = [dataDict valueForKey:@"lastsession"];
              lastSession = [temp integerValue];
              temp = [dataDict valueForKey:@"batterylevel"];
              batteryLevel = [temp integerValue];
              temp = [dataDict valueForKey:@"timeuntilcharge"];
              timeUntilCharge = [temp integerValue];
              [self.tableView reloadData];
            }
          }
        }
      } // name is "reader_status"
      
    }
  }
}

@end
