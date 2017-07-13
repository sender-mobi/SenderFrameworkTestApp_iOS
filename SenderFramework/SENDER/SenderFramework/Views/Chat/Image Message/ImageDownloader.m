//
//  ImageDownloader.m
//  SENDER
//
//  Created by Eugene on 1/5/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "ImageDownloader.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ServerFacade.h"
#import "FileManager.h"

@implementation ImageDownloader

- (id)initWithModel:(Message *)model
{
    if (self) {
        _imageModel = model;
        [self startDownload];
    }
    return self;
}

- (void)startDownload
{
    [[ServerFacade sharedInstance] downloadFileWithBlock:^(NSData *data) {
        if ([[FileManager sharedFileManager] saveImageData:data toPhotosAlbum:_imageModel.moId isLocal:NO])
        {
            _imageModel.file.isDownloaded = [NSNumber numberWithBool:YES];
           [self finishDownload];
        }
    } forUrl:_imageModel.file.url];
}

- (void)finishDownload
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishDownloadingImage:)]) {
        [self.delegate didFinishDownloadingImage:self];
    }
}

@end

