//
//  CommonTextMessageView.h
//  SENDER
//
//  Created by Roman Serga on 12/1/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"

@interface CommonTextMessageView : UIView
{
    @protected
    
    UITextView * messageTextView;
    UIImageView * leftIcon;
    UIView * labelBackground;
}

- (void)initWithModel:(Message *)submodel width:(CGFloat)maxWidth timeLabelSize:(CGSize)timeLabelSize;
- (void)fixWidthForTimeLabelSize:(CGSize)timeSize maxWidth:(CGFloat)maxWidth;

- (void)setLeftIcon:(UIImage *)leftIconImage;
- (void)setText:(NSString *)text;

@property (nonatomic, strong) Message * viewModel;
@property (nonatomic) BOOL leftIconHidden;

@end
