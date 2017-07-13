//
// Created by Roman Serga on 9/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "ContactViewModel.h"
#import "NSString+ConvertToLatin.h"
#import "DefaultContactImageGenerator.h"
#import "NSURL+PercentEscapes.h"


@implementation ContactViewModel
{

}

@synthesize chatTitleLatin = _chatTitleLatin;

- (instancetype)initWithContact:(Contact *)contact;
{
    self = [super init];
    if (self)
    {
        self.contact = contact;
    }
    return self;
}

- (void)setContact:(Contact *)contact
{
    _contact = contact;
    dispatch_async(dispatch_queue_create("com.MiddleWare.ChatCellModel.nameConverting", DISPATCH_QUEUE_SERIAL), ^{
        _chatTitleLatin = [_contact.name convertedToLatin];
    });
}

- (NSString *)chatTitle
{
    return self.contact.name;
}

- (NSString *)chatSubtitle
{
    return [self.contact getPhoneFormatted:YES];
}

- (NSInteger)unreadCount
{
    return 0;
}

- (ChatType)chatType
{
    return ChatTypeP2P;
}

- (NSDate *)lastMessageTime
{
    return [NSDate dateWithTimeIntervalSince1970:0];
}

- (BOOL)isFavorite
{
    return NO;
}

- (BOOL)isEncrypted
{
    return NO;
}

- (BOOL)isCounterHidden
{
    return YES;
}

- (BOOL)isNotificationsHidden
{
    return YES;
}

- (NSURL *)imageURL
{
    return [self.contact.imageURL length] ? [NSURL URLByAddingPercentEscapesToString:self.contact.imageURL] : nil;
}

- (UIColor *)imageBackgroundColor
{
    return [UIColor whiteColor];
}

- (UIColor *)defaultImageBackgroundColor
{
    return self.contact.cellBackgroundColor;
}

- (UIImage *)defaultImage
{
    NSString * defaultImageName = [DefaultContactImageGenerator convertContactNameToImageName:self.chatTitle];
    UIImage * defaultImage = [UIImage imageFromSenderFrameworkNamed:defaultImageName];
    return defaultImage;
}

@end