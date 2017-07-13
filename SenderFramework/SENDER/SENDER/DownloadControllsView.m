//
//  DownloadControllsView.m
//  SENDER
//
//  Created by Roman Serga on 7/4/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "DownloadControllsView.h"

@implementation DownloadControllsView
{
    CAShapeLayer * circleLayer;
    CGFloat circleRadius;
    CGFloat buttonRadius;
    
    UIButton * mainButton;
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        circleLayer = [CAShapeLayer layer];
        
        circleRadius = (self.frame.size.height <= self.frame.size.width ? self.frame.size.height : self.frame.size.height)/2;
        circleLayer.frame = self.bounds;
        circleLayer.lineWidth = 2.0f;
        
        buttonRadius = circleRadius;
        
        mainButton = [[UIButton alloc]initWithFrame:CGRectMake((self.frame.size.width - 2 * buttonRadius)/2, (self.frame.size.height - 2 * buttonRadius)/2 , 2 * buttonRadius, 2 * buttonRadius)];
        mainButton.layer.cornerRadius = buttonRadius;
        [self addSubview:mainButton];
        mainButton.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.9];
        mainButton.hidden = YES;
        
        circleLayer.fillColor = [UIColor clearColor].CGColor;
        circleLayer.strokeColor = [UIColor redColor].CGColor;
        
        [self.layer addSublayer:circleLayer];
    }
    return self;
}

- (void)startDownloading
{
    self.progress = 0.0f;
    mainButton.hidden = NO;
    [self showPauseButton];
}

- (void)showPauseButton
{
    [mainButton setImage:[UIImage imageNamed:@"_resend"] forState:UIControlStateNormal];
    [mainButton removeTarget:self action:@selector(resumeLoading) forControlEvents:UIControlEventTouchUpInside];
    [mainButton addTarget:self action:@selector(pauseLoading) forControlEvents:UIControlEventTouchUpInside];
}

- (void)showResumeButton
{
    [mainButton setImage:[UIImage imageNamed:@"_resend"] forState:UIControlStateNormal];
    [mainButton removeTarget:self action:@selector(pauseLoading) forControlEvents:UIControlEventTouchUpInside];
    [mainButton addTarget:self action:@selector(resumeLoading) forControlEvents:UIControlEventTouchUpInside];
}

- (void)pauseLoading
{
    if ([self.delegate respondsToSelector:@selector(downloadControllsViewDidPressPause)])
    {
        [self.delegate downloadControllsViewDidPressPause];
        [self showResumeButton];
    }
}

- (void)resumeLoading
{
    if ([self.delegate respondsToSelector:@selector(downloadControllsViewDidPressResume)])
    {
        [self.delegate downloadControllsViewDidPressResume];
        [self showPauseButton];
    }
}

- (void)layoutSubviews
{
    CGRect circleFrame = CGRectMake((self.frame.size.width - 2 * circleRadius)/2, (self.frame.size.height - 2 * circleRadius)/2 , 2 * circleRadius, 2 * circleRadius);
    
    UIBezierPath * path = [UIBezierPath bezierPathWithOvalInRect:circleFrame];
    
    circleLayer.frame = self.bounds;
    circleLayer.path = path.CGPath;
}

- (void)setColor:(UIColor *)color
{
    circleLayer.strokeColor = color.CGColor;
}

- (void)setProgress:(CGFloat)progress
{
    if (progress > 1)
        circleLayer.strokeEnd = 1;
    else if (progress < 0)
        circleLayer.strokeEnd = 0;
    else
        circleLayer.strokeEnd = progress;
}

@end
