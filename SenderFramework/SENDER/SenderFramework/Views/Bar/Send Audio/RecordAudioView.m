//
//  RecordAudioView.m
//  SENDER
//
//  Created by Eugene on 11/3/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "RecordAudioView.h"
#import "SenderNotifications.h"
#import "PBConsoleConstants.h"
#import "CoreDataFacade.h"
#import "ServerFacade.h"
#import "Message.h"
#import "FileManager.h"
#import "AVFoundation/AVAudioSession.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import <KAProgressLabel/KAProgressLabel.h>

@implementation RecordAudioView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
        self = [[NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"RecordAudioView" owner:nil options:nil] objectAtIndex:0];
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, SCREEN_WIDTH, self.frame.size.height);
        self.isSetUp = NO;
        [self layoutIfNeeded];
    }
    return self;
}

- (void)dealloc
{
//    recorder = nil;
}

- (void)setUpView
{
    self.isSetUp = YES;
    timerCount = 0;
    [self.pLabel setBackBorderWidth: 4.0];
    [self.pLabel setFrontBorderWidth: 9.0];
    [self.pLabel setColorTable: @{
                                  NSStringFromProgressLabelColorTableKey(ProgressLabelTrackColor):[UIColor clearColor],
                                  NSStringFromProgressLabelColorTableKey(ProgressLabelProgressColor):[[SenderCore sharedCore].stylePalette mainAccentColor]
                                  }];
    
    [self.startStopButton setTitleColor:[[SenderCore sharedCore].stylePalette mainAccentColor] forState:UIControlStateNormal];
    
    [self.playButton setImage:[UIImage imageFromSenderFrameworkNamed:@"play"] forState:UIControlStateNormal];
    
    recImage = [UIImage imageFromSenderFrameworkNamed:@"hold&talk_press"];
    stopImage = [UIImage imageFromSenderFrameworkNamed:@"hold&talk_normal"];
    [self changeRecBgImage:NO];
    [self showHideRecButtons:NO];
    
    CALayer *topBorder = [CALayer layer];
    topBorder.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, 1.0f);
    topBorder.backgroundColor = [[[SenderCore sharedCore].stylePalette mainAccentColor]colorWithAlphaComponent:0.2].CGColor;
    [self.layer addSublayer:topBorder];

    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!granted)
            {
                self.noInputAvailiableView.hidden = NO;
                self.noInputAvailiableLabel.text = SenderFrameworkLocalizedString(@"error_mic_not_available", nil);
                self.noInputAvailiableLabel.textColor = [[SenderCore sharedCore].stylePalette secondaryTextColor];
                [self.goToSettingsButton setTitle:SenderFrameworkLocalizedString(@"error_mic_not_available_go_to_settings", nil) forState:UIControlStateNormal];
                [self.goToSettingsButton setTitleColor:[[SenderCore sharedCore].stylePalette mainAccentColor] forState:UIControlStateNormal];
            }
            else
            {
                self.noInputAvailiableView.hidden = YES;
            }
        });
    }];
}

-(IBAction)goToSettings:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

- (void)localize
{
    [self.startStopButton setTitle:SenderFrameworkLocalizedString(@"click_and_talk_ios", nil)
                          forState:UIControlStateNormal];
}

- (void)updateCount
{
    timerCount += 0.015;
    [self.pLabel setProgress:timerCount];
}

- (IBAction)sendRecordToServer:(id)sender
{
    [self changeRecBgImage:NO];
    [self showHideRecButtons:NO];
    timerCount = 0;
    [self.pLabel setProgress:0];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL res = [[AudioRecorder sharedInstance]  convertToMp3];
        if (res)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate recordAudioViewDidRecordedTrack:[[AudioRecorder sharedInstance] getFileData]];
//                recorder = nil;
            });
        }
        else
        {
//            recorder = nil;
        }
    });
}

- (IBAction)cancelRecord:(id)sender
{
    [self stopPlaying];
    timerCount = 0;
    [self.pLabel setProgress:0];

    [self changeRecBgImage:NO];
    [self showHideRecButtons:NO];
//    recorder = nil;
}

- (IBAction)startRecordAudio:(id)sender
{
    if (!recMode) {
        recMode = YES;
    }
    else { recMode = NO; [self stopRecording]; return;}
    
    timerCount = 0;
    self.startStopButton.enabled = NO;
    // NSLog(@"start");
    [self.pLabel setProgress:0];
    self.sendButton.hidden = YES;
    self.playButton.hidden = YES;
    
//    recorder = [[AudioRecorder alloc] init];
    [[AudioRecorder sharedInstance] startRecord];
    [self changeRecBgImage:YES];
    
    repeatTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                 target:self
                                               selector:@selector(updateCount)
                                               userInfo:nil
                                                repeats:YES];
    mainTimer = [NSTimer scheduledTimerWithTimeInterval:29.5
                                                 target:self
                                               selector:@selector(stopRecording)
                                               userInfo:nil
                                                repeats:NO];
    [self performSelector:@selector(reEnableReccord) withObject:nil afterDelay:1.0];
}

- (void)reEnableReccord
{
    self.startStopButton.enabled = YES;
    [self.startStopButton setTitle:SenderFrameworkLocalizedString(@"Stop", nil) forState:UIControlStateNormal];
}

- (void)stopRepeatTimer
{
//    [self performSelector:@selector(reEnableReccord) withObject:nil afterDelay:1.0];
    // NSLog(@"stop");
    [repeatTimer invalidate];
    repeatTimer = nil;
    [mainTimer invalidate];
    mainTimer =  nil;
    durationOfRecordedFile = [[AudioRecorder sharedInstance]  getFileDuration];
    [self changeRecBgImage:NO];
    if (durationOfRecordedFile < 0.01) {
        
        [self.pLabel setProgress:0];
        [self showHideRecButtons:NO];
        return;
    }

    [self showHideRecButtons:YES];
    durationOfRecordedFileLabel.text = [NSString stringWithFormat:@"%.02f",durationOfRecordedFile];
    [FileManager sharedFileManager].lastRecorderAudioDuration = [NSString stringWithFormat:@"%f",durationOfRecordedFile];
    [self.startStopButton setTitle:SenderFrameworkLocalizedString(@"click_and_talk_ios", nil) forState:UIControlStateNormal];
}

- (IBAction)playRecordedAudio:(id)sender
{
    if ([[AudioRecorder sharedInstance]  playerStatus])
        [self stopPlaying];
    else
        [self startPlaying];
}

- (void)stopPlaying
{
    [[AudioRecorder sharedInstance]  stopPlay];
    [self.playButton setImage:[UIImage imageFromSenderFrameworkNamed:@"play"]
                     forState:UIControlStateNormal];
    [playTimer invalidate];
    playTimer = nil;
}

- (void)startPlaying
{
    if ([[AudioRecorder sharedInstance]  playWithDelegate:self])
    {
        [self.playButton setImage:[UIImage imageFromSenderFrameworkNamed:@"pause"]
                         forState:UIControlStateNormal];

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
    if (currentTime < 0) {return;}
    durationOfRecordedFileLabel.text = [NSString stringWithFormat:@"%.02f", currentTime];
}

#pragma mark - AVAudioPlayerDelegate

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [playTimer invalidate];
    playTimer = nil;
    [self.playButton setImage:[UIImage imageFromSenderFrameworkNamed:@"play"]
                     forState:UIControlStateNormal];
    durationOfRecordedFileLabel.text = [NSString stringWithFormat:@"%.02f",durationOfRecordedFile];
}

- (IBAction)stopRecording
{
    [[AudioRecorder sharedInstance] stopRecord];
    [self stopRepeatTimer];
}

- (void)changeRecBgImage:(BOOL)mode
{
    if (mode) {
        recBgImageView.image = recImage;
    }
    else {
        recBgImageView.image = stopImage;
    }
}

- (void)showHideRecButtons:(BOOL)mode
{
    self.pLabel.hidden = mode;
    self.startStopButton.hidden = mode;
    recBgImageView.hidden = mode;
    
    durationOfRecordedFileLabel.hidden = !mode;
    self.sendButton.hidden = !mode;
    self.playButton.hidden = !mode;
    self.cancelButton.hidden = !mode;
    playBgImageView.hidden = !mode;
    self.playButton.hidden = !mode;
}

@end
