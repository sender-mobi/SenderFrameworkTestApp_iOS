//
//  AppDelegate.h
//  SenderFrameworkTest
//
//  Created by Roman Serga on 13/4/17.
//  Copyright © 2017 Roman Serga. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SenderFramework/SenderFramework.h>
#import <UserNotifications/UserNotifications.h>

@class SenderUI;

@interface AppDelegate : UIResponder <UIApplicationDelegate,
                                      SenderAuthorizationDelegate,
                                      UNUserNotificationCenterDelegate,
                                      PKPushRegistryDelegate>

@property (strong, nonatomic) UIWindow *window;
@property(nonatomic, strong) SenderUI *senderUI;

@end

