//
//  ImageDownloader.h
//  SENDER
//
//  Created by Eugene on 1/5/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

@class ImageDownloader;

@protocol ImageDownloaderDelegate <NSObject>

- (void)didFinishDownloadingImage:(ImageDownloader *)videoDownloader;

@end

@interface ImageDownloader : NSObject

@property (nonatomic, assign)   id<ImageDownloaderDelegate> delegate;

- (id)initWithModel:(Message *)model;

@property (nonatomic, strong) Message * imageModel;

@end