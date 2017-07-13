//
//  MovieViewController.m
//  SENDER
//
//  Created by Eugene on 12/8/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "MovieViewController.h"
#import "PBConsoleConstants.h"
#import "UIView+subviews.h"

@interface MovieViewController ()

@end

@implementation MovieViewController

- (id)initWithURL:(NSURL *)urlV
{
    self = [super init];
    if (self)
    {
        self.urlVideo = urlV;

        self.videoController = [[MPMoviePlayerController alloc] init];

        self.videoController.shouldAutoplay = YES;
        [self.videoController setContentURL:self.urlVideo];

        self.videoController.scalingMode = MPMovieScalingModeAspectFit;
        self.videoController.fullscreen = YES;

        [self.videoController setControlStyle:MPMovieControlStyleFullscreen];

        [self addSubview:self.videoController.view];
        [self.videoController play];
        
        self.videoController.view.translatesAutoresizingMaskIntoConstraints = NO;
        [self pinSubview:self.videoController.view];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(myMovieFinishedCallback)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:self.videoController];


        UIButton * closeButton1 = [[UIButton alloc] initWithFrame:CGRectMake(0, 21, 60, 20)];
        [self addSubview:closeButton1];
        [closeButton1 addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];

        [self showVideo];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setVideoController:(MPMoviePlayerController *)videoController
{
    if (_videoController)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPMoviePlayerPlaybackStateDidChangeNotification
                                                      object:_videoController];
    }
    _videoController = videoController;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerPlaybackStateDidChangeNotification:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_videoController];
}

- (void)showVideo
{
    [self.videoController play];
}

- (void)moviePlayerPlaybackStateDidChangeNotification:(NSNotification *)notification
{
    switch (self.videoController.playbackState) {
        case MPMoviePlaybackStateStopped:
            [self backButtonAction];
            break;
        case MPMoviePlaybackStatePlaying:
            break;
        case MPMoviePlaybackStatePaused:
            break;
        default:
            break;
    }
}

- (void)myMovieFinishedCallback
{
    self.videoController.initialPlaybackTime = 0;
}

- (void)backButtonAction
{
    [self.videoController stop];
    [self.videoController.view removeFromSuperview];
    [[NSNotificationCenter defaultCenter] postNotificationName:PBRemoveViewFromScene object:self];
}

@end
