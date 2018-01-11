//
//  AccessPointsTableViewController.m
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-01-03.
//  Copyright © 2018 TechConficio. All rights reserved.
//

#import "AccessPointsController.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "PickerView.h"
#import "BLEDefines.h"
#import "EnvisasSupport/EnvisasAccessPointSecurity.h"

@interface AccessPointsController ()

@end

@implementation AccessPointsController

@synthesize ble;
@synthesize peripheral;
@synthesize service;

NSMutableArray<NSString *> *accessPoints;
NSMutableData *bleReceiverBuffer;
bool recStartFound = false;
bool recEndFound = false;;

bool haveTx = false;
bool haveRx = false;

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSLog(@"APC peripheral name is %@",self.peripheral.name);
  
  ble.delegate = self;
  
  bleReceiverBuffer=[[NSMutableData alloc] init];
  accessPoints = [[NSMutableArray<NSString *> alloc] init];

  UIBarButtonItem *addAPButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAcessPoint:)];
  [self navigationItem].rightBarButtonItem = addAPButton;
  [self navigationItem].title = @"Access Points";

  if (ble.activePeripheral)
  {
    if(ble.activePeripheral.state == CBPeripheralStateConnected)
    {
      NSLog(@"What? Got an active peripheral. Disconnecting...");
      [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
    } else
    {
      if (self.peripheral)
        [ble connectPeripheral:self.peripheral];
    }
  }
  
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
  ble = nil;
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
  NSLog(@"%lu rows in table",(unsigned long)[accessPoints count]);
  return [accessPoints count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSLog(@"cellforRowAt...");
  static NSString *cellIdentifier = @"APCell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
  
  if (cell == nil) {
    cell = [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:cellIdentifier];
  }
  
  NSString *ap = [accessPoints objectAtIndex:indexPath.row];
  
  [cell.textLabel setText:ap];
  [cell.detailTextLabel setText:@"could put something here..."];

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

- (IBAction)addAcessPoint:(id)sender {
  NSLog(@"addAcessPoint");

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
  if (haveTx)
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
    [self.ble write:AAPCmd];
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
        CBUUID *clientSendServiceUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_CLIENT_SEND_CHARACTERISTIC_UUID];
        CBUUID *serverSendServiceUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_SERVER_SEND_CHARACTERISTIC_UUID];
        NSArray<CBUUID *> *characteristicUUIDs = [NSArray arrayWithObjects:clientSendServiceUUID,serverSendServiceUUID, nil];
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
  CBUUID *clientSendServiceUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_CLIENT_SEND_CHARACTERISTIC_UUID];
  CBUUID *serverSendServiceUUID = [CBUUID UUIDWithString:@ENVISAS_COMMAND_SERVER_SEND_CHARACTERISTIC_UUID];
  for (int i=0; i < self.service.characteristics.count; i++)
  {
    CBCharacteristic *c = [service.characteristics objectAtIndex:i];
    NSLog(@"Found characteristic %@",c.UUID.UUIDString);
    
    if ([c.UUID.UUIDString isEqual:clientSendServiceUUID.UUIDString])
      haveTx = true;
    if ([c.UUID.UUIDString isEqual:serverSendServiceUUID.UUIDString])
      haveRx = true;
  }
  NSLog(@"SSID is %@",[self getConnectedAccessPoint]);
  
  if (haveRx)
  {
    [self.ble enableReadNotification:self.ble.activePeripheral];
  }
  
  if (haveTx)
  {
    unsigned char listAccessPointsCommand[4] = {0x20, 0x30, 0x30, 0x30};
    NSData *LAPCmd = [NSData dataWithBytes:listAccessPointsCommand length:4];
    [self.ble write:LAPCmd];
  }
}

-(void) bleDidReceiveData:(unsigned char *) data length:(int) length
{
  NSLog(@"bleDidReceiveData received %d bytes",length);
  if (!recStartFound && data[0] != '{')
  {
    // we got data without the leading JSON delimiter, so just dump it
    return;
  }
  
  if (!recStartFound && data[0] == '{')
  {
    recStartFound = true;
    recEndFound = false;
    [bleReceiverBuffer setLength:0];
    [bleReceiverBuffer appendBytes:data length:length];
  } else
    if (recStartFound)
    {
      [bleReceiverBuffer appendBytes:data length:length];
//      NSString *rec = [NSString stringWithUTF8String:[bleReceiverBuffer bytes]];
      NSString *rec  = [[NSString alloc] initWithBytes:[bleReceiverBuffer bytes] length:[bleReceiverBuffer length] encoding:NSUTF8StringEncoding];
      NSLog(@"rec length = %lu",(unsigned long)[rec length]);
      if ([rec rangeOfString:@"}"].location == NSNotFound)
        NSLog(@"} NOT FOUND");
      else
      {
        NSLog(@"} found");
        NSLog(@"rec = %@",rec);
        NSLog(@"--------------------");
        
        NSData *recData = [NSData dataWithBytes:[bleReceiverBuffer bytes] length:[bleReceiverBuffer length]];
        [self parseLAPResponse:recData];
        recStartFound = false;
      }
    }

}

- (void) parseLAPResponse:(NSData *)response
{
//  NSDictionary *lapRespDict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:response];

  NSError *error;
  NSDictionary *lapRespDict = [NSJSONSerialization JSONObjectWithData:response options:kNilOptions error:&error];
  if (error)
  {
    NSLog(@"LAP response is not JSON");
  }
  else {
    if ([NSJSONSerialization isValidJSONObject:lapRespDict])
    {
      NSLog(@"got a valid JSON object");
      NSString *name = [lapRespDict valueForKey:@"name"];
      NSLog(@"name = %@",name);
      NSArray *data = [lapRespDict valueForKey:@"data"];
      [accessPoints removeAllObjects];
      NSLog(@"data contains :");
      for (int i=0; i < [data count]; i++)
      {
        [accessPoints addObject:[data objectAtIndex:i]];
        NSLog(@"  %@",[data objectAtIndex:i]);
      }
      [self.tableView reloadData];
//      NSMutableDictionary *data = [[[lapRespDict valueForKey:@"data"] objectAtIndex:1] mutableCopy];
//      NSLog(@"description %@",data.description);
      
    }
  }
//  NSError *error;
//  NSDictionary *lapRespDict = [NSJSONSerialization JSONObjectWithData:lapRespData options:kNilOptions error:&error];
//  if (error.)
//  NSLog(@"lapRespDict has %d items",[lapRespDict count]);
//  id dataObject = [lapRespDict valueForKey:@"data"];
//  if ([dataObject isKindOfClass:[NSArray class]])
//    NSLog(@"found NSArray");
//  if ([dataObject isKindOfClass:[NSMutableArray class]])
//    NSLog(@"found NSMutableArray");
//  if ([dataObject isMemberOfClass:[NSDictionary class]])
//    NSLog(@"found NSDictionary");
//  if ([dataObject isMemberOfClass:[NSMutableDictionary class]])
//    NSLog(@"found NSMutableDictionary");
}

@end
