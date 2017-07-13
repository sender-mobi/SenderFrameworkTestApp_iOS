//
//  KeyboardLaunchPad.h
//  Sender
//
//  Created by Eugene Gilko on 9/17/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RecordAudioView.h"
#import "ActionLauncherView.h"
#import "EmojiLauncherView.h"
#import "StickerView.h"

@interface KeyboardLaunchPad : UIView <UINavigationControllerDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) RecordAudioView * audioView;
@property (nonatomic, strong) ActionLauncherView * actionView;
@property (nonatomic, strong) EmojiLauncherView * emojiView;
@property (nonatomic, strong) StickerView * stickerView;
@property (nonatomic, strong) UIScrollView * mainScrollView;
@property (nonatomic, strong) UIPageControl * pageControll;

- (id)initWithViewMode:(NSString *)viewMode;

@end
