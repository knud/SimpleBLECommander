//
//  BagContentsController.m
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-01-21.
//  Copyright © 2018 Envisas Inc. All rights reserved.
//

#import "BagContentsController.h"
#import "BLEDefines.h"
#import "EnvisasCommand.h"

@interface BagContentsController ()
{
  UIActivityIndicatorView *bagScanningIndicator;
  NSMutableArray<NSString *> *tags;
  NSMutableData *bleReceiverBuffer;
  int bleDataCount;
  bool recStartFound;
  bool recEndFound;
}
@end

@implementation BagContentsController

@synthesize ble;
@synthesize peripheral;
@synthesize service;


- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSLog(@"BagContentsController using peripheral %@",self.peripheral.name);
  
  // safe to initialize as nothing could have possibly been received yet
  recStartFound = false;
  recEndFound = false;;
  
  ble = [BLE sharedInstance];
  ble.delegate = self;
  
  bleReceiverBuffer=[[NSMutableData alloc] init];
  bleDataCount = 0;
  tags = [[NSMutableArray<NSString *> alloc] init];
  
  UIImage *configImage = [UIImage imageNamed:@"spanner.png"];
  UIBarButtonItem *configButton = [[UIBarButtonItem alloc] initWithImage:configImage style:UIBarButtonItemStylePlain target:self action:@selector(configure:)];
  [self navigationItem].rightBarButtonItem = configButton;
  
  UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Previous" style:UIBarButtonItemStylePlain target:nil action:nil];
  [self navigationItem].backBarButtonItem = backButtonItem;
  
  bagScanningIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  bagScanningIndicator.frame = CGRectMake(0.0, 0.0, 80.0, 80.0);
  bagScanningIndicator.center = self.view.center;
  [self.view addSubview:bagScanningIndicator];
  [bagScanningIndicator bringSubviewToFront:self.view];
  
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
    if(ble.activePeripheral.state == CBPeripheralStateConnected)
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
  return [tags count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  static NSString *cellIdentifier = @"BagContentsCell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
  
  if (cell == nil) {
    cell = [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:cellIdentifier];
  }
  
  NSString *tagName = [tags objectAtIndex:indexPath.row];
  
  [cell.textLabel setText:tagName];
  [cell.detailTextLabel setText:@"could put something here..."];
  
  return cell;
}

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
  
  CBUUID *commandServiceUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_SERVICE_UUID];
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
    
    if ([c.UUID.UUIDString isEqual:commandInvokeCharacteristicUUID.UUIDString])
    {
      // enable notification for this characteristic on the peripheral
      [self.ble.activePeripheral setNotifyValue:YES forCharacteristic:c];
      
      // We need a list of tags, so issue an inventory command
      EnvisasCommand * inventoryCommand = [[EnvisasCommand alloc] initWith:INVENTORY argument:@"010" error:NULL];
      NSArray<NSString *> *commandStrings = [inventoryCommand commandStrings];
      
      //    EnvisasCommand * listAPsCommand = [[EnvisasCommand alloc] initWith:LIST_ACCESS_POINTS argument:NULL error:NULL];
      //    NSArray<NSString *> *commandStrings = [listAPsCommand commandStrings];

      [bagScanningIndicator startAnimating];
//      [self.navigationController.navigationItem.backBarButtonItem setEnabled:NO];
      [self.navigationItem.backBarButtonItem setEnabled:NO];
      // TODO replace 11 and 10 above with proper programmtic value
      [NSTimer scheduledTimerWithTimeInterval:(float)11.0 target:self selector:@selector(bagScanningTimer:) userInfo:nil repeats:NO];

      
      // TODO could move this into a method to handle command strings?
      CBUUID *uuid = [CBUUID UUIDWithString:@ENVISAS_COMMAND_INVOKE_CHARACTERISTIC_UUID];
      for (int i = 0; i < [commandStrings count]; i++) {
        NSString *cmdStr = [commandStrings objectAtIndex:i];
        NSData *cmdData = [cmdStr dataUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"cmdStr = %@",cmdStr);
        [self.ble write:cmdData toUUID:uuid];
//        [NSThread sleepForTimeInterval:0.05];
      }
    }
    if ([c.UUID.UUIDString isEqual:commandResponseCharacteristicUUID.UUIDString])
    {
      // enable notification for this characteristic on the peripheral
      [self.ble.activePeripheral setNotifyValue:YES forCharacteristic:c];
    }
  }
}

-(void) bagScanningTimer:(NSTimer *)timer
{
  // reset the right bar button
  [bagScanningIndicator stopAnimating];
  [self.navigationController.navigationItem.backBarButtonItem setEnabled:YES];
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
        //        NSLog(@"bleHaveDataFor received %lu bytes",[characteristic.value length]);
        [bleReceiverBuffer appendData:characteristic.value];
        bleDataCount -= [characteristic.value length];
        //        const char * rxBytes = [characteristic.value bytes];
        //        for (int i = 0; i < [characteristic.value length]; i++)
        //        {
        //          printf("%c",rxBytes[i]);
        //        }
        //        printf("\n\n");
        
        if (bleDataCount > 0) {
          // ask for more data
          [self.ble.activePeripheral readValueForCharacteristic:characteristic];
        } else {
          NSLog(@" --------- received %lu bytes",(unsigned long)[bleReceiverBuffer length]);
          [self parseResponse:bleReceiverBuffer];
          [bagScanningIndicator stopAnimating];
          [self.navigationController.navigationItem.backBarButtonItem setEnabled:YES];
        }
      }
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
  // TODO parse the data!
  NSString *startStr = @"{\"name";
  NSString *endStr = @"\"}";
  NSRange currentRange = {0, [temp length]};
  for (int jsonMsgs = 0; jsonMsgs < 3; jsonMsgs++) {
    NSRange startRange = [temp rangeOfString:startStr options:NSLiteralSearch range:currentRange];
    NSLog(@"range %lu %lu",(unsigned long)startRange.location,(unsigned long)startRange.length);
    if (startRange.length <= 0) {
      NSLog(@"Parse error; no starting {\"name");
      return;
    }
    currentRange.location = startRange.location + startRange.length;
    currentRange.length = [temp length] - currentRange.location;
    NSRange endRange = [temp rangeOfString:endStr options:NSLiteralSearch range:currentRange];
    NSLog(@"range %lu %lu",(unsigned long)endRange.location,(unsigned long)endRange.length);
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
    NSLog(@"LAP response is not JSON");
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
      
      // check for tags list
      if ([name compare:@"inventory"] == 0) {
        // inventory messages are either JSON arrays or strings
        NSObject *value = [respDict valueForKey:@"data"];
        if (value != nil && value != [NSNull null]) {
          if ([value isKindOfClass:[NSString class]])
          {
            NSString *invString = (NSString *) value;
            NSLog(@"invString = %@",invString);
            if ([invString componentsSeparatedByString:@"end"] == 0)
            {
              NSLog(@"No more tags...");
              return;
            }
          }
          if ([value isKindOfClass:[NSArray class]])
          {
            NSArray *data = (NSArray *) value;
            [tags removeAllObjects];
            NSLog(@"data contains :");
            for (int i=0; i < [data count]; i++)
            {
              [tags addObject:[data objectAtIndex:i]];
              NSLog(@"  %@",[data objectAtIndex:i]);
            }
            [self.tableView reloadData];
          } // if array
        }
      } // name is "inventory"
      else {
        // check for command_result
        if ([name compare:@"command_result"] == 0) {
          NSString *result = [respDict valueForKey:@"data"];
          if (result) {
            NSLog(@"command_result = %@",result);
          } else {
            NSLog(@"Bad command_result");
          }
        }
      } // name is not "inventory"
      
    }
  }
}

@end
