//
//  AccessPointsTableViewController.m
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-01-03.
//  Copyright © 2018 TechConficio. All rights reserved.
//

#import "AccessPointsController.h"
#import <SystemConfiguration/CaptiveNetwork.h>


#import "BLEDefines.h"

@interface AccessPointsController ()

@end

@implementation AccessPointsController

@synthesize ble;
@synthesize peripheral;
@synthesize service;
@synthesize accessPoints;

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
  return [accessPoints count];
}

/*
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
 
 // Configure the cell...
 
 return cell;
 }
 */

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
      NSString *rec = [NSString stringWithUTF8String:[bleReceiverBuffer bytes]];
      if ([rec rangeOfString:@"}"].location == NSNotFound)
        NSLog(@"} NOT FOUND");
      else
      {
        NSLog(@"} found");
        NSLog(@"rec = %@",rec);
        [self parseLAPResponse:rec];
      }
    }

}

- (void) parseLAPResponse:(NSString *)response
{
  
}

@end
