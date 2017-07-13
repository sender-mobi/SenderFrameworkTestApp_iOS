//
//  VideoMenager.m
//  SENDER
//
//  Created by Eugene on 12/11/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "VideoManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CoreDataFacade.h"
#import "FileManager.h"
#import "ServerFacade.h"
#import <AVFoundation/AVFoundation.h>

@implementation VideoManager
{
    __weak UIViewController * parentController;
    MPMoviePlayerController * moviePlayer;
    UIImage * finalImage;
    NSURL * videoOutURL;
    float durationOfFile;
    NSData * outPutData;
    NSString * chatIdToSend;
}

- (id)initWithParentController:(UIViewController *)controller chatId:(NSString *)chatId;
{
    if (self = [super init]) {
        parentController = controller;
        chatIdToSend = chatId;
    }
    return self;
}

- (void)showCamera
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
    picker.delegate = self;
    
    picker.allowsEditing = NO;
    //   picker.showsCameraControls = NO;
    //        picker.navigationBarHidden = YES;
    //        picker.toolbarHidden = YES;
    
    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    
    [parentController presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSURL * videoURL = info[UIImagePickerControllerMediaURL];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    AVAsset * video = [AVAsset assetWithURL:videoURL];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:video presetName:AVAssetExportPresetPassthrough];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeMPEG4;
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * tempPath = [documentsDirectory stringByAppendingFormat:@"/%@.mp4",[NSDate date]];
    NSURL * outURL = [NSURL fileURLWithPath:tempPath];
    exportSession.outputURL = outURL;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        // LLog(@"DONE processing video!");
        
        ALAssetsLibrary * library = [[ALAssetsLibrary alloc] init];
        
        [library writeVideoAtPathToSavedPhotosAlbum:outURL completionBlock:^(NSURL * assetURL, NSError *error){
            if (!error) {
                // LLog(@"DONE WRITE!");
                
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:tempPath error:&error];
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    
                    [self getVideoThumbnail:assetURL];
                });
            }
        }];
    }];
}

- (void)getVideoThumbnail:(NSURL *)videoURL
{
    videoOutURL = videoURL;
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], AVURLAssetPreferPreciseDurationAndTimingKey, nil]];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    NSTimeInterval durationInSeconds = 0.0;
    if (asset)
        durationInSeconds = CMTimeGetSeconds(asset.duration);
    durationOfFile = durationInSeconds;
    asset = nil;
    
    generator.appliesPreferredTrackTransform=TRUE;
    CMTime thumbTime = CMTimeMakeWithSeconds(0,30);
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result != AVAssetImageGeneratorSucceeded) {
            // LLog(@"couldn't generate thumbnail, error:%@", error);
        }
        UIImage * thumbnail = [UIImage imageWithCGImage:im];
        if (thumbnail != nil){
            finalImage = thumbnail;
        }
        [self sendDataToServer];
    };
    
    CGSize maxSize = CGSizeMake(600, 600);
    generator.maximumSize = maxSize;
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
    
}

- (void)sendDataToServer
{
    finalImage = [self squareImageWithImage:finalImage scaledToSize:CGSizeMake(300, 300)];
    
    NSData * imageData = UIImageJPEGRepresentation(finalImage, 0.6);
    
    [[ServerFacade sharedInstance] sendVideoMessage:outPutData fromLocalURL:videoOutURL imageData:imageData videoDuration:durationOfFile chatId:chatIdToSend completionHandler:^(NSDictionary *response, NSError *error) {
        if (!error) {
            
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (UIImage *)squareImageWithImage:(UIImage *)curImage scaledToSize:(CGSize)newSize {
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.height);
    
    CGRect clipRect = CGRectMake(0, 0,
                                 (curImage.size.width),
                                 (curImage.size.height));
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [curImage drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}


@end
