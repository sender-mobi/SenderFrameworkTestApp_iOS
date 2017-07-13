//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Dialog.h"
#import "DialogSetting.h"

@interface Dialog (HumanReadableSettings)

ChatSettingsNotificationType convertHumanReadableNotificationSettingToRaw(NSString * humanReadable);
ChatSettingsSoundScheme convertHumanReadableSoundSchemeToRaw(NSString * humanReadable);
NSString * humanReadableStateForType(ChatSettingsNotificationType notificationType);
NSString * humanReadableSoundSchemeState(ChatSettingsSoundScheme soundScheme);

-(NSArray<NSString *> *)allSoundSchemeValues;
-(NSArray<NSString *> *)allNotificationSelectorValues;

@end