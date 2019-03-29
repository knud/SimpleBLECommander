/*!
 * @file BLEDefines.h
 * @author Steven Knudsen
 * @date 2018-03-19
 * @brief BLE-related defines.
 *
 * Define things like the device name, service and characteristic UUIDs, etc.
 *
 * @note Please change the base UUID for your own applications based on this example.
 *
 * @see https://devzone.nordicsemi.com/tutorials/b/bluetooth-low-energy/posts/ble-services-a-beginners-tutorial
 *
 * This file is part of the Simple BLE Commander example.
 *
 * Copyright (C) 2019 by Steven Knudsen
 *
 * This software may be modified and distributed under the terms
 * of the MIT license.  See the LICENSE file for details.
 */



// Simple BLE Commander Service
//
// The peripheral offers one service that is related to the "command" function. It is meant to
// support operations client commands and server responses. It has 3 characteristics
// documented below.
#define SIMPLE_COMMAND_SERVICE_UUID                 "E92C0000-98A5-42E0-B06E-839F2D1D4102"

// This is a spare characteristic not currently used
#define SIMPLE_COMMAND_SPARE_CHARACTERISTIC_UUID    "E92C0001-98A5-42E0-B06E-839F2D1D4102"

// This characteristic is used for sending commands to the peripheral
#define SIMPLE_COMMAND_INVOKE_CHARACTERISTIC_UUID   "E92C0002-98A5-42E0-B06E-839F2D1D4102"

// This characteristic is used for receiving responses from the peripheral
#define SIMPLE_COMMAND_RESPONSE_CHARACTERISTIC_UUID "E92C0003-98A5-42E0-B06E-839F2D1D4102"

#define BLE_DEVICE_NAME1 "Peripheral1"
#define BLE_DEVICE_NAME2 "Peripheral2"
