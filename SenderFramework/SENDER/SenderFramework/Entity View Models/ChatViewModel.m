//
// Created by Roman Serga on 31/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "ChatViewModel.h"
#import "NSString+ConvertToLatin.h"
#import "DialogSetting.h"
#import "DefaultContactImageGenerator.h"
#import "NSURL+PercentEscapes.h"

@implementation ChatViewModel
{

}

@synthesize chatTitleLatin = _chatTitleLatin;

- (instancetype)initWithChat:(Dialog *)chat
{
    self = [super init];
    if (self)
    {
        self.chat = chat;
    }
    return self;
}

- (void)setChat:(Dialog *)chat
{
    _chat = chat;
    dispatch_async(dispatch_queue_create("com.MiddleWare.ChatCellModel.nameConverting", DISPATCH_QUEUE_SERIAL), ^{
        _chatTitleLatin = [_chat.name convertedToLatin];
    });
}

- (NSString *)chatTitle
{
    return self.chat.name;
}

- (NSString *)chatSubtitle
{
    NSString * subtitle;

    if ([self.chat.lastMessageText length])
    {
        BOOL textHidden = self.chat.chatSettings.hideTextNotification != ChatSettingsNotificationTypeDisabled;
        if (textHidden)
            NSLog(@"");
        subtitle = SenderFrameworkLocalizedString(textHidden ? @"new_msg_gcm" : self.chat.lastMessageText, nil);
    }
    else if ([self.chat.chatDescription length])
        subtitle = self.chat.chatDescription;
    else
        subtitle = SenderFrameworkLocalizedString(@"chat_is_empty", nil);

    return subtitle;
}

- (NSInteger)unreadCount
{
    return [self.chat.unreadCount integerValue];
}

- (ChatType)chatType
{
    return self.chat.chatType;
}

- (NSDate *)lastMessageTime
{
    return self.chat.lastMessageTime;
}

- (BOOL)isFavorite
{
    return [self.chat.chatSettings.favChat boolValue];
}

- (BOOL)isEncrypted
{
    return (self.chatType == ChatTypeP2P && self.chat.p2pBTCKeyData.length > 10) ||
            (self.chatType == ChatTypeGroup && [self.chat isEncrypted]);
}

- (BOOL)isCounterHidden
{
    return self.chat.chatSettings.hideCounterNotification != ChatSettingsNotificationTypeDisabled;
}

- (BOOL)isNotificationsHidden
{
    return self.chat.chatSettings.hidePushNotification != ChatSettingsNotificationTypeDisabled;
}

- (NSURL *)imageURL
{
    return [self.chat.imageURL length] ? [NSURL URLByAddingPercentEscapesToString:self.chat.imageURL] : nil;
}

- (UIColor *)imageBackgroundColor
{
    return [UIColor whiteColor];
}

- (UIColor *)defaultImageBackgroundColor
{
    return self.chat.defaultImageBackgroundColor;
}

- (UIImage *)defaultImage
{
    return self.chat.defaultImage;
}

@end