//
//  AudioButton.h
//  SENDER
//
//  Created by Eugene on 11/7/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "File.h"
#import "Message.h"
#import "AudioRecorder.h"

@interface AudioButton : UIView <AVAudioPlayerDelegate>
{
    IBOutlet UIButton * playButton;
    IBOutlet UILabel * counter;
    IBOutlet UIProgressView * progressView;
    Message * localModel;
    BOOL isPlaying;
    AudioRecorder * recorder;
    Float64 durationOfRecordedFile;
    float progressIncrase;
    NSTimer * playTimer;
}
- (void)stopPlaying;
- (void)updateDurationLabel;
- (id)initWithFrame:(CGRect)frame forModel:(Message *)model;

@end
