/****************************************************************************
 * EnvisasAccessPointManager.h:
 *
 * Description: Envisas reader access point manager.
 *
 * Note: This was adapted from wwd_constants.h to support mapping between
 * Particle Firmware constants and the reader firmware.
 *
 * See https://github.com/particle-iot/firmware/blob/develop/hal/src/photon/wiced/WWD/include/wwd_constants.h
 *
 * DISCLAIMER
 *  This document contains confidential information which is proprietary to
 *  Envisas Inc. No part of its contents may be used, copied, disclosed, or
 *  conveyed in any manner whatsoever without prior written permission from
 *  Envisas Inc.
 *
 * Copyright 2017, Envisas Inc.
 *
 * Created on: Nov 14, 2017
 *     Author: Steven Knudsen
 ***************************************************************************/

typedef enum {
ENVISAS_ACCESS_POINT_SECURITY_OPEN           = 0,   /**< Open security                               */
ENVISAS_ACCESS_POINT_SECURITY_WEP_PSK        = 1,   /**< WEP PSK Security with open authentication   */
ENVISAS_ACCESS_POINT_SECURITY_WEP_SHARED     = 2,   /**< WEP PSK Security with shared authentication */
ENVISAS_ACCESS_POINT_SECURITY_WPA_TKIP_PSK   = 3,   /**< WPA PSK Security with TKIP                  */
ENVISAS_ACCESS_POINT_SECURITY_WPA_AES_PSK    = 4,   /**< WPA PSK Security with AES                   */
ENVISAS_ACCESS_POINT_SECURITY_WPA_MIXED_PSK  = 5,   /**< WPA PSK Security with AES & TKIP            */
ENVISAS_ACCESS_POINT_SECURITY_WPA2_AES_PSK   = 6,   /**< WPA2 PSK Security with AES                  */
ENVISAS_ACCESS_POINT_SECURITY_WPA2_TKIP_PSK  = 7,   /**< WPA2 PSK Security with TKIP                 */
ENVISAS_ACCESS_POINT_SECURITY_WPA2_MIXED_PSK = 8,   /**< WPA2 PSK Security with AES & TKIP           */

ENVISAS_ACCESS_POINT_SECURITY_WPA_TKIP_ENT   = 20,  /**< WPA Enterprise Security with TKIP           */
ENVISAS_ACCESS_POINT_SECURITY_WPA_AES_ENT    = 21,  /**< WPA Enterprise Security with AES            */
ENVISAS_ACCESS_POINT_SECURITY_WPA_MIXED_ENT  = 22,  /**< WPA Enterprise Security with AES & TKIP     */
ENVISAS_ACCESS_POINT_SECURITY_WPA2_TKIP_ENT  = 23,  /**< WPA2 Enterprise Security with TKIP          */
ENVISAS_ACCESS_POINT_SECURITY_WPA2_AES_ENT   = 24,  /**< WPA2 Enterprise Security with AES           */
ENVISAS_ACCESS_POINT_SECURITY_WPA2_MIXED_ENT = 25,  /**< WPA2 Enterprise Security with AES & TKIP    */

ENVISAS_ACCESS_POINT_SECURITY_IBSS_OPEN      = 40,  /**< Open security on IBSS ad-hoc network        */
ENVISAS_ACCESS_POINT_SECURITY_WPS_OPEN       = 41,  /**< WPS with open security                      */
ENVISAS_ACCESS_POINT_SECURITY_WPS_SECURE     = 42,  /**< WPS with AES security                       */

ENVISAS_ACCESS_POINT_SECURITY_UNKNOWN        = -1,

ENVISAS_ACCESS_POINT_SECURITY_FORCE_8_BIT    = 0x7f /**< Force type to 8 bits                        */
} envisas_access_point_security_t;
