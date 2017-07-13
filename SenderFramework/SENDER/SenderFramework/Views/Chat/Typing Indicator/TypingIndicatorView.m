//
//  TypingIndicatorView.m
//  SENDER
//
//  Created by Roman Serga on 13/8/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "TypingIndicatorView.h"
#import "PBConsoleConstants.h"

@interface TypingIndicatorView ()
{
    __weak IBOutlet UILabel * titleLabel;
    __weak IBOutlet UIImageView * bubbleBackground;
    __weak IBOutlet NSLayoutConstraint * titleLabelWidth;
}

@end

@implementation TypingIndicatorView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
        self = [[NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"TypingIndicatorView" owner:nil options:nil] objectAtIndex:0];
        if (CGSizeEqualToSize(frame.size , CGSizeZero))
        {
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, SCREEN_WIDTH, 44.0f);
            self.backgroundColor = [UIColor clearColor];
            titleLabel.font = [[SenderCore sharedCore].stylePalette inputTextFieldFontStyle:nil andSize:11.0f];
            titleLabel.textColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
            UIImage * bubbleImage = [[UIImage imageFromSenderFrameworkNamed:@"_bubble"]resizableImageWithCapInsets:UIEdgeInsetsMake(18.0f, 15.0f, 18.0f, 15.0f)];
            bubbleBackground.image = [bubbleImage imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
            bubbleBackground.tintColor = [SenderCore sharedCore].stylePalette.foreignMessageBackgroundColor;
            [self setTitleText:@""];
            [self layoutIfNeeded];
        }
    }
    return self;
}

- (void)setTitleText:(NSString *)text
{
    titleLabel.text = text;
    CGSize labelSize = [titleLabel sizeThatFits:CGSizeMake(self.frame.size.width - 68.0f, titleLabel.frame.size.height)];
    labelSize.width = (labelSize.width > self.frame.size.width - 68.0f) ? (self.frame.size.width - 68.0f) : labelSize.width;
    titleLabelWidth.constant = labelSize.width > 0.0f ? labelSize.width : titleLabelWidth.constant;
    [self layoutIfNeeded];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
}

@end
