//
//  VideoCellView.m
//  SENDER
//
//  Created by Eugene on 1/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "VideoCellView.h"
#import "PBConsoleConstants.h"
#import "ParamsFacade.h"
#import "File.h"
#import "SenderNotifications.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+Resize.h"
#import "Contact.h"
#import "CoreDataFacade.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "MovieViewController.h"

@implementation VideoCellView
{
    UIImageView * imageFromMessage;
    UIActivityIndicatorView * progressView;
    UILabel * loadingLabel;
    UIView * durationPad;
    UIButton * actionBtt;
    UIButton * mainButton;
    UIView * labelBackground;

    BOOL isObservingMessage;
    BOOL isObservingFile;

    VideoDownloader * videoDownloader;
}

- (void)dealloc
{
    if (videoDownloader.delegate == self)
        videoDownloader.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (isObservingMessage)
        [self stopObservingKeyPathsOfMessage:self.viewModel];
    if (isObservingFile)
        [self stopObservingKeyPathsOfFile:self.viewModel.file];
}

- (void)initWithModel:(Message *)submodel width:(CGFloat)maxWidth timeLabelSize:(CGSize)timeLabelSize
{
    if (isObservingMessage)
        [self stopObservingKeyPathsOfMessage:self.viewModel];
    if (isObservingFile)
        [self stopObservingKeyPathsOfFile:self.viewModel.file];

    self.viewModel = submodel;
    
    if (self) {
        
        self.frame = CGRectMake(0, 0, 208.0f, 208.0f);
        
        CGRect innerRect = CGRectMake(4.0f, 4.0f, 200.0, 200.0);
        
        imageFromMessage = [[UIImageView alloc] initWithFrame:innerRect];
        imageFromMessage.contentMode = UIViewContentModeScaleAspectFill;
        [imageFromMessage sd_setImageWithURL:self.viewModel.file.getFileUrl placeholderImage:[UIImage imageFromSenderFrameworkNamed:@"ic_send_video@3x"]];
        
        imageFromMessage.layer.cornerRadius = 14.0;
        imageFromMessage.clipsToBounds = YES;
        
        [self addSubview:imageFromMessage];
        
        actionBtt = [[UIButton alloc] initWithFrame:innerRect];
        actionBtt.backgroundColor = [UIColor clearColor];

        UIImage * playImage = [UIImage imageFromSenderFrameworkNamed:@"_play"];

        UIImageView * innerImage = [[UIImageView alloc]initWithFrame:CGRectMake((actionBtt.frame.size.width - playImage.size.width)/2, (actionBtt.frame.size.height - playImage.size.height)/2, playImage.size.width, playImage.size.height)];
        innerImage.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.4f];
        innerImage.layer.cornerRadius = innerImage.frame.size.height / 2.0f;
        innerImage.clipsToBounds = YES;
        innerImage.image = playImage;

        [actionBtt addSubview:innerImage];
        [actionBtt addTarget:self action:@selector(playAction) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:actionBtt];
        [self addTimeBackgroud];
        [self fixWidthForTimeLabelSize:timeLabelSize maxWidth:maxWidth];
        [self addSpinerAndLabel];
        [self enableSwitch];
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
    [message removeObserver:self forKeyPath:@"file" context:nil];
    isObservingMessage = NO;
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
    @try{
        [file removeObserver:self forKeyPath:@"isDownloaded" context:nil];
        isObservingFile = NO;
    }@catch(id anException){
        //do nothing, Padre!!!
    }
}

- (void)addTimeBackgroud
{
    labelBackground = [[UIView alloc]init];
    labelBackground.backgroundColor = self.viewModel.owner ? [SenderCore sharedCore].stylePalette.myMessageBackgroundColor : [SenderCore sharedCore].stylePalette.foreignMessageBackgroundColor;
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

- (void)addSpinerAndLabel
{
    progressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    progressView.color = [[SenderCore sharedCore].stylePalette mainAccentColor];
    progressView.frame = CGRectMake(50,50,100,100);

    /*
     * Calling asynchronously in order to fix CATransaction completionHandler bug.
     * http://stackoverflow.com/questions/27470130/catransaction-completion-block-never-fires
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        [progressView startAnimating];
    });

    loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(60,130,140,20)];
    loadingLabel.text = SenderFrameworkLocalizedString(@"loading_video_ios", nil);
    loadingLabel.textColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    [loadingLabel setFont:[[SenderCore sharedCore].stylePalette timeMarkerFont]];
    [imageFromMessage addSubview:progressView];
    [imageFromMessage addSubview:loadingLabel];
}

- (void)enableSwitch
{
    if ([self.viewModel.file.isDownloaded boolValue]) {
        [self enableVideo];
    }
    else {
        self.userInteractionEnabled = NO;
        self.alpha = 0.5;
        [self startObservingKeyPathsOfFile:self.viewModel.file];
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
        if ((File*)object == self.viewModel.file) {
            [self enableVideo];
            [object removeObserver:self forKeyPath:@"isDownloaded"];
        }
    }
}

- (void)enableVideo
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.userInteractionEnabled = YES;
    self.alpha = 1;
    [progressView stopAnimating];
    [progressView removeFromSuperview];
    [loadingLabel removeFromSuperview];
    progressView = nil;
    loadingLabel = nil;
    
    UIImage * image = [UIImage imageWithContentsOfFile:self.viewModel.file.getFileUrl.absoluteString];
    
    if(image){
        
        imageFromMessage.image = image;
    }
    else
        imageFromMessage.image = [UIImage imageFromSenderFrameworkNamed:@"ic_send_video@3x"];
}

- (void)playAction
{
    if (self.viewModel.file.localUrl) {
        
        MovieViewController * movieView = [[MovieViewController alloc] initWithURL:[NSURL URLWithString:self.viewModel.file.localUrl]];
        [[NSNotificationCenter defaultCenter] postNotificationName:PBAddSelectViewToScene object:movieView];
        
    }
    else {
        
        self.userInteractionEnabled = NO;
        self.alpha = 0.8;
        [self addSpinerAndLabel];
        
        videoDownloader = [[VideoDownloader alloc] initWithModel:self.viewModel];
        videoDownloader.delegate = self;
    }
}

- (void)didFinishDownloadingVideo:(VideoDownloader *)videoDownloader
{
    self.userInteractionEnabled = YES;
    self.alpha = 1;
    [progressView stopAnimating];
    [progressView removeFromSuperview];
    [loadingLabel removeFromSuperview];
    progressView = nil;
    loadingLabel = nil;
    [self performSelector:@selector(playAction) withObject:nil afterDelay:0.5];
}

@end
