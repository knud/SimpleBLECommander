//
//  EnvisasCommand.h
//  Odin BLE Tester
//
//  Created by Knud S Knudsen on 2018-01-11.
//  Copyright © 2018 Envisas Inc. All rights reserved.
//

#define ENVISAS_COMMAND_ARG_LENGTH 63

typedef NS_ENUM(NSInteger, CommandID) {
  NO_COMMAND              = 0x00, // No Command
  RFID_ON_OFF             = 0x02, // RFID On/Off
  INVENTORY               = 0x03, // Inventory
  HALT_INVENTORY          = 0x04, // Halt Inventory
  READ_TAG                = 0x10, // Read Tag
  WRITE_TAG               = 0x11, // Write Tag
  LIST_ACCESS_POINTS      = 0x20, // List Access Points
  ADD_ACCESS_POINT        = 0x21, // Add Access Point
  REMOVE_ACCESS_POINTS    = 0x22, // Remove Access Points
  READER_STATUS           = 0x30, // Reader Status
  READER_CONFIG           = 0x31, // Reader Configuration
  UPDATE_READER_CONFIG    = 0x32, // Update Reader Configuration
  RESET_READER            = 0x3E, // Reset the reader command
  RESET_READER_TO_FACTORY = 0x3F, // Reset the reader to factory command
  ABORT                   = 0xFF // Abort current command
};


@interface EnvisasCommand : NSObject {
  @public

  @private
  CommandID             commandID; // The command ID
  uint16_t              argLength; // The number of arg bytes [0,4095]
  NSString            * argData;   // The command argument
  NSArray<NSString *> * commands;  // The array of command strings
}

/*!
 * @brief Return an @pEnvisasCommand object.
 * @ingroup envisas
 *
 * @details The @pEnvisasCommand object is initialized with the @pCOMMAND_ID
 * and as appropriate an @pNSString containing the command argument.
 *
 * @param command The command identifier.
 * @param argString The argument string if appropriate, otherwise pass in NULL. It can be up to 4095 characters.
 * @param error If an error occurs, up return contains an @pNSError object that
 * describes the problem. If you are not interested in possible errors,
 * pass in @pNULL

 * @return An @pEnvisasCommand object if successful, @pNULL otherwise.
 */
- (instancetype _Nullable )initWith:(CommandID)command argument:(NSString * _Nullable) argString error:(NSError * _Nullable * _Nullable)error;

/*!
 * @brief Return one or more command strings.
 * @ingroup envisas
 *
 * @details An @pEnvisasCommand will always provide at least one string that
 * is sent to the reader to invoke a command. Some commands take long arguments
 * and require that multiple strings be sent to the reader in sequence. This
 * @pNSArray contains that(those) string(s).
 *
 * The general format of a command string is shown in the table below.
 *
 * |    ID    | Arg Len   |     Arg Data      |
 * | (1 byte) | (3 chars) | (0 to 4095 chars) |
 * |:--------:|:---------:|:------------------|
 * |   0xXX   |    000    | command dependent |
 *
 * The ID is a 2-digit, ASCII-encoded hex number prefixed by '0x'
 * The Arg len is a 3 digit hex number with leading zeros.
 * The Arg Data depends on the command and may be empty.
 *
 * @return An @pNSArray of comprising at least one reader command string.
 */
- (NSArray<NSString *> *_Nonnull)commandStrings;

// @TODO finish documenting all commands below.

/*!
 * @brief noCommand
 * @ingroup envisas
 * @details Example for @pnoCommand command is described below.
 *
 * @note No error is ever expected.
 *
 * @code
 * EnvisasCommand *nc = [[EnvisasCommand alloc] initWith:NO_COMMAND argString:NULL error:NULL];
 * @endcode
 */

/*!
 * @brief
 * @ingroup envisas
 *
 * @details
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x02 | 003     | ' ON' or 'OFF' | don't care                        |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | 3 C            | 56 C                              |
 *   +------+---------+----------------------------------------------------+
 * @param ' ON' or 'OFF'
 * @return SUCCESS if successful, FAILURE otherwise.
 */
//- (int) rfidOnOff:(EnvisasCommand *)command;

/*!
 * @brief
 * @ingroup envisas
 *
 * @details
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x03 | 004     | scanTime | don't care                              |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     |  4 C     | 55 C                                    |
 *   +------+---------+----------------------------------------------------+
 * @param scanTime Number of seconds to scan [0,120], ASCII string
 * @return SUCCESS if successful, FAILURE otherwise.
 */
//- (int) inventory:(EnvisasCommand *)command;

/*!
 * @brief
 * @ingroup envisas
 *
 * @details
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x04 | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 * @return SUCCESS if successful, FAILURE otherwise.
 */
//- (int) haltInventory:(EnvisasCommand *)command;

/*!
 * @brief
 * @ingroup envisas
 *
 * @details
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x10 | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 * @return SUCCESS if successful, FAILURE otherwise.
 */
//- (int) readTag:(EnvisasCommand *)command;

/*!
 * @brief
 * @ingroup envisas
 *
 * @details
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x11 | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 * @return SUCCESS if successful, FAILURE otherwise.
 */
//- (int) writeTag:(EnvisasCommand *)command;

/*!
 * @brief Report the list of access points.
 * @ingroup envisas
 *
 * @details Respond with a list of known SSIDs
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x20 | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 * @return SUCCESS if successful, FAILURE otherwise.
 */
//- (int) listAccessPoints:(EnvisasCommand *)command;

/*!
 * @brief Add an access point to the reader
 * @ingroup envisas
 *
 * @details The access point credentials are stored on the reader.
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x21 | 061     | home | ssid | auth | pwd                           |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | 1 B  | 32 B | 1 B  | 63 B                          |
 *   +------+---------+----------------------------------------------------+
 * @param home (1 byte) 1 if SSID is to be the HOME AP, otherwise ignored
 * @param ssid a 32 character array containing the SSID. which may be 1 to
 *             32 characters long. Anything less than 32 characters has
 *             trailing blanks (is padded on the right)
 * @param auth encryption/auth scheme
 *             (see @pEnvisasAccessPointSecurity::envisas_access_point_security_t)
 * @param pwd a 63 character array containing the pass-phase, which may be
 *            8 to 63 characters long. Anything less than 63 characters has
 *            trailing blanks (is padded on the right)
 * @return SUCCESS if successful, FAILURE otherwise.
 */
//- (int) addAccessPoint:(EnvisasCommand *)command;

/*!
 * @brief Remove all access points.
 * @ingroup envisas
 *
 * @details This command is used to remove all known access points from the
 * reader. It is mostly useful for setting the unit to "factory" and for
 * testing.
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x22 | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 * @return SUCCESS if successful, FAILURE otherwise.
 */
//- (int) removeAccessPoints:(EnvisasCommand *)command;

/*!
 * @brief
 * @ingroup envisas
 *
 * @details
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x30 | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 * @return SUCCESS if successful, FAILURE otherwise.
 */
//- (int) readerStatus:(EnvisasCommand *)command;

/*!
 * @brief
 * @ingroup envisas
 *
 * @details
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x31 | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 * @return SUCCESS if successful, FAILURE otherwise.
 */
//- (int) readerConfig:(EnvisasCommand *)command;

/*!
 * @brief
 * @ingroup envisas
 *
 * @details
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x32 | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 * @return SUCCESS if successful, FAILURE otherwise.
 */
//- (int) updateReaderConfig:(EnvisasCommand *)command;

/*!
 * @brief Reset the reader.
 * @ingroup envisas
 *
 * @details Reset the reader; equivalent to hitting the reset button.
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x3E | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 * @return Nothing, the reader is reset before it can return a value.
 */
//- (int) resetReader:(EnvisasCommand *)command;

/*!
 * @brief Reset the reader to factory conditions.
 * @ingroup envisas
 *
 * @details Reset the reader to factory conditions. Key parameters are setting
 * to defaults and the reset function is invoked, which is equivalent to
 * hitting the reset button.
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0x3F | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 * @return Nothing, the reader is reset before it can return a value.
 */
//- (int) resetReaderToFactory:(EnvisasCommand *)command;

/*!
 * @brief
 * @ingroup envisas
 *
 * @details
 *
 * @param command (format below)
 *   +--ID--+-Arg Len-+-Arg Data-------------------------------------------+
 *   | 0xFF | 000     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 *   | 1 B  | 3 C     | don't care                                         |
 *   +------+---------+----------------------------------------------------+
 * @return SUCCESS if successful, FAILURE otherwise.
 */
//- (int) abort:(EnvisasCommand *)command;

@end
