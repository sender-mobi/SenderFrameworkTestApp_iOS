//
//  FileManager.m
//  SENDER
//
//  Created by Nick Gromov on 10/27/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "FileManager.h"
#import "ServerFacade.h"
#import "SenderNotifications.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define IMAGE_SIZE 170

NSString *const SNotificationFileDidDownload = @"SNotificationFileDidDownload";

@implementation FileManager

+ (FileManager *)sharedFileManager {
    static FileManager * fileManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fileManager = [[FileManager alloc] init];
    });
    
    return fileManager;
}

- (NSString *)documentsDirectory {
    if (documentsDirectory) {
        return documentsDirectory;
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    documentsDirectory = [documentsDirectory stringByAppendingPathComponent:@"AudioFiles"];
    
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    
    return documentsDirectory;
}

- (NSData *)getFileData:(File *)file {
    NSString *fullPath = [[self documentsDirectory] stringByAppendingPathComponent:file.getFilePathName];
    return [NSData dataWithContentsOfFile:fullPath];
}

- (void)downloadDataForMessage:(Message *)message
{
//    NSString * fileName = message.file.getFilePathName;
    [[ServerFacade sharedInstance] downloadFileWithBlock:^(NSData *data) {
        
        if (message && [self saveData:data toMessage:message.moId])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:SNotificationFileDidDownload object:message.moId];
        }
    } forUrl:message.file.url];
}

- (void)downloadVideoPreviewForMessage:(Message *)message
{
    //    NSString * fileName = message.file.getFilePathName;
    [[ServerFacade sharedInstance] downloadFileWithBlock:^(NSData *data) {
        if (message && [self saveData:data toMessage:message.moId])
        {
            message.file.isDownloaded = [NSNumber numberWithBool:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:SNotificationFileDidDownload object:message.moId];
        }
    } forUrl:message.file.prev_url];
}

- (void)downloadOwnerImage:(NSString *)urlString
{
    [[ServerFacade sharedInstance] downloadFileWithBlock:^(NSData *data) {
        [[CoreDataFacade sharedInstance] setOwnerImageData:data];
    } forUrl:urlString];
}

- (BOOL)saveData:(NSData *)data byServerUrl:(NSString *)url
{
    if (!url)
        return NO;
    NSArray * subs = [url componentsSeparatedByString:@"."];
    return [self saveData:data toFile:[[NSString stringWithFormat:@"%lu",(unsigned long)[url hash]]stringByAppendingPathExtension:[subs lastObject]]];
}

- (BOOL)saveData:(NSData *)data toMessage:(NSString *)messageId
{
    Message * message = [[CoreDataFacade sharedInstance] messageById:messageId];
    
    if (!message) {
        return NO;
    }
    
    NSString *fullPath = [[self documentsDirectory] stringByAppendingPathComponent:message.file.getFilePathName];
    NSError *error;
    BOOL success = [data writeToFile:fullPath options:NSDataWritingAtomic error:&error];
    if (!success) {
        // NSLog(@"Error creating data path: %@", [error localizedDescription]);
        return NO;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        message.file.isDownloaded = @YES;
        [[CoreDataFacade sharedInstance] saveContext];
    });
  
    return YES;
}

- (BOOL)savePreviewImage:(NSData *)previewImageData toMessage:(NSString *)messageId
{
    Message * message = [[CoreDataFacade sharedInstance] messageById:messageId];
    NSString * fullPath = [[self documentsDirectory] stringByAppendingPathComponent:message.file.getFilePathName];
    message.file.prev_url = fullPath;
    
    NSError *error;
    BOOL success = [previewImageData writeToFile:fullPath options:NSDataWritingAtomic error:&error];
    if (!success) {
        // NSLog(@"Error creating data path: %@", [error localizedDescription]);
        return NO;
    }
    message.file.isDownloaded = @YES;
    [[CoreDataFacade sharedInstance] saveContext];
    return YES;
}

- (BOOL)saveData:(NSData *)data toFile:(NSString *)fileName {
    NSString *fullPath = [[self documentsDirectory] stringByAppendingPathComponent:fileName];
    NSError *error;
    BOOL success = [data writeToFile:fullPath options:NSDataWritingAtomic error:&error];
    if (!success) {
        // NSLog(@"Error creating data path: %@", [error localizedDescription]);
        return NO;
    }
    return YES;
}

- (BOOL)saveImageData:(NSData *)data toPhotosAlbum:(NSString *)messageId isLocal:(BOOL)isLocal
{
    ALAssetsLibrary * library = [[ALAssetsLibrary alloc] init];
//    UIImage * image = [UIImage imageWithData:data];
    __block BOOL returnBool = YES;
    NSString * albumName = @"SENDER";
    [library writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            // TODO: error handling
            returnBool = NO;
        } else {

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
                                                returnBool = NO;
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
                                                                                    returnBool = NO;
                                                                                }
                                                                            }];} failureBlock:^(NSError *error) {
                                                                                if (error) {
                                                                                    // TODO: error handling
                                                                                    returnBool = NO;
                                                                                }
                                                                            }];
                                        return;
                                    }
                                }failureBlock:^(NSError *error) {
                                    if (error) {
                                        // TODO: error handling
                                        returnBool = NO;
                                    }
                                }];
            [[CoreDataFacade sharedInstance] setLocalUrl:assetURL.absoluteString toMessage:messageId];
            if (isLocal) {
                [[CoreDataFacade sharedInstance] setUploadUrl:assetURL.absoluteString toMessage:messageId];
                [self savePreviewImage:data toMessage:messageId];
                [[NSNotificationCenter defaultCenter] postNotificationName:SNotificationFileDidDownload object:messageId];
            }
        }
    }];
    return returnBool;
}

- (BOOL)deleteFile:(File *)file {
    NSString *fullPath = [[self documentsDirectory] stringByAppendingPathComponent:file.getFilePathName];
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error];
    if (!success) {
        // NSLog(@"Error removing document path: %@", error.localizedDescription);
        return NO;
    }
    return YES;
}

- (BOOL)isFileExists:(File *)file
{
    NSString *fullPath = [[self documentsDirectory] stringByAppendingPathComponent:file.getFilePathName];
    return [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
}

- (NSData *)createPreviewImage:(NSData *)imageData
{
    UIImage * image = [UIImage imageWithData:imageData];
    CGSize size = image.size;
    if (size.height <= IMAGE_SIZE || size.width <= IMAGE_SIZE) {
        return imageData;
    }
    float coeff = size.height < size.width ? size.height/IMAGE_SIZE : size.width/IMAGE_SIZE;
    CGSize newSize = (CGSize){size.width/coeff, size.height/coeff};

    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    float x = 0, y = 0;
    if (newSize.height < newSize.width) {
        x = (newSize.width - newSize.height)/2;
    }
    else if (newSize.height > newSize.width) {
        y = (newSize.height - newSize.width)/2;
    }
    CGRect rect = CGRectMake(x, y, IMAGE_SIZE, IMAGE_SIZE);
    CGImageRef imageRef = CGImageCreateWithImageInRect([newImage CGImage], rect);
    UIImage * clipImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    image = nil;
    return UIImagePNGRepresentation(clipImage);
}

@end
