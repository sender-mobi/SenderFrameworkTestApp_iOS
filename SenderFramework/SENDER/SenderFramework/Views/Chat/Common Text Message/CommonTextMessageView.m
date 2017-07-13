//
//  CommonTextMessageView.m
//  SENDER
//
//  Created by Roman Serga on 12/1/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "CommonTextMessageView.h"
#import "PBConsoleConstants.h"
#import "ParamsFacade.h"
#import "NSString+EmojiHelpers.h"

#define contentSideOffset 4.0f
#define contentTopOffset 0.0f
#define imageSideOffset 10.0f
#define imageTopOffset 10.0f

@interface CommonTextMessageView ()

@property (nonatomic) CGFloat maxWidth;
@property (nonatomic) CGSize timeLabelSize;

@end

@implementation CommonTextMessageView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initWithModel:(Message *)submodel width:(CGFloat)maxWidth timeLabelSize:(CGSize)timeLabelSize
{
    self.viewModel = submodel;
    
    if (self)
    {
        leftIcon = [[UIImageView alloc] initWithFrame:CGRectMake(imageSideOffset, imageTopOffset, 17.0f, 17.0f)];
        
        self.maxWidth = maxWidth;
        self.timeLabelSize = timeLabelSize;
        
        messageTextView = [[UITextView alloc] init];

        [messageTextView setFont:[[SenderCore sharedCore].stylePalette inputTextFieldFontStyle:nil andSize:16]];
        messageTextView.textColor = self.viewModel.owner ? [SenderCore sharedCore].stylePalette.mainTextColor : [SenderCore sharedCore].stylePalette.mainTextColor;

        messageTextView.backgroundColor = [UIColor clearColor];
        messageTextView.scrollEnabled = NO;
        messageTextView.editable = NO;
        
        [messageTextView addSubview:leftIcon];
        [self addSubview:messageTextView];
    }
}

-(void)setLeftIconHidden:(BOOL)leftIconHidden
{
    _leftIconHidden = leftIconHidden;
    leftIcon.hidden = leftIconHidden;
    
    [self fixWidthForTimeLabelSize:self.timeLabelSize maxWidth:self.maxWidth];
}

- (void)setLeftIcon:(UIImage *)leftIconImage
{
    leftIcon.image = leftIconImage;
}

- (void)setText:(NSString *)text
{
    [messageTextView setText:text];
    
    UIFont * font = [[SenderCore sharedCore].stylePalette inputTextFieldFontStyle:nil andSize:15];
    bool isEmoji = NO;
    
    if ([text isSingleEmoji])
    {
        font = [UIFont fontWithName:@"AppleColorEmoji" size:37.0];
        isEmoji = YES;
    }
    
    [messageTextView setFont:font];
    if (isEmoji)
        [messageTextView setTextAlignment:NSTextAlignmentCenter];
    
    [self fixWidthForTimeLabelSize:self.timeLabelSize maxWidth:self.maxWidth];
}

- (void)fixWidthForTimeLabelSize:(CGSize)timeSize maxWidth:(CGFloat)maxWidth
{
    UIBezierPath * leftIconPath;

    if (self.leftIconHidden) {
        leftIconPath = [UIBezierPath bezierPathWithRect:CGRectZero];
    }
    else {
        leftIconPath = [UIBezierPath bezierPathWithRect:leftIcon.frame];
    }
    
    messageTextView.textContainer.exclusionPaths = @[leftIconPath];

    //First calculation to find aproximate timeLabel frame
    
    CGSize textSize = [self calculateTextSizeForTimeLabelSize:timeSize maxWidth:maxWidth];

    CGRect timeRect = CGRectMake(textSize.width - timeSize.width, textSize.height - timeSize.height, timeSize.width, timeSize.height);
    UIBezierPath *timePath = [UIBezierPath bezierPathWithRect:timeRect];
    
    messageTextView.textContainer.exclusionPaths = @[timePath, leftIconPath];
    
    //Second calculation for more accurate size
    textSize = [self calculateTextSizeForTimeLabelSize:timeSize maxWidth:maxWidth];
    
    timePath = [UIBezierPath bezierPathWithRect:CGRectMake(textSize.width - timeSize.width, textSize.height - timeSize.height, timeSize.width, timeSize.height)];
    
    messageTextView.textContainer.exclusionPaths = @[timePath, leftIconPath];

    CGFloat textHeight;
    if (textSize.height >= leftIcon.frame.size.height + 2 * imageTopOffset)
        textHeight = textSize.height;
    else
        textHeight = leftIcon.frame.size.height + 2 * imageTopOffset;
    messageTextView.frame = CGRectMake(contentSideOffset, contentTopOffset, textSize.width, textHeight);
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, messageTextView.frame.size.width + 2 * contentSideOffset, messageTextView.frame.size.height + 2 * contentTopOffset);
}


-(CGSize)calculateTextSizeForTimeLabelSize:(CGSize)timeSize maxWidth:(CGFloat)maxWidth
{
    CGSize newSize = [messageTextView sizeThatFits:CGSizeMake(maxWidth - 2 * contentSideOffset, FLT_MAX)];
    
    float intSize = (self.leftIconHidden) ? 15.0f : 42.0f;
    
    newSize.width = (newSize.width < intSize) ?  intSize: newSize.width;
    newSize.width += (newSize.width + timeSize.width <= maxWidth - 2 * contentSideOffset) ? timeSize.width : 0.0f;

    return newSize;
}

- (void)addTimeBackgroud
{
    labelBackground = [[UIView alloc]init];
    labelBackground.backgroundColor = self.viewModel.owner ? [SenderCore sharedCore].stylePalette.myMessageBackgroundColor : [SenderCore sharedCore].stylePalette.foreignMessageBackgroundColor;
    labelBackground.clipsToBounds = YES;
    [self addSubview:labelBackground];
}

@end
