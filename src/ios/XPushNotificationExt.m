
/*
 Copyright 2012-2013, Polyvi Inc. (http://polyvi.github.io/openxface)
 This program is distributed under the terms of the GNU General Public License.

 This file is part of xFace.

 xFace is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 xFace is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with xFace.  If not, see <http://www.gnu.org/licenses/>.
 */

//
//  XPushNotificationExt.m
//  xFaceLib
//
//

#import "XPushNotificationExt.h"
#import <XFace/XUtils.h>
#import <XFace/XConstants.h>

#import <Cordova/CDVInvokedUrlCommand.h>
#import <Cordova/CDVPluginResult.h>

@implementation XPushNotificationExt

- (void)getDeviceToken:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *result = nil;

    NSData *deviceToken = (NSData *)[XUtils getValueFromDataForKey:XFACE_DATA_KEY_DEVICETOKEN];
    if (deviceToken) {
        // NSData ==> hex string
        NSString *tokenString = [deviceToken description];
        tokenString = [tokenString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
        tokenString = [tokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:tokenString];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)registerOnReceivedListener:(CDVInvokedUrlCommand*)command
{
}

- (void)fire:(NSString *)pushString
{
    NSString *jsString = [NSString stringWithFormat:@"(function(){\
                          try {\
                              cordova.require('com.polyvi.xface.extension.push.PushNotification').fire('%@');\
                          }\
                          catch(e) {\
                              console.log('exception in push fire:' + e);\
                          }\
                          })();", pushString];
    [self.commandDelegate evalJs:jsString];
}

@end
