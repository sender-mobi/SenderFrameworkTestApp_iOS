//
// Created by Roman Serga on 5/12/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ChatNotification : UIView

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text;

@property (nonatomic, strong) NSString * text;
@property (nonatomic, strong) UILabel * titleLabel;

@end

@interface AbstractChatNotificationCell : UIView

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text;

@property (nonatomic, strong) NSLayoutConstraint * notificationLeading;
@property (nonatomic, strong) NSLayoutConstraint * notificationTrailing;
@property (nonatomic, strong) NSLayoutConstraint * notificationBottom;
@property (nonatomic, strong) NSLayoutConstraint * notificationTop;

@property (nonatomic, strong) ChatNotification * notification;

@end

@interface ChatNotificationCell : AbstractChatNotificationCell

@end

@interface ChatTypingCell : AbstractChatNotificationCell

@end