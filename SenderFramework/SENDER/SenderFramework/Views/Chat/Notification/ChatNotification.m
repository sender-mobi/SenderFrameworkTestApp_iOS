//
// Created by Roman Serga on 5/12/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import "ChatNotification.h"

@interface ChatNotification()

@property (nonatomic, strong) NSLayoutConstraint * titleLabelLeading;
@property (nonatomic, strong) NSLayoutConstraint * titleLabelTrailing;
@property (nonatomic, strong) NSLayoutConstraint * titleLabelBottom;
@property (nonatomic, strong) NSLayoutConstraint * titleLabelTop;

@end

@implementation ChatNotification {

}

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [SenderCore sharedCore].stylePalette.chatNotificationBackgroundColor;

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.textColor = [SenderCore sharedCore].stylePalette.chatNotificationTextColor;
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.layer.cornerRadius = 11.0f;

        self.titleLabel.font = (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_8_2) ? [UIFont systemFontOfSize:11.0f weight:UIFontWeightMedium] : [UIFont fontWithName:@"HelveticaNeue-Medium" size:11.0f];

        [self addSubview:self.titleLabel];

        self.titleLabelLeading = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1.0f
                                                               constant:10.0f];
        self.titleLabelTrailing = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                                               attribute:NSLayoutAttributeTrailing
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self
                                                               attribute:NSLayoutAttributeTrailing
                                                              multiplier:1.0f
                                                                constant:-10.0f];
        self.titleLabelTop = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0f
                                                           constant:3.5f];
        self.titleLabelBottom = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1.0f
                                                              constant:-3.5f];

        [self addConstraint:self.titleLabelLeading];
        [self addConstraint:self.titleLabelTrailing];
        [self addConstraint:self.titleLabelTop];
        [self addConstraint:self.titleLabelBottom];

        self.titleLabel.text = text;

    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat horizontalSpaces = (CGFloat)(fabs(self.titleLabelLeading.constant) + fabs(self.titleLabelTrailing.constant));
    CGFloat verticalSpaces = (CGFloat)(fabs(self.titleLabelTop.constant) + fabs(self.titleLabelBottom.constant));

    CGSize maxLabelSize = size;
    maxLabelSize.width -= horizontalSpaces;
    maxLabelSize.height -= verticalSpaces;

    CGSize sizeThatFits = [self.titleLabel sizeThatFits:maxLabelSize];

    sizeThatFits.width += horizontalSpaces;
    sizeThatFits.height += verticalSpaces;
    if (sizeThatFits.height < self.layer.cornerRadius * 2) sizeThatFits.height = self.layer.cornerRadius * 2;

    return sizeThatFits;
}

- (CGSize)intrinsicContentSize
{
    CGSize intrinsicContentSize = self.titleLabel.intrinsicContentSize;
    intrinsicContentSize.width += (fabs(self.titleLabelLeading.constant) + fabs(self.titleLabelTrailing.constant));
    intrinsicContentSize.height += (fabs(self.titleLabelTop.constant) + fabs(self.titleLabelBottom.constant));
    return intrinsicContentSize;
}

- (void)setText:(NSString *)text
{
    self.titleLabel.text = text;
    [self layoutIfNeeded];
}

- (NSString *)text
{
    return self.titleLabel.text;
}

@end

@implementation AbstractChatNotificationCell

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text
{
    if ([self isMemberOfClass:[AbstractChatNotificationCell class]])
    {
        NSAssert(NO, @"Don't use AbstractChatNotificationCell directly. Use it's subclasses instead");
        return nil;
    }

    self = [super initWithFrame:frame];
    if (self)
    {
        self.notification = [[ChatNotification alloc] initWithFrame:CGRectZero text:text];
        self.notification.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.notification];

        self.notificationTop = [NSLayoutConstraint constraintWithItem:self.notification
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self
                                                            attribute:NSLayoutAttributeTop
                                                           multiplier:1.0f
                                                             constant:9.0f];

        self.notificationBottom = [NSLayoutConstraint constraintWithItem:self.notification
                                                               attribute:NSLayoutAttributeBottom
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self
                                                               attribute:NSLayoutAttributeBottom
                                                              multiplier:1.0f
                                                                constant:-9.0f];

        self.notificationTrailing = [NSLayoutConstraint constraintWithItem:self.notification
                                                                 attribute:NSLayoutAttributeTrailing
                                                                 relatedBy:NSLayoutRelationLessThanOrEqual
                                                                    toItem:self
                                                                 attribute:NSLayoutAttributeTrailing
                                                                multiplier:1.0f
                                                                  constant:-16.0f];

        [self addConstraint:self.notificationTop];
        [self addConstraint:self.notificationBottom];
        [self addConstraint:self.notificationTrailing];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat horizontalSpaces = (CGFloat)(fabs(self.notificationLeading.constant) + fabs(self.notificationTrailing.constant));
    CGFloat verticalSpaces = (CGFloat)(fabs(self.notificationTop.constant) + fabs(self.notificationBottom.constant));

    CGSize maxNotificationSize = size;
    maxNotificationSize.width -= horizontalSpaces;
    maxNotificationSize.height -= verticalSpaces;

    CGSize sizeThatFits = [self.notification sizeThatFits:maxNotificationSize];

    sizeThatFits.width += horizontalSpaces;
    sizeThatFits.height += verticalSpaces;

    return sizeThatFits;
}

@end

@interface ChatNotificationCell()

@property (nonatomic, strong) NSLayoutConstraint * notificationCenterX;

@end

@implementation ChatNotificationCell

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text
{
    self = [super initWithFrame:frame text:text];
    if (self)
    {
        self.notificationCenterX = [NSLayoutConstraint constraintWithItem:self.notification
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.0f
                                                                 constant:0.0f];

        self.notificationLeading = [NSLayoutConstraint constraintWithItem:self.notification
                                                                attribute:NSLayoutAttributeLeading
                                                                relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeLeading
                                                               multiplier:1.0f
                                                                 constant:16.0f];

        [self addConstraint:self.notificationCenterX];
        [self addConstraint:self.notificationLeading];
    }
    return self;
}

@end

@implementation ChatTypingCell

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text
{
    self = [super initWithFrame:frame text:text];
    if (self)
    {
        self.notification.titleLabel.numberOfLines = 1;
        self.notificationLeading = [NSLayoutConstraint constraintWithItem:self.notification
                                                                attribute:NSLayoutAttributeLeading
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeLeading
                                                               multiplier:1.0f
                                                                 constant:16.0f];

        [self addConstraint:self.notificationLeading];
    }
    return self;
}

@end