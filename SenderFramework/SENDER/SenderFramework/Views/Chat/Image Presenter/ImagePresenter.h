//
// Created by Roman Serga on 24/6/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ImagePresenter;

@protocol ImageModuleDelegate <NSObject>

-(void)imagePresenter:(ImagePresenter *)presenter didDismissed:(BOOL)unused;

@end

@interface ImagePresenter : NSObject <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView * zoomingScrollView;
@property (nonatomic, strong) UIWindow * presentationWindow;

@property (nonatomic, weak) id<ImageModuleDelegate> delegate;
@property (nonatomic) BOOL isPresentingImage;

-(void)presentWindowWithImageWithLocalURL:(NSURL *)URL withTransformFromFrame:(CGRect)fromFrame toFrame:(CGRect)toFrame;
-(void)dismissWindowWithImage;

@end