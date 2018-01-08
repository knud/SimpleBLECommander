
/*
 
 Copyright (c) 2013 RedBearLab
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "BLE.h"
#import "BLEDefines.h"

@implementation BLE

@synthesize delegate;
@synthesize CM;
@synthesize peripherals;
@synthesize activePeripheral;

static bool isConnected = false;
static int rssi = 0;

-(void) readRSSI
{
  [activePeripheral readRSSI];
}

-(BOOL) isConnected
{
  return isConnected;
}

-(void) read
{
  CBUUID *uuid_service = [CBUUID UUIDWithString:@ENVISAS_COMMAND_SERVICE_UUID];
  CBUUID *uuid_char = [CBUUID UUIDWithString:@ENVISAS_COMMAND_SERVER_SEND_CHARACTERISTIC_UUID];
  
  [self readValue:uuid_service characteristicUUID:uuid_char p:activePeripheral];
}

-(void) write:(NSData *)d
{
  CBUUID *uuid_service = [CBUUID UUIDWithString:@ENVISAS_COMMAND_SERVICE_UUID];
  CBUUID *uuid_char = [CBUUID UUIDWithString:@ENVISAS_COMMAND_CLIENT_SEND_CHARACTERISTIC_UUID];
  
  [self writeValue:uuid_service characteristicUUID:uuid_char p:activePeripheral data:d];
}

-(void) enableReadNotification:(CBPeripheral *)p
{
  CBUUID *uuid_service = [CBUUID UUIDWithString:@ENVISAS_COMMAND_SERVICE_UUID];
  CBUUID *uuid_char = [CBUUID UUIDWithString:@ENVISAS_COMMAND_SERVER_SEND_CHARACTERISTIC_UUID];
  
  [self notification:uuid_service characteristicUUID:uuid_char p:p on:YES];
}

-(void) notification:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on
{
  CBService *service = [self findServiceBy:serviceUUID peripheral:p];

  if (!service)
  {
    NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
          [self CBUUIDToString:serviceUUID],
          p.identifier.UUIDString);
    
    return;
  }
  
  CBCharacteristic *characteristic = [self findCharacteristicBy:characteristicUUID service:service];
  
  if (!characteristic)
  {
    NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
          [self CBUUIDToString:characteristicUUID],
          [self CBUUIDToString:serviceUUID],
          p.identifier.UUIDString);
    
    return;
  }
  
  [p setNotifyValue:on forCharacteristic:characteristic];
}

-(UInt16) frameworkVersion
{
  return RBL_BLE_FRAMEWORK_VER;
}

-(NSString *) CBUUIDToString:(CBUUID *) cbuuid;
{
  NSData *data = cbuuid.data;
  
  if ([data length] == 2)
  {
    const unsigned char *tokenBytes = [data bytes];
    return [NSString stringWithFormat:@"%02x%02x", tokenBytes[0], tokenBytes[1]];
  }
  else if ([data length] == 16)
  {
    NSUUID* nsuuid = [[NSUUID alloc] initWithUUIDBytes:[data bytes]];
    return [nsuuid UUIDString];
  }
  
  return [cbuuid description];
}

-(void) readValue: (CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p
{
  CBService *service = [self findServiceBy:serviceUUID peripheral:p];
  
  if (!service)
  {
    NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
          [self CBUUIDToString:serviceUUID],
          p.identifier.UUIDString);
    
    return;
  }
  
  CBCharacteristic *characteristic = [self findCharacteristicBy:characteristicUUID service:service];
  
  if (!characteristic)
  {
    NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
          [self CBUUIDToString:characteristicUUID],
          [self CBUUIDToString:serviceUUID],
          p.identifier.UUIDString);
    
    return;
  }
  
  [p readValueForCharacteristic:characteristic];
}

-(void) writeValue:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data
{
  CBService *service = [self findServiceBy:serviceUUID peripheral:p];
  
  if (!service)
  {
    NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
          [self CBUUIDToString:serviceUUID],
          p.identifier.UUIDString);
    
    return;
  }
  
  CBCharacteristic *characteristic = [self findCharacteristicBy:characteristicUUID service:service];
  
  if (!characteristic)
  {
    NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
          [self CBUUIDToString:characteristicUUID],
          [self CBUUIDToString:serviceUUID],
          p.identifier.UUIDString);
    
    return;
  }
  
  [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
}

-(UInt16) swap:(UInt16)s
{
  UInt16 temp = s << 8;
  temp |= (s >> 8);
  return temp;
}

- (void) controlSetup
{
  self.CM = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (int) findBLEPeripherals:(int) timeout
{
  if (self.CM.state != CBManagerStatePoweredOn)
  {
    NSLog(@"CoreBluetooth not correctly initialized !");
    NSLog(@"State = %ld (%s)\r\n", (long) self.CM.state, [self centralManagerStateToString:self.CM.state]);
    return -1;
  }
  
  [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
  
  // set up find peripherals that provide specified service(s)
  // TODO seems to be broken currently, so find any peripheral and then filter in the delegate
#if 0
  NSString *serviceUUIDStr = @ENVISAS_COMMAND_SERVICE_UUID;
  CBUUID *serviceUUID = [CBUUID UUIDWithString:serviceUUIDStr];
  NSArray<CBUUID *> *services = [NSArray arrayWithObjects:serviceUUIDStr, nil];
#if TARGET_OS_IPHONE
  [self.CM scanForPeripheralsWithServices:services options:nil];
#else
  [self.CM scanForPeripheralsWithServices:nil options:nil]; // Start scanning
#endif
#else
  [self.CM scanForPeripheralsWithServices:nil options:nil]; // Start scanning
#endif
  
  NSLog(@"scanForPeripheralsWithServices");
  
  return 0; // Started scanning OK !
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
{
  [[self delegate] bleDidDisconnect];
  
  isConnected = false;
}

- (void) connectPeripheral:(CBPeripheral *)peripheral
{
  NSLog(@"Connecting to peripheral with UUID : %@", peripheral.identifier.UUIDString);
  
  self.activePeripheral = peripheral;
  self.activePeripheral.delegate = self;
  [self.CM connectPeripheral:self.activePeripheral
                     options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

- (const char *) centralManagerStateToString: (int)state
{
  switch(state)
  {
    case CBManagerStateUnknown:
      return "State unknown (CBManagerStateUnknown)";
    case CBManagerStateResetting:
      return "State resetting (CBManagerStateResetting)";
    case CBManagerStateUnsupported:
      return "State BLE unsupported (CBManagerStateUnsupported)";
    case CBManagerStateUnauthorized:
      return "State unauthorized (CBManagerStateUnauthorized)";
    case CBManagerStatePoweredOff:
      return "State BLE powered off (CBManagerStatePoweredOff)";
    case CBManagerStatePoweredOn:
      return "State powered up and ready (CBManagerStatePoweredOn)";
    default:
      return "State unknown";
  }
  
  return "State unknown";
}

- (void) scanTimer:(NSTimer *)timer
{
  [self.CM stopScan];
  NSLog(@"Stopped Scanning");
  NSLog(@"Known peripherals : %lu", (unsigned long)[self.peripherals count]);
  [self printKnownPeripherals];
  [[self delegate] bleFindPeripheralsFinished];
}

- (void) printKnownPeripherals
{
  NSLog(@"List of currently known peripherals :");
  
  for (int i = 0; i < self.peripherals.count; i++)
  {
    CBPeripheral *p = [self.peripherals objectAtIndex:i];
    
    if (p.identifier != NULL)
      NSLog(@"%d  |  %@", i, p.identifier.UUIDString);
    else
      NSLog(@"%d  |  NULL", i);
    
    [self printPeripheralInfo:p];
  }
}

- (void) printPeripheralInfo:(CBPeripheral*)peripheral
{
  NSLog(@"------------------------------------");
  NSLog(@"Peripheral Info :");
  
  if (peripheral.identifier != NULL)
    NSLog(@"UUID : %@", peripheral.identifier.UUIDString);
  else
    NSLog(@"UUID : NULL");

  NSLog(@"Name : %@", peripheral.name);
  NSLog(@"-------------------------------------");
}

- (BOOL) UUIDSAreEqual:(NSUUID *)UUID1 UUID2:(NSUUID *)UUID2
{
  if ([UUID1.UUIDString isEqualToString:UUID2.UUIDString])
    return TRUE;
  else
    return FALSE;
}

// services can be nil, in which case all services are found
-(void) findServicesFrom:(CBPeripheral *) peripheral services:(NSArray<CBUUID *> *)services;
{
  NSLog(@"findServicesFrom: ");
  [peripheral discoverServices:services];
}

-(void) findCharacteristicsFrom:(CBPeripheral *) peripheral characteristicUUIDs:(NSArray<CBUUID *> *)characteristicUUIDs;
{
  if (peripheral.services)
  {
    unsigned long numServices = [peripheral.services count];
    NSLog(@"findCharacteristicsFrom services count %lu",numServices);
  for (int i=0; i < peripheral.services.count; i++)
  {
    CBService *s = [peripheral.services objectAtIndex:i];
    [peripheral discoverCharacteristics:characteristicUUIDs forService:s];
  }
  }
}

-(CBService *) findServiceBy:(CBUUID *)UUID peripheral:(CBPeripheral *)peripheral;
{
  for(int i = 0; i < peripheral.services.count; i++)
  {
    CBService *s = [peripheral.services objectAtIndex:i];
    if ([self compareCBUUID:s.UUID UUID2:UUID])
      return s;
  }
  return nil;
}

-(CBCharacteristic *) findCharacteristicBy:(CBUUID *)UUID service:(CBService*)service;
{
  for(int i=0; i < service.characteristics.count; i++)
  {
    CBCharacteristic *c = [service.characteristics objectAtIndex:i];
    if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
  }
  return nil;
}


-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2
{
  char b1[16];
  char b2[16];
  [UUID1.data getBytes:b1 length:UUID1.data.length];
  [UUID2.data getBytes:b2 length:UUID2.data.length];
  
  if (memcmp(b1, b2, UUID1.data.length) == 0)
    return 1;
  else
    return 0;
}

-(int) compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2
{
  char b1[16];
  
  [UUID1.data getBytes:b1 length:UUID1.data.length];
  UInt16 b2 = [self swap:UUID2];
  
  if (memcmp(b1, (char *)&b2, 2) == 0)
    return 1;
  else
    return 0;
}

-(UInt16) CBUUIDToInt:(CBUUID *) UUID
{
  char b1[16];
  [UUID.data getBytes:b1 length:UUID.data.length];
  return ((b1[0] << 8) | b1[1]);
}

-(CBUUID *) IntToCBUUID:(UInt16)UUID
{
  char t[16];
  t[0] = ((UUID >> 8) & 0xff); t[1] = (UUID & 0xff);
  NSData *data = [[NSData alloc] initWithBytes:t length:16];
  return [CBUUID UUIDWithData:data];
}

#if TARGET_OS_IPHONE
//-- no need for iOS
#else
- (BOOL) isLECapableHardware
{
  NSString * state = nil;
  
  switch ([CM state])
  {
    case CBManagerStateUnsupported:
      state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
      break;
      
    case CBManagerStateUnauthorized:
      state = @"The app is not authorized to use Bluetooth Low Energy.";
      break;
      
    case CBManagerStatePoweredOff:
      state = @"Bluetooth is currently powered off.";
      break;
      
    case CBManagerStatePoweredOn:
      return TRUE;
      
    case CBManagerStateUnknown:
    default:
      return FALSE;      
  }

  NSLog(@"Central manager state: %@", state);
  
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:state];
  [alert addButtonWithTitle:@"OK"];
  [alert setIcon:[[NSImage alloc] initWithContentsOfFile:@"AppIcon"]];
  [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:nil contextInfo:nil];
  
  return FALSE;
}
#endif

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
#if TARGET_OS_IPHONE
  NSLog(@"Status of CoreBluetooth central manager changed %ld (%s)", (long)central.state, [self centralManagerStateToString:central.state]);
  [[self delegate] bleCentralManagerStateChanged:central.state];

#else
  [self isLECapableHardware];
#endif
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
  NSLog(@"new peripheraal with RSSI %@",RSSI);
  if (!self.peripherals)
    self.peripherals = [[NSMutableArray alloc] initWithObjects:peripheral,nil];
  else
  {
    for(int i = 0; i < self.peripherals.count; i++)
    {
      CBPeripheral *p = [self.peripherals objectAtIndex:i];
      
      if ((p.identifier == NULL) || (peripheral.identifier == NULL))
        continue;
      
      if ([self UUIDSAreEqual:p.identifier UUID2:peripheral.identifier])
      {
        [self.peripherals replaceObjectAtIndex:i withObject:peripheral];
        NSLog(@"Duplicate UUID found updating...");
        return;
      }
    }
    
    [self.peripherals addObject:peripheral];
    
    NSLog(@"New UUID, adding");
  }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
  if (peripheral.identifier != NULL)
    NSLog(@"Connected to %@ successful", peripheral.identifier.UUIDString);
  else
    NSLog(@"Connected to NULL successful");
  
  self.activePeripheral = peripheral;
  [[self delegate] bleDidConnect];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
  if (!error)
  {
    NSLog(@"Characteristics of service with UUID : %@ found",[self CBUUIDToString:service.UUID]);
    if (service.characteristics)
    {
      unsigned long numCharacteristics = [service.characteristics count];
      NSLog(@"  %lu Characteristics",numCharacteristics);
    }
    [[self delegate] bleServiceCharacteristicsFound];
  }
  else
  {
    NSLog(@"Characteristic discovery unsuccessful!");
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
  if (!error)
  {
    //        printf("Services of peripheral with UUID : %s found\n",[self UUIDToString:peripheral.UUID]);
    NSLog(@"Service discovery success!");
    [[self delegate] bleServicesFound];
  }
  else
  {
    NSLog(@"Service discovery was unsuccessful!");
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
  if (!error)
  {
    //        printf("Updated notification state for characteristic with UUID %s on service with  UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID],[self UUIDToString:peripheral.UUID]);
  }
  else
  {
    NSLog(@"Error in setting notification state for characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
          [self CBUUIDToString:characteristic.UUID],
          [self CBUUIDToString:characteristic.service.UUID],
          peripheral.identifier.UUIDString);
    
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
  unsigned char data[20];
  
  static unsigned char buf[512];
  static int len = 0;
  NSInteger data_len;
  
  if (!error)
  {
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@ENVISAS_COMMAND_SERVER_SEND_CHARACTERISTIC_UUID]])
    {
      data_len = characteristic.value.length;
      [characteristic.value getBytes:data length:data_len];
      
      if (data_len == 20)
      {
        memcpy(&buf[len], data, 20);
        len += data_len;
        
        if (len >= 64)
        {
          [[self delegate] bleDidReceiveData:buf length:len];
          len = 0;
        }
      }
      else if (data_len < 20)
      {
        memcpy(&buf[len], data, data_len);
        len += data_len;
        
        [[self delegate] bleDidReceiveData:buf length:len];
        len = 0;
      }
    }
  }
  else
  {
    NSLog(@"updateValueForCharacteristic failed!");
  }
}

// delegate for scanForPeripheralsWithServices called from findBLEPeripherals
- (void)peripheral:(CBPeripheral *)peripheral
       didReadRSSI:(NSNumber *)RSSI
             error:(NSError *)error
{
  if (!isConnected)
    return;
  
  if (error) {
    NSLog(@"Error reading RSSI for peripheral with UUID %@",
          peripheral.identifier.UUIDString);
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
  } else {
    if (rssi != RSSI.intValue) {
      rssi = RSSI.intValue;
      [[self delegate] bleDidUpdateRSSI:RSSI];
    }
  }
}

@end
