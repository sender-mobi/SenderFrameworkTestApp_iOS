//
//  FileManager.h
//  SENDER
//
//  Created by Nick Gromov on 10/27/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

extern NSString * const SNotificationFileDidDownload;

@interface FileManager : NSObject {
    NSString * documentsDirectory;
}

@property (nonatomic, strong) NSString * lastRecorderAudioDuration;

+ (FileManager *)sharedFileManager;

- (NSString *)documentsDirectory;
- (NSData *)getFileData:(File *)file;
- (void)downloadDataForMessage:(Message *)message;
- (void)downloadVideoPreviewForMessage:(Message *)message;
- (void)downloadOwnerImage:(NSString *)urlString;
- (BOOL)saveData:(NSData *)data byServerUrl:(NSString *)url;
- (BOOL)saveData:(NSData *)data toFile:(NSString *)fileName;
- (BOOL)saveData:(NSData *)data toMessage:(NSString *)messageId;
- (BOOL)savePreviewImage:(NSData *)previewImageData toMessage:(NSString *)messageId;
- (BOOL)saveImageData:(NSData *)data toPhotosAlbum:(NSString *)messageId isLocal:(BOOL)isLocal;
- (BOOL)deleteFile:(File *)file;
- (BOOL)isFileExists:(File *)file;
- (NSData *)createPreviewImage:(NSData *)imageData;

@end
