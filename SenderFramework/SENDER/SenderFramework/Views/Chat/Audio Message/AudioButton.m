//
//  AudioButton.m
//  SENDER
//
//  Created by Eugene on 11/7/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import "AudioButton.h"
#import "ParamsFacade.h"

@implementation AudioButton

- (id)initWithFrame:(CGRect)frame forModel:(Message *)model
{
    if (self)
    {
        NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
        self = [[NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"AudioButton" owner:self options:nil] objectAtIndex:0];
        self.frame = frame;
        isPlaying = NO;
        localModel = model;
        [self setupPlayer];
        playButton.tintColor = [SenderCore sharedCore].stylePalette.mainTextColor;
        counter.textColor = [SenderCore sharedCore].stylePalette.mainTextColor;
    }
    return self;
}

- (void)setupPlayer
{
    progressView.progress = 0;
    [playButton setImage:[self imgForButton] forState:UIControlStateNormal];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopPlaying)
                                                 name:@"stopPlayingAudio"
                                               object:nil];
}

- (UIImage *)imgForButton
{
    return [[UIImage imageFromSenderFrameworkNamed:[self imageForMode]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (NSString *)imageForMode
{
    if (isPlaying) {
        return @"_pause_s";
    }
   return @"_play_s";
}

- (void)stopPlaying
{
    if ([[AudioRecorder sharedInstance] playerStatus])
        [[AudioRecorder sharedInstance] stopPlay];
    isPlaying = NO;
    [playButton setImage:[self imgForButton] forState:UIControlStateNormal];
    [playTimer invalidate];
    playTimer = nil;
    counter.text = localModel.file.duration;
}

- (IBAction)playRecordedAudio:(id)sender
{
    progressView.progress = 0;
    if ([[AudioRecorder sharedInstance] playerStatus]) {
        [self stopPlaying];
        return;
    }
    
    if ([[AudioRecorder sharedInstance] playWithDelegate:self fromPath:localModel.file.getFileUrl])
    {
        isPlaying = YES;
        [playButton setImage:[self imgForButton] forState:UIControlStateNormal];
        
        playTimer = [NSTimer
                     scheduledTimerWithTimeInterval:0.1
                     target:self selector:@selector(timerFired:)
                     userInfo:nil repeats:YES];
    }
}

- (void)timerFired:(NSTimer*)timer
{
    [self updateDisplay];
}

- (void)updateDisplay
{
    NSTimeInterval currentTime = [[AudioRecorder sharedInstance] currentTime:self];
    
    if (currentTime < 0) {
        [self stopPlaying];
        return;
    }
    
    counter.text = [[NSString stringWithFormat:@"%.02f", currentTime/100]stringByReplacingOccurrencesOfString:@"." withString:@":"];
    progressIncrase = (currentTime/(durationOfRecordedFile - 0.3));
    progressView.progress = progressIncrase;
}

#pragma mark - AVAudioPlayerDelegate

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    progressView.progress = 0;
    [playTimer invalidate];
    playTimer = nil;
    isPlaying = NO;
    [playButton setImage:[self imgForButton] forState:UIControlStateNormal];
}

- (void)updateDurationLabel
{
    if (!localModel.file.duration) {
        AVAsset * asset = [AVURLAsset assetWithURL:localModel.file.getLocalFileURL];
        [asset loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^{
            durationOfRecordedFile = CMTimeGetSeconds(asset.duration) / 100;
            localModel.file.duration = [[NSString stringWithFormat:@"%.02f", durationOfRecordedFile]stringByReplacingOccurrencesOfString:@"." withString:@":"];
            dispatch_async(dispatch_get_main_queue(), ^{
                counter.text = localModel.file.duration;
            });
        }];
    }
    else
    {
        counter.text = localModel.file.duration;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
