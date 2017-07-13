//
//  AudioCellView.h
//  SENDER
//
//  Created by Eugene on 1/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"

@interface AudioCellView : UIView

- (void)initWithModel:(Message *)submodel width:(CGFloat)maxWidth timeLabelSize:(CGSize)timeLabelSize;
- (void)fixWidthForTimeLabelSize:(CGSize)timeSize maxWidth:(CGFloat)maxWidth;

@property (nonatomic, strong) Message * viewModel;

@end
