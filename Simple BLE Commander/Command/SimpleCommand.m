/*!
 * @file SimpleCommand.m
 * @author Steven Knudsen
 * @date 2018-03-19
 * @brief A SimpleCommand root class
 *
 * This file is part of the Simple BLE Commander example.
 *
 * Copyright (C) 2019 by Steven Knudsen
 *
 * This software may be modified and distributed under the terms
 * of the MIT license.  See the LICENSE file for details.
 */

#import <Foundation/Foundation.h>

#import "SimpleCommand.h"

@interface SimpleCommand ()

@end

@implementation SimpleCommand

- (instancetype _Nullable )initWith:(CommandID)command argument:(NSString * _Nullable) argString error:(NSError * _Nullable * _Nullable)error
{
  if ( self = [super init])
  {
    
    self->commandID = command;
    self->name = [SimpleCommand commandName:command];
    switch(command)
    {
      case NO_COMMAND:
        self->argLength = 0;
        break;
      case FAST_BLINK:
        self->argLength = 0;
        break;
      case SLOW_BLINK:
        self->argLength = 0;
        break;
      case ALT_BLINK:
        self->argLength = 0;
        break;
      case OFF:
        self->argLength = 0;
        break;
      case ABORT:
        self->argLength = 0;
        break;
      default:
        self->argLength = 0;
        break;
    }
    if (self->argLength > 0) {
      if ([argString length] < 4096) {
        self->argData = [NSString stringWithString:argString];
        self->argLength = [argString length];
      }
      else {
      // TODO implement error defn
      }
    }
    return self;
  } else
    return nil; // TODO should raise exception
}

+ (NSString *_Nonnull)commandName:(CommandID)command
{
  switch(command)
  {
    case NO_COMMAND:
      return @"No Command";
      break;
    case FAST_BLINK:
      return @"Fast Blink";
      break;
    case SLOW_BLINK:
      return @"Slow Blink";
      break;
    case ALT_BLINK:
      return @"Alternating Blink";
      break;
    case OFF:
      return @"LED Off";
      break;
    case ABORT:
      return @"Abort";
      break;
    default:
      return @"Bad Command";
      break;
  }
}

- (NSData *)bleFormat
{
  char uCmd[64];
  uCmd[0] = self->commandID;
  snprintf(uCmd+1,62,"%03x",self->argLength);
//  uint16_t argCharsCount = self->argLength;
  NSRange range = NSMakeRange(0, self->argLength);

  [self->argData getBytes:(uCmd+4) maxLength:self->argLength usedLength:NULL encoding:NSUTF8StringEncoding options:NSStringEncodingConversionAllowLossy range:range remainingRange:NULL];
  uCmd[4+self->argLength] = '\0'; // make sure it looks like a C string
  NSData * cmdData = [[NSData alloc] initWithBytes:uCmd length:(4+self->argLength)];
//  NSString * cmdString = [[NSString alloc] initWithCString:uCmd encoding:NSUTF8StringEncoding];
//  NSString * bString = [[NSString alloc] initWithBytes:uCmd length:4+self->argLength encoding:NSUTF8StringEncoding];

  return cmdData;
}

@end
