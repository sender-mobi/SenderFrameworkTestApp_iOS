//
// Created by Roman Serga on 9/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "UIImageView+EntityImage.h"
#import "EntityViewModel.h"
#import <SDWebImage/UIView+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

@implementation UIImageView (EntityImage)

NSURL * encodedURLWithString(NSString * string)
{
    if (!string) return nil;
    NSString * encodedString = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString: encodedString];
}

- (void)setImageOfViewModel:(id<EntityViewModel>)viewModel
{
    [self sd_cancelCurrentImageLoad];

    self.backgroundColor = viewModel.defaultImageBackgroundColor;
    UIImage * defaultImage = viewModel.defaultImage;

    if (viewModel.imageURL )
    {
        [self sd_setImageWithURL:viewModel.imageURL
                placeholderImage:defaultImage
                       completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                           self.backgroundColor = viewModel.imageBackgroundColor;
                       }];
    }
    else
    {
        self.image = defaultImage;
    }
}

@end