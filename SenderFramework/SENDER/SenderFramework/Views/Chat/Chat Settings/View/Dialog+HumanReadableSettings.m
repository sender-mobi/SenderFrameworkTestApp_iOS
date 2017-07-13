//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "Dialog+HumanReadableSettings.h"

#define soundSchemeDefault SenderFrameworkLocalizedString(@"chat_settings_sound_scheme_default", nil)
#define soundSchemeBusiness SenderFrameworkLocalizedString(@"chat_settings_sound_scheme_business", nil)
#define soundSchemePersonal SenderFrameworkLocalizedString(@"chat_settings_sound_scheme_personal", nil)
#define soundSchemeAlert SenderFrameworkLocalizedString(@"chat_settings_sound_scheme_alert", nil)

#define enabledAllDevice SenderFrameworkLocalizedString(@"chat_settings_all_devices", nil)
#define enabledThisDevice SenderFrameworkLocalizedString(@"chat_settings_this_device", nil)
#define disabled SenderFrameworkLocalizedString(@"chat_settings_disabled", nil)

@implementation Dialog (HumanReadableSettings)

ChatSettingsNotificationType convertHumanReadableNotificationSettingToRaw(NSString * humanReadable)
{
    ChatSettingsNotificationType result;
    if ([humanReadable isEqualToString:enabledAllDevice])
        result = ChatSettingsNotificationTypeEnabled;
    else if ([humanReadable isEqualToString:enabledThisDevice])
        result = ChatSettingsNotificationTypeEnabledLocally;
    else
        result = ChatSettingsNotificationTypeDisabled;

    return result;
}

ChatSettingsSoundScheme convertHumanReadableSoundSchemeToRaw(NSString * humanReadable)
{
    ChatSettingsSoundScheme result;

    if ([humanReadable isEqualToString:soundSchemeAlert])
        result = ChatSettingsSoundSchemeAlert;
    else if ([humanReadable isEqualToString:soundSchemeBusiness])
        result = ChatSettingsSoundSchemeBusiness;
    else if ([humanReadable isEqualToString:soundSchemePersonal])
        result = ChatSettingsSoundSchemePersonal;
    else
        result = ChatSettingsSoundSchemeDefault;

    return result;
}


NSString * humanReadableStateForType(ChatSettingsNotificationType notificationType)
{
    NSString * result;

    switch (notificationType) {
        case ChatSettingsNotificationTypeEnabledLocally:
            result = enabledThisDevice;
            break;
        case ChatSettingsNotificationTypeEnabled:
            result = enabledAllDevice;
            break;
        case ChatSettingsNotificationTypeDisabled:
            result = disabled;
            break;
        default:
            break;
    }

    return result;
}

NSString * humanReadableSoundSchemeState(ChatSettingsSoundScheme soundScheme)
{
    NSString * result;
    switch (soundScheme)
    {
        case ChatSettingsSoundSchemeDefault:
            result = soundSchemeDefault;
            break;
        case ChatSettingsSoundSchemeBusiness:
            result = soundSchemeBusiness;
            break;
        case ChatSettingsSoundSchemePersonal:
            result = soundSchemePersonal;
            break;
        case ChatSettingsSoundSchemeAlert:
            result = soundSchemeAlert;
            break;
        default:
            break;
    }
    return result;
}


-(NSArray<NSString *> *)allSoundSchemeValues
{
    return @[soundSchemeDefault, soundSchemePersonal, soundSchemeBusiness, soundSchemeAlert];
}

-(NSArray<NSString *> *)allNotificationSelectorValues
{
    return @[enabledAllDevice, enabledThisDevice, disabled];
}

@end
