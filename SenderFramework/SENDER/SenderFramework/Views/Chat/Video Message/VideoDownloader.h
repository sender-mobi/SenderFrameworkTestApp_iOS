//
//  VideoDownloader.h
//  SENDER
//
//  Created by Eugene on 12/12/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

@class VideoDownloader;

@protocol VideoDownloaderDelegate <NSObject>

- (void)didFinishDownloadingVideo:(VideoDownloader *)videoDownloader;

@end

@interface VideoDownloader : NSObject

@property (nonatomic, assign)id<VideoDownloaderDelegate> delegate;

- (id)initWithModel:(Message *)model;

@property (nonatomic, strong) Message * videoModel;

@end