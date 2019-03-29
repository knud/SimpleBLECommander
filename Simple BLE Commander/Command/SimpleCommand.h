/*!
 * @file SimpleCommand.h
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

#define SIMPLE_COMMAND_ARG_LENGTH 63

typedef NS_ENUM(NSInteger, CommandID) {
  NO_COMMAND              = 0xFE, // No Command
  FAST_BLINK              = 0x01,
  SLOW_BLINK              = 0x02,
  ALT_BLINK               = 0x03,
  OFF                     = 0x04,
  ABORT                   = 0xFF // Abort current command
};


@interface SimpleCommand : NSObject {
  @public
  NSString            * name;      // Printable name

  @private
  CommandID             commandID; // The command ID
  uint16_t              argLength; // The number of arg bytes [0,4095]
  NSString            * argData;   // The command argument
}

/*!
 * @brief Return an @pSimpleCommand object.
 * @ingroup techconficio
 *
 * @details The @pSimpleCommand object is initialized with the @pCOMMAND_ID
 * and as appropriate an @pNSString containing the command argument.
 *
 * @param command The command identifier.
 * @param argString The argument string if appropriate, otherwise pass in NULL. It can be up to 4095 characters.
 * @param error If an error occurs, up return contains an @pNSError object that
 * describes the problem. If you are not interested in possible errors,
 * pass in @pNULL

 * @return An @pSimpleCommand object if successful, @pNULL otherwise.
 */
- (instancetype _Nullable )initWith:(CommandID)command argument:(NSString * _Nullable) argString error:(NSError * _Nullable * _Nullable)error;

/*!
 * @brief Return the name of the command as a string
 *
 * @param command The command ID
 * @return NSString * pointer to the command name.
 */
+ (NSString *_Nonnull)commandName:(CommandID)command;

/*!
 * @brief Return BLE-formatted command string.
 * @ingroup techconficio
 *
 * @details The format of a BLE command string is shown in the table below.
 *
 * |    ID    | Arg Len   |     Arg Data      |
 * | (1 byte) | (3 chars) | (0 to 4095 chars) |
 * |:--------:|:---------:|:------------------|
 * |   0xXX   |    000    | command dependent |
 *
 * The ID is a uint8_t
 * The Arg len is a 3 digit hex number with leading zeros.
 * The Arg Data depends on the command and may be empty.
 *
 * @return An @pNSArray of comprising at least one reader command string.
 */
- (NSData *_Nonnull)bleFormat;

// @TODO finish documenting all commands below.

/*!
 * @brief Start LED fast blink
 * @ingroup techconficio
 *
 * @details
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x01 | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | dont' care                                         |
 *   +------+---------+----------------------------------------------------+
 */

/*!
 * @brief Initiate LED fast blink
 * @ingroup techconficio
 *
 * @details
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x01 | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | dont' care                                         |
 *   +------+---------+----------------------------------------------------+
 */

/*!
 * @brief Initiate LED slow blink
 * @ingroup techconficio
 *
 * @details
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x02 | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | dont' care                                         |
 *   +------+---------+----------------------------------------------------+
 */

/*!
 * @brief Initiate alternate LED blinking
 * @ingroup techconficio
 *
 * @details
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x03 | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | dont' care                                         |
 *   +------+---------+----------------------------------------------------+
 */

/*!
 * @brief Turn off LED
 * @ingroup techconficio
 *
 * @details
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x04 | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | dont' care                                         |
 *   +------+---------+----------------------------------------------------+
 */


/*!
 * @brief Abort the current operation
 * @ingroup techconficio
 *
 * @details
 * @todo not yet implemented
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0xFF | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 */

@end
