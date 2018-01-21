
/*
 
 Copyright (c) 2013 RedBearLab
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
*/

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
    #import <CoreBluetooth/CoreBluetooth.h>
#else
    #import <IOBluetooth/IOBluetooth.h>
#endif

@protocol BLEDelegate

@optional
-(void) bleDidConnect;
-(void) bleDidDisconnect;
-(void) bleDidUpdateRSSI:(NSNumber *) rssi;
-(void) bleDidReceiveData:(unsigned char *) data length:(int) length;
-(void) bleCentralManagerStateChanged:(CBManagerState) state;
-(void) bleServicesFound;
-(void) bleServiceCharacteristicsFound;
-(void) bleFindPeripheralsFinished;

@required

@end

@interface BLE : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate> {
    
}

@property (nonatomic,assign) id <BLEDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *peripherals;
@property (strong, nonatomic) CBPeripheral *activePeripheral;
@property (strong, nonatomic) CBCentralManager *CM;

+ (id)sharedInstance;

#pragma mark - Manage peripherals
-(int) findPeripherals:(int) timeout;
-(void) scanTimer:(NSTimer *)timer;
-(void) connectPeripheral:(CBPeripheral *)peripheral;
-(BOOL) isConnected;
-(void) printKnownPeripherals;
-(void) printPeripheralInfo:(CBPeripheral*)peripheral;
-(void) readRSSI;

#pragma mark - Find Services and Characteristics
-(void) findServicesFrom:(CBPeripheral *) peripheral services:(NSArray<CBUUID *> *)services;
-(void) findCharacteristicsFrom:(CBPeripheral *) peripheral characteristicUUIDs:(NSArray<CBUUID *> *)characteristicUUIDs;
-(CBService *) findServiceBy:(CBUUID *)UUID peripheral:(CBPeripheral *)peripheral;
-(CBCharacteristic *) findCharacteristicBy:(CBUUID *)UUID service:(CBService*)service;

#pragma mark - Read and Write
-(void) read;
-(void) write:(NSData *)d;
-(void) writeValue:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data;
-(void) readValue: (CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p;
-(void) enableReadNotification:(CBPeripheral *)p;

@end
