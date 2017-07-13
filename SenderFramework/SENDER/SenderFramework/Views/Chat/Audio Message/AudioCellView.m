//
//  AudioCellView.m
//  SENDER
//
//  Created by Eugene on 1/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "AudioCellView.h"
#import "PBConsoleConstants.h"
#import "ParamsFacade.h"
#import "File.h"
#import "AudioButton.h"
#import <AVFoundation/AVFoundation.h>
#import "SenderNotifications.h"
#import "Contact.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "CoreDataFacade.h"

@implementation AudioCellView
{
    AudioButton * audioButton;
    UIActivityIndicatorView * progressView;
    UIView * labelBackground;

    BOOL isObservingMessage;
    BOOL isObservingFile;
}

- (void)initWithModel:(Message *)submodel width:(CGFloat)maxWidth timeLabelSize:(CGSize)timeLabelSize
{
    if (isObservingMessage)
        [self stopObservingKeyPathsOfMessage:self.viewModel];
    if (isObservingFile)
        [self stopObservingKeyPathsOfFile:self.viewModel.file];

    self.viewModel = submodel;
    
    if (self) {
        
        self.frame = CGRectMake(0.0f, 0.0f, 175.0f, 32.0f);
        
        audioButton = [[AudioButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 175.0f, 32.0f) forModel:self.viewModel];
        
        [self addSubview:audioButton];
        [self addTimeBackgroud];
        [self fixWidthForTimeLabelSize:timeLabelSize maxWidth:maxWidth];
        [self enableSwitch];
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (isObservingMessage && self.viewModel)
        [self stopObservingKeyPathsOfMessage:self.viewModel];
    if (isObservingFile && self.viewModel.file)
        [self stopObservingKeyPathsOfFile:self.viewModel.file];
}

- (void)addTimeBackgroud
{
    labelBackground = [[UIView alloc]init];
    labelBackground.backgroundColor = self.viewModel.owner ? [[SenderCore sharedCore].stylePalette myMessageBackgroundColor] : [[SenderCore sharedCore].stylePalette foreignMessageBackgroundColor];
    labelBackground.clipsToBounds = YES;
    [self addSubview:labelBackground];
}

- (void)fixWidthForTimeLabelSize:(CGSize)timeSize maxWidth:(CGFloat)maxWidth
{
    CGFloat newWidth = timeSize.width + 5.0f;
    CGFloat newHeight = timeSize.height + 10.0f;
    
    labelBackground.frame = CGRectMake(self.frame.size.width - newWidth, self.frame.size.height - newHeight, newWidth, newHeight);
    labelBackground.layer.cornerRadius = labelBackground.frame.size.height / 2;
}

- (void)enableSwitch
{
    if ([self.viewModel.file.isDownloaded boolValue]) {
        [self enablePlayAudio];
    }
    else {
        self.userInteractionEnabled = NO;
        self.alpha = 0.5;
        if (!isObservingMessage)
        {
            [self startObservingKeyPathsOfMessage:self.viewModel];
            [self startObservingKeyPathsOfFile:self.viewModel.file];
        }
        [self addSpiner];
    }
}

-(void)startObservingKeyPathsOfMessage:(Message *)message
{
    [message addObserver:self
              forKeyPath:@"file"
                 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                 context:nil];
    isObservingMessage = YES;
}

-(void)stopObservingKeyPathsOfMessage:(Message *)message
{
    if (message) {
        @try{
            [message removeObserver:self forKeyPath:@"file" context:nil];
            isObservingMessage = NO;
        }@catch(id anException){
            //do nothing, Padre!!!
        }
    }
}

-(void)startObservingKeyPathsOfFile:(File *)file
{
    [file addObserver:self
           forKeyPath:@"isDownloaded"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
              context:nil];
    isObservingFile = YES;
}

-(void)stopObservingKeyPathsOfFile:(File *)file
{
    if (file) {
        
        @try{
            [file removeObserver:self forKeyPath:@"isDownloaded" context:nil];
            isObservingFile = NO;
        }@catch(id anException){
            //do nothing, Padre!!!
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"file"])
    {
        if (isObservingFile)
        {
            File * oldFile = change[NSKeyValueChangeOldKey];
            [self stopObservingKeyPathsOfFile:oldFile];
            File * newFile = change[NSKeyValueChangeNewKey];
            [self startObservingKeyPathsOfFile:newFile];
        }
    }
    else
    {
        if ((File*)object == self.viewModel.file)
        {
            [self enablePlayAudio];
            [object removeObserver:self forKeyPath:@"isDownloaded"];
            [self removeSpiner];
        }
    }
}

- (void)enablePlayAudio
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.userInteractionEnabled = YES;
    self.alpha = 1;
    [self updateDuration];
}

- (void)updateDuration
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [audioButton updateDurationLabel];
    });
}

- (void)addSpiner
{
    progressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    progressView.color = [[SenderCore sharedCore].stylePalette mainAccentColor];
    [self addSubview:progressView];
    progressView.center = self.center;
    /*
     * Calling asynchronously in order to fix CATransaction completionHandler bug.
     * http://stackoverflow.com/questions/27470130/catransaction-completion-block-never-fires
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        [progressView startAnimating];
    });
}

- (void)removeSpiner
{
    [progressView stopAnimating];
    [progressView removeFromSuperview];
}
@end
