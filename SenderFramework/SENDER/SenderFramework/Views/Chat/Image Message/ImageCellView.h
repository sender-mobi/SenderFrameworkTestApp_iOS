//
//  ImageCellView.h
//  SENDER
//
//  Created by Eugene on 1/7/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"
#import "ImageDownloader.h"

extern NSString * const ShowFullScreenPicture;

@interface ImageCellView : UIView <ImageDownloaderDelegate>

- (void)initWithModel:(Message *)submodel width:(CGFloat)maxWidth timeLabelSize:(CGSize)timeLabelSize;
- (void)fixWidthForTimeLabelSize:(CGSize)timeSize maxWidth:(CGFloat)maxWidth;

@property (nonatomic, strong) Message * viewModel;
@end
