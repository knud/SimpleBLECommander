
//
//  FirstViewController.h
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-12-29.
//  Copyright © 2018 Envisas Inc. All rights reserved.
//


// ODIN Service
//
// The Duo offers one service that is related to the "command" function. It is meant to
// support operations matching the Particle.io cloud-based API. It has 3 characteristics
// documented below.
#define ENVISAS_COMMAND_SERVICE_UUID                 "E92C0000-98A5-42E0-B06E-839F2D1D4102"

// This is a spare characteristic not currently used
#define ENVISAS_COMMAND_SPARE_CHARACTERISTIC_UUID    "E92C0001-98A5-42E0-B06E-839F2D1D4102"

// This characteristic is used for sending commands to the peripheral
#define ENVISAS_COMMAND_INVOKE_CHARACTERISTIC_UUID   "E92C0002-98A5-42E0-B06E-839F2D1D4102"

// This characteristic is used for receiving responses from the peripheral
#define ENVISAS_COMMAND_RESPONSE_CHARACTERISTIC_UUID "E92C0003-98A5-42E0-B06E-839F2D1D4102"

