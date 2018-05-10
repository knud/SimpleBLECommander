//
//  AccessPointsController.m
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-01-03.
//  Copyright © 2018 Envisas Inc. All rights reserved.
//

#import "AccessPointsController.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "PickerView.h"
#import "BLEDefines.h"
#import "EnvisasSupport/EnvisasAccessPointSecurity.h"
#import "EnvisasCommand.h"

@interface AccessPointsController ()
{
  NSMutableArray<NSString *> *accessPoints;
  NSMutableData *bleReceiverBuffer;
  int bleDataCount;
  bool recStartFound;
  bool recEndFound;
  bool haveCommandInvoke;
  bool haveCommandResponse;
}
@end

@implementation AccessPointsController

@synthesize ble;
@synthesize peripheral;
@synthesize service;


- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSLog(@"AccessPoints peripheral name is %@",self.peripheral.name);
  
  haveCommandInvoke = false;
  haveCommandResponse = false;

  // safe to initialize as nothing could have possibly been received yet
  recStartFound = false;
  recEndFound = false;;

  ble = [BLE sharedInstance];
  ble.delegate = self;

  bleReceiverBuffer=[[NSMutableData alloc] init];
  accessPoints = [[NSMutableArray<NSString *> alloc] init];
  
  UIBarButtonItem *addAPButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAccessPoint:)];
  [self navigationItem].rightBarButtonItem = addAPButton;
  
  CBUUID *commandServiceUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_SERVICE_UUID];
  NSArray<CBUUID *> *serviceUUIDs = [NSArray arrayWithObjects:commandServiceUUID, nil];
  NSLog(@"  calling findServicesFrom");
  [self.ble findServicesFrom:self.peripheral services:serviceUUIDs];
}

- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
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
    return @"App is connected to...";
  else
    return @"Reader Access Points";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == 0)
    return 1;
  else
  {
    NSLog(@"%lu rows in table",(unsigned long)[accessPoints count]);
    return [accessPoints count];
  }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  
  UITableViewCell *cell;
  NSString *cellIdentifier;
  if (indexPath.section == 0)
    cellIdentifier = @"phoneAPCell";
  else
    cellIdentifier = @"APCell";

  cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
  
  if (cell == nil) {
    cell = [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:cellIdentifier];
  }
  
  if (indexPath.section == 0) {
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    NSString *connectedAPName = [self getConnectedAccessPoint];
    if (connectedAPName != nil) {
      cell.imageView.image = [UIImage imageNamed:@"55-wifi-green.png"];
      label.text = connectedAPName;
    } else {
      cell.imageView.image = [UIImage imageNamed:@"55-wifi-red.png"];
      label.text = @"not connected";
    }
  }
  else {
    NSString *ap = [accessPoints objectAtIndex:indexPath.row];
    NSArray *apElements = [ap componentsSeparatedByString:@","];
    
    if ([[apElements objectAtIndex:1] caseInsensitiveCompare:@"F"] == NSOrderedSame)
      cell.imageView.image = [UIImage imageNamed:@"55-wifi-red.png"];
    else
      cell.imageView.image = [UIImage imageNamed:@"55-wifi-green.png"];
    UILabel *label;
    
    label = (UILabel *)[cell viewWithTag:1];
    label.text = [apElements objectAtIndex:0];
    
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

#pragma mark - UI actions

- (IBAction)addAccessPoint:(id)sender {
  NSLog(@"addAccessPoint");
  
  // Always present the connected access point
  NSMutableArray *ssids = [[NSMutableArray alloc] initWithObjects:[self getConnectedAccessPoint], nil];
  
  // Pretend we somehow know some other APs...
  [ssids addObject:@"fooAP"];
  [ssids addObject:@"barAP"];
  [ssids addObject:@"01234567890123456789012345678932"];
  
  [PickerView showPickerWithOptions:ssids title:@"Select Access Point" selectionBlock:^(NSString *accessPointName) {
    NSLog(@"Selected Access Point : %@",accessPointName);
    if (self.presentedViewController != nil)
      [self.presentedViewController dismissViewControllerAnimated:true completion:nil];
    [self accessPointPassword:accessPointName];
  }];
}

-(void) accessPointPassword:(NSString *) ap {
  NSString *title = [@"Password for " stringByAppendingString:ap];
  UIAlertController * alertController = [UIAlertController alertControllerWithTitle: title
                                                                            message: @"Enter Password"
                                                                     preferredStyle:UIAlertControllerStyleAlert];
  [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    textField.placeholder = @"password";
    textField.textColor = [UIColor blueColor];
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.secureTextEntry = YES;
  }];
  UIAlertAction *cancelAction = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction *action)
                                 {
                                   NSLog(@"Cancel action");
                                 }];
  UIAlertAction *okayAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    NSArray * textfields = alertController.textFields;
    UITextField * passwordfield = textfields[0];
    NSLog(@"%@",passwordfield.text);
    if ([passwordfield.text length] > 0)
      [self addReaderAP:ap password:passwordfield.text];
  }];
  
  [alertController addAction:cancelAction];
  [alertController addAction:okayAction];
  [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Access Points Support

// TODO this is not robust; purely happy path
- (NSString *) getConnectedAccessPoint
{
  CFArrayRef myArray = CNCopySupportedInterfaces();
  CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
  //  long count = CFDictionaryGetCount(myDict);
  //  NSLog(@"supported interfaces count = %ld",count);
  NSString *ssid = CFDictionaryGetValue(myDict, kCNNetworkInfoKeySSID);
  //  NSLog(@"connected SSID is %@",ssid);
  return ssid;
}

- (void) addReaderAP:(NSString *) ap password:(NSString *) password {
  if (haveCommandInvoke)
  {
    // +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
    // | 0x21 | 097     | home | ssid | auth | pwd                           |
    // +------+---------+----------------------------------------------------+
    // | 1 B  | 3 C     | 1 B  | 32 B | 1 B  | 63 B                          |
    // +------+---------+----------------------------------------------------+
    //
    // home is not true (i.e, not set to 1)
    // Arg Len is encoded as decimal ascii
    //
    unsigned char addAccessPointCommand[5] = {0x21, 0x30, 0x36, 0x31, 0xFF};
    NSMutableData *AAPCmd = [NSMutableData dataWithBytes:addAccessPointCommand length:sizeof(addAccessPointCommand)];
    // since the ap string was selected using APs detected by the device, they cannot be too long (> 32 chars)
    unsigned long padding = 32 - [ap length];
    NSLog(@"padding is %lu blanks",padding);
    if (padding > 0) {
      NSString *temp = [[NSString string] stringByPaddingToLength:padding withString:@" " startingAtIndex:0];
      ap = [ap stringByAppendingString:temp];
    }
    NSData *apData = [ap dataUsingEncoding:NSUTF8StringEncoding];
    //    apData = [apData subdataWithRange:NSMakeRange(0, [apData length] - 1)];
    [AAPCmd appendData:apData];
    NSLog(@"AAPCmd length is %lu",(unsigned long)[AAPCmd length]);
    
    uint8_t auth[1] = {ENVISAS_ACCESS_POINT_SECURITY_WPA2_MIXED_PSK};
    [AAPCmd appendBytes:auth length:1];
    NSLog(@"AAPCmd length is %lu",(unsigned long)[AAPCmd length]);
    
    padding = 63 - [password length];
    NSLog(@"padding is %lu blanks",padding);
    if (padding > 0) {
      NSString *temp = [[NSString string] stringByPaddingToLength:padding withString:@" " startingAtIndex:0];
      password = [password stringByAppendingString:temp];
    }
    [AAPCmd appendData:[password dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"AAPCmd length is %lu",(unsigned long)[AAPCmd length]);
    uint8_t *dataBytes = (uint8_t *)[AAPCmd bytes];
    for (int i = 0; i < [AAPCmd length]; i++)
      printf("%02x\n",dataBytes[i]);
    CBUUID *uuid = [CBUUID UUIDWithString:@ENVISAS_COMMAND_INVOKE_CHARACTERISTIC_UUID];
    [self.ble write:AAPCmd toUUID:uuid];
  }
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

      EnvisasCommand * listAPsCommand = [[EnvisasCommand alloc] initWith:LIST_ACCESS_POINTS argument:NULL error:NULL];
      NSArray<NSString *> *commandStrings = [listAPsCommand commandStrings];
//      EnvisasCommand * readerStatusCommand = [[EnvisasCommand alloc] initWith:READER_STATUS argument:NULL error:NULL];
//      NSArray<NSString *> *commandStrings = [readerStatusCommand commandStrings];
      

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
      
      // check for access points list
      if ([name compare:@"access_points"] == 0) {
        // the access points are in a JSON array
        NSObject *value = [respDict valueForKey:@"data"];
        if (value != nil && value != [NSNull null]) {
          if ([value isKindOfClass:[NSArray class]])
          {
            NSArray *data = (NSArray *) value;
            [accessPoints removeAllObjects];
            NSLog(@"data contains :");
            for (int i=0; i < [data count]; i++)
            {
              [accessPoints addObject:[data objectAtIndex:i]];
              NSLog(@"  %@",[data objectAtIndex:i]);
            }
            [self.tableView reloadData];
          } // if array
        }
      } // name is "access_points"
      
    }
  }
}

@end
