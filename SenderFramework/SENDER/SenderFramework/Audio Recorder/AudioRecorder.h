//
//  AudioRecorder.h
//  SENDER
//
//  Created by Nick Gromov on 10/24/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioRecorder : NSObject <AVAudioRecorderDelegate>

+ (AudioRecorder *)sharedInstance;
- (void)startRecord;
- (void)stopRecord;
- (NSData *)getFileData;
- (void)deleteFile;
- (BOOL)convertToMp3;

- (BOOL)playWithDelegate:(id<AVAudioPlayerDelegate>)delegate;
- (BOOL)playWithDelegate:(id<AVAudioPlayerDelegate>)delegate fromPath:(NSURL *)filePath;
- (void)stopPlay;
- (BOOL)playerStatus;
- (float)getFileDuration;
- (float)getDuration:(NSURL *)url;

- (NSTimeInterval)currentTime:(id)delegate;
- (void)playAudioFormUrl:(NSString *)fileURL;

@end
