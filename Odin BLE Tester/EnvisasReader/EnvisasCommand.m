//
//  EnvisasCommand.m
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-01-11.
//  Copyright © 2018 TechConficio. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EnvisasCommand.h"

@interface EnvisasCommand ()

@end

@implementation EnvisasCommand

- (instancetype _Nullable )initWith:(CommandID)command argument:(NSString * _Nullable) argString error:(NSError * _Nullable * _Nullable)error
{
  if ( self = [super init])
  {
    self->commandID = command;
    self->argLength = 0;
    if (argString != NULL) {
      if ([argString length] < 4096) {
        self->argData = [NSString stringWithString:argString];
        self->argLength = [argString length];
      }
      else {
        if (error != NULL)
        {
          // TODO implement error defn
        }
      }
    }
    return self;
  } else
    return nil; // TODO should raise exception
}

- (NSArray<NSString *> *_Nonnull)commandStrings
{
  // In each command string acceptable by the reader there can be only up to 59 bytes.
  // If there are more than 59 bytes in the argData, we will need multiple command
  // strings.
  unsigned long numCommands = 1 + ([self->argData length] / 59);
  NSMutableArray *commands = [[NSMutableArray alloc] initWithCapacity:numCommands];
  char uCmd[64];
  uCmd[0] = self->commandID;
  uint16_t argCharsCount = self->argLength;
  // handle commands with no arguments
  if (argCharsCount <= 0)
  {
    snprintf(uCmd+1,62,"%03x",0);
    NSString * cmdString = [[NSString alloc] initWithCString:uCmd encoding:NSUTF8StringEncoding];
    [commands addObject:cmdString];
  } else {
    // there were arguments to handle
    uint16_t argPos = 0;
    while (argCharsCount > 0) {
      snprintf(uCmd+1,62,"%03x",argCharsCount);
      uint16_t charsToMove = 59;
      if (argCharsCount < 59) charsToMove = argCharsCount;
      NSRange range = NSMakeRange(argPos, charsToMove);
      [self->argData getBytes:(uCmd+4) maxLength:59 usedLength:NULL encoding:NSUTF8StringEncoding options:NSStringEncodingConversionAllowLossy range:range remainingRange:NULL];
      uCmd[4+charsToMove] = '\0'; // make sure it looks like a C string
      NSString * cmdString = [[NSString alloc] initWithCString:uCmd encoding:NSUTF8StringEncoding];
      [commands addObject:cmdString];
      argPos += charsToMove;
      argCharsCount -= charsToMove;
      charsToMove = 0;
    }
  }
  
  return commands;
}

@end
