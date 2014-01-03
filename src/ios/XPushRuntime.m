
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

#import "XPushRuntime.h"
#import "XPushNotificationExt.h"
#import <objc/runtime.h>
#import <XFace/XUtils.h>
#import <XFace/NSObject+JSONSerialization.h>
#import "BPush.h"

#define XFACE_DATA_KEY_DEVICETOKEN               @"deviceToken"

@implementation AppDelegate(Pushwoosh)

// 必须，如果正确调用了setDelegate，在bindChannel之后，结果在这个回调中返回。
// 若绑定失败，请进行重新绑定，确保至少绑定成功一次
- (void) onMethod:(NSString*)method response:(NSDictionary*)data
{
    if ([BPushRequestMethod_Bind isEqualToString:method])
    {
        NSDictionary* res = [[NSDictionary alloc] initWithDictionary:data];

        NSString *appid = [res valueForKey:BPushRequestAppIdKey];
        NSString *userid = [res valueForKey:BPushRequestUserIdKey];
        NSString *channelid = [res valueForKey:BPushRequestChannelIdKey];
        int returnCode = [[res valueForKey:BPushRequestErrorCodeKey] intValue];
        NSString *requestid = [res valueForKey:BPushRequestErrorCodeKey];
        NSLog(@"BPushRequestAppIdKey=%@;BPushRequestUserIdKey=%@;BPushRequestChannelIdKey=%@;BPushRequestErrorCodeKey=%d;BPushRequestErrorCodeKey=%@",appid,userid,channelid,returnCode,requestid);
    }
}

- (void)application:(UIApplication *)application internalDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    [BPush registerDeviceToken:devToken]; // 必须

    [BPush bindChannel]; // 必须。可以在其它时机调用，只有在该方法返回（通过onMethod:response:回调）绑定成功时，app才能接收到Push消息。一个app绑定成功至少一次即可（如果access token变更请重新绑定）。

    [XUtils setValueToDataForKey:XFACE_DATA_KEY_DEVICETOKEN value:devToken];
	NSLog(@"Push token: %@", [devToken description]);
}

- (void)application:(UIApplication *)application newDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
	[self application:application newDidRegisterForRemoteNotificationsWithDeviceToken:devToken];
	[self application:application internalDidRegisterForRemoteNotificationsWithDeviceToken:devToken];
}

- (void)application:(UIApplication *)application internalDidFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    NSLog(@"RegisterForRemoteNotificationsWithError:%@",[err description]);
}

- (void)application:(UIApplication *)application newDidFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
	[self application:application newDidFailToRegisterForRemoteNotificationsWithError:err];
	[self application:application internalDidFailToRegisterForRemoteNotificationsWithError:err];
}

- (void)application:(UIApplication *)application internalDidReceiveRemoteNotification:(NSDictionary *)userInfo {
    [BPush handleNotification:userInfo]; // 可选

    XPushNotificationExt *push = [self.viewController getCommandInstance:@"PushNotification"];
    [push fire:[userInfo JSONString]];
    [application setApplicationIconBadgeNumber:0];
    [application cancelAllLocalNotifications];
}

- (void)application:(UIApplication *)application newDidReceiveRemoteNotification:(NSDictionary *)userInfo {
	[self application:application newDidReceiveRemoteNotification:userInfo];
	[self application:application internalDidReceiveRemoteNotification:userInfo];
}

- (BOOL)application:(UIApplication *)application newDidFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	BOOL result = [self application:application newDidFinishLaunchingWithOptions:launchOptions];

    [BPush setupChannel:launchOptions]; // 必须
    [BPush setDelegate:self]; // 必须。

    [application registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeAlert
     | UIRemoteNotificationTypeBadge
     | UIRemoteNotificationTypeSound];

    if(result) {
		NSDictionary * userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
		if(userInfo) {
            [application setApplicationIconBadgeNumber:0];
            XPushNotificationExt *push = [self.viewController getCommandInstance:@"PushNotification"];
            [push performSelector:@selector(fire:) withObject:[userInfo JSONString] afterDelay:3];
        }
    }

	return result;
}

void dynamicMethodIMP(id self, SEL _cmd, id application, id param) {
	if (_cmd == @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)) {
		[self application:application internalDidRegisterForRemoteNotificationsWithDeviceToken:param];
		return;
    }

	if (_cmd == @selector(application:didFailToRegisterForRemoteNotificationsWithError:)) {
		[self application:application internalDidFailToRegisterForRemoteNotificationsWithError:param];
		return;
    }

	if (_cmd == @selector(application:didReceiveRemoteNotification:)) {
		[self application:application internalDidReceiveRemoteNotification:param];
		return;
    }
}

+ (void)load {
	method_exchangeImplementations(class_getInstanceMethod(self, @selector(application:didFinishLaunchingWithOptions:)), class_getInstanceMethod(self, @selector(application:newDidFinishLaunchingWithOptions:)));

	//if methods does not exist - provide default implementation, otherwise swap the implementation
	Method method = nil;
	method = class_getInstanceMethod(self, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
	if(method) {
		method_exchangeImplementations(method, class_getInstanceMethod(self, @selector(application:newDidRegisterForRemoteNotificationsWithDeviceToken:)));
	}
	else {
		class_addMethod(self, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:), (IMP)dynamicMethodIMP, "v@:::");
	}

	method = class_getInstanceMethod(self, @selector(application:didFailToRegisterForRemoteNotificationsWithError:));
	if(method) {
		method_exchangeImplementations(class_getInstanceMethod(self, @selector(application:didFailToRegisterForRemoteNotificationsWithError:)), class_getInstanceMethod(self, @selector(application:newDidFailToRegisterForRemoteNotificationsWithError:)));
	}
	else {
		class_addMethod(self, @selector(application:didFailToRegisterForRemoteNotificationsWithError:), (IMP)dynamicMethodIMP, "v@:::");
	}

	method = class_getInstanceMethod(self, @selector(application:didReceiveRemoteNotification:));
	if(method) {
		method_exchangeImplementations(class_getInstanceMethod(self, @selector(application:didReceiveRemoteNotification:)), class_getInstanceMethod(self, @selector(application:newDidReceiveRemoteNotification:)));
	}
	else {
		class_addMethod(self, @selector(application:didReceiveRemoteNotification:), (IMP)dynamicMethodIMP, "v@:::");
	}
}

@end
