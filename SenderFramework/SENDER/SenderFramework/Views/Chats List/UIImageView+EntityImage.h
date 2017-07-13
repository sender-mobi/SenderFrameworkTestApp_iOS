//
// Created by Roman Serga on 9/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EntityViewModel;

@interface UIImageView (EntityImage)

- (void)setImageOfViewModel:(id<EntityViewModel>)viewModel;

@end