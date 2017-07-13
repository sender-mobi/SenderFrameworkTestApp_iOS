//
//  VideoDownloader.m
//  SENDER
//
//  Created by Eugene on 12/12/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "VideoDownloader.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation VideoDownloader

- (id)initWithModel:(Message *)model
{
    if (self) {
        _videoModel = model;
        [self startDownload];
    }
    return self;
}

- (void)startDownload
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSError * error;
            NSString * url = [_videoModel.file.url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSData * videoData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url] options:NSDataReadingUncached error:&error];
            
            if (!videoData) {
                return ;
            }
            
            NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString * documentsDirectory = [paths objectAtIndex:0];
            NSString * tempPath = [documentsDirectory stringByAppendingFormat:@"/%@.mp4",[NSDate date]];
            NSURL * outURL = [NSURL fileURLWithPath:tempPath];
            BOOL success = [videoData writeToFile:tempPath atomically:YES];
            
            if (success) {
                ALAssetsLibrary * library = [[ALAssetsLibrary alloc] init];
                
                [library writeVideoAtPathToSavedPhotosAlbum:outURL completionBlock:^(NSURL * assetURL, NSError *error){
                    if (!error) {
                        // NSLog(@"DONE DOQNLOADS AND WRITE!");
                        
                        NSError * error = nil;
                        [[NSFileManager defaultManager] removeItemAtPath:tempPath error:&error];
                        
                        NSString * albumName = @"SENDER";
                        __block BOOL albumWasFound = NO;
                        
                        [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                               usingBlock:^(ALAssetsGroup *group, BOOL *stop){
                                                   if ([albumName compare: [group valueForProperty:ALAssetsGroupPropertyName]]==NSOrderedSame)
                                                   {
                                                       albumWasFound = YES;
                                                       [library assetForURL: assetURL resultBlock:^(ALAsset *asset) {
                                                           [group addAsset: asset];
                                                       } failureBlock:^(NSError *error) {
                                                           if (error) {
                                                               // TODO: error handling
                                                           }}];
                                                       return;
                                                   }
                                                   if (group==nil && albumWasFound==NO)
                                                   {
                                                       __weak ALAssetsLibrary* weakSelf = library;
                                                       [library addAssetsGroupAlbumWithName:albumName
                                                                                resultBlock:^(ALAssetsGroup *group) {
                                                                                    [weakSelf assetForURL: assetURL
                                                                                              resultBlock:^(ALAsset *asset) {
                                                                                                  [group addAsset: asset];
                                                                                              } failureBlock:^(NSError *error) {
                                                                                                  if (error) {
                                                                                                      // TODO: error handling
                                                                                                  }
                                                                                              }];} failureBlock:^(NSError *error) {
                                                                                                  if (error) {
                                                                                                      // TODO: error handling
                                                                                                  }
                                                                                              }];
                                                       return;
                                                   }
                                               }failureBlock:^(NSError *error) {
                                                   if (error) {
                                                       // TODO: error handling
                                                   }
                                               }];

                        dispatch_async(dispatch_get_main_queue(), ^(void) {
                            
                            _videoModel.file.localUrl = assetURL.absoluteString;
                            [self finishDownload];
                            
                        });
                    }
                }];
            }
        }
    });
}

- (void)finishDownload
{
    if ([self.delegate respondsToSelector:@selector(didFinishDownloadingVideo:)])
        [self.delegate didFinishDownloadingVideo:self];
}

@end
