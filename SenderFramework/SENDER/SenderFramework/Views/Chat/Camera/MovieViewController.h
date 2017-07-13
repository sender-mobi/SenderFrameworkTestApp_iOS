//
//  MovieViewController.h
//  SENDER
//
//  Created by Eugene on 12/8/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface MovieViewController : UIView

@property (nonatomic, strong) NSURL * urlVideo;

@property (strong, nonatomic) MPMoviePlayerController *videoController;

- (id)initWithURL:(NSURL *)urlV;

@end
