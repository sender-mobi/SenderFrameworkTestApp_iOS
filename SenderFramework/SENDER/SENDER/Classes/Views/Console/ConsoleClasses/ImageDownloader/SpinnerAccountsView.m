//
//  SpinnerAccountsView.m
//  Privat24
//
//  Created by Eugene Gilko on 27.07.14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "SpinnerAccountsView.h"
#import <QuartzCore/QuartzCore.h>

const int kSpinnerAccountsViewTag = 10293800;

@implementation SpinnerAccountsView


-(NSInteger)framesPerSecond
{
    if (!_framesPerSecond)
    {
        _framesPerSecond = 20;
    }
    return _framesPerSecond;
}

-(UIImageView *)imgViewSpinner
{
    if (!_imgViewSpinner)
    {
        _imgViewSpinner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AccountsSpinner"]];
        [self addSubview:_imgViewSpinner];
        _imgViewSpinner.backgroundColor = [UIColor clearColor];
        
        CGRect tmpFrame = _imgViewSpinner.frame;
        
        if (tmpFrame.size.height > self.frame.size.height)
        {
            tmpFrame = self.bounds;
        }
        else
        {
            tmpFrame.size = CGSizeMake(44, 44);
            tmpFrame.origin.x = self.bounds.size.width/2 - tmpFrame.size.width/2;
            tmpFrame.origin.y = self.bounds.size.height/2 - tmpFrame.size.height/2;
        }
        
        _imgViewSpinner.frame = tmpFrame;
    }
    return _imgViewSpinner;
}

-(void)startAnimation
{
    CATransform3D rotationTransform = CATransform3DMakeRotation(M_2_SQRTPI, 0.0f, 0.0f, 1.0);
    CABasicAnimation* rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    rotationAnimation.toValue = [NSValue valueWithCATransform3D:rotationTransform];
    rotationAnimation.duration = 1/self.framesPerSecond;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = NSIntegerMax;
    rotationAnimation.removedOnCompletion = NO;
    
    [self.imgViewSpinner.layer addAnimation:rotationAnimation forKey:@"transform"];
}

-(void)stopAnimation
{
    [self.imgViewSpinner.layer removeAllAnimations];
}

+(SpinnerAccountsView *)spinnerView
{
    return [self spinerViewWithFrame:[UIScreen mainScreen].bounds];
}

+ (SpinnerAccountsView *)spinerViewWithFrame:(CGRect)frame
{
    SpinnerAccountsView* tmpProgress = [[SpinnerAccountsView alloc] initWithFrame:frame];
    tmpProgress.backgroundColor = [UIColor clearColor];
    tmpProgress.tag = kSpinnerAccountsViewTag;
    return tmpProgress;
}

- (void)dealloc
{
    [self stopAnimation];
}

@end
