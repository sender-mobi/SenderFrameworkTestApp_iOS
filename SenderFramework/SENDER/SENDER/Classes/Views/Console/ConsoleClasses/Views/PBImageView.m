//
//  PBImageView.m
//  ZiZZ
//
//  Created by Eugene Gilko on 7/25/14.
//  Copyright (c) 2014 Dima Yarmolchuk. All rights reserved.
//

#import "PBImageView.h"
#import "UIImage+animatedGIF.h"
#import "SpinnerAccountsView.h"
#import "UIImageView+WebCache.h"
#import "File.h"

@interface PBImageView()
{
    UIImageView * imgView;
    SpinnerAccountsView * progAccountsView;
}

@end

@implementation PBImageView

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainConteinerModel *)submodel
{
    self.viewModel = submodel;
//    
//    float startX = 0;
//    if (mainRect.origin.x > 0)
//        startX = mainRect.origin.x;
    
    float widthImg = mainRect.size.width;
    
    float scaleRatio = 1;
    if ([self.viewModel.w floatValue] > mainRect.size.width) {
        scaleRatio = 0.5;
    }
    
    if (self.viewModel.w) {
        widthImg = (float)[self.viewModel.w floatValue];
    }
    
    float heightImg = (mainRect.size.height > 0) ? mainRect.size.height : 100;
    if (self.viewModel.h) {
        heightImg = (float)[self.viewModel.h floatValue];
    }
    
    self.frame = CGRectMake(0, 0, widthImg * scaleRatio, heightImg * scaleRatio);
    self.backgroundColor = [UIColor clearColor];
    
    [self imageWithRect:self.frame];
}

- (void)imageWithRect:(CGRect)mainRect
{
    imgView = [[UIImageView alloc] initWithFrame:mainRect];
    
    [imgView sd_setImageWithURL:[NSURL URLWithString:self.viewModel.src] placeholderImage:[UIImage imageNamed:@""]];
    [imgView setContentMode:UIViewContentModeScaleAspectFit];
    [self addSubview:imgView];
    [PBConsoleContans settingViewBorder:imgView andModel:self.viewModel];
}

@end
