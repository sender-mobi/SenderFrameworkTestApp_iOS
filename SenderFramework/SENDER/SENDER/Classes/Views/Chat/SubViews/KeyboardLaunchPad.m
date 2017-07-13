//
//  KeyboardLaunchPad.m
//  Sender
//
//  Created by Eugene Gilko on 9/17/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "KeyboardLaunchPad.h"
#import "Notifications.h"
#import "PBConsoleContans.h"
#import "EmojiLauncherView.h"

@implementation KeyboardLaunchPad

- (id)initWithViewMode:(NSString *)viewMode
{
    if (((self = [super initWithFrame:CGRectMake(0, 0, 320.0, 216.0)]))) {
        [self viewSetup:viewMode];
    }
    return self;
}

- (void)viewSetup:(NSString *)viewMode
{
    self.tag = 333333;
    _mainScrollView = [[UIScrollView alloc] initWithFrame:self.frame];
    [self addSubview:_mainScrollView];
    _mainScrollView.backgroundColor = [UIColor whiteColor];
    _mainScrollView.showsHorizontalScrollIndicator = NO;
    _mainScrollView.delegate = self;
    
    CGRect finalRect;
    
    if ([viewMode isEqualToString:@"AUDIO"]) {
        _mainScrollView.scrollEnabled = NO;
        _audioView = [[RecordAudioView alloc] init];
        _audioView = [[[NSBundle mainBundle] loadNibNamed:@"RecordAudioView" owner:nil options:nil] objectAtIndex:0];
        
        finalRect =  _audioView.frame;
        [_audioView setupView];
        [_mainScrollView addSubview:_audioView];
    }
    else if ([viewMode isEqualToString:@"ACTION"]) {
        _mainScrollView.scrollEnabled = YES;
        _mainScrollView.pagingEnabled = YES;
        _actionView = [[ActionLauncherView alloc] init];
        _actionView = [[[NSBundle mainBundle] loadNibNamed:@"ActionLauncherView" owner:nil options:nil] objectAtIndex:0];
        
        finalRect = _actionView.frame;
        [_mainScrollView addSubview:_actionView];
        
        _pageControll = [[UIPageControl alloc] initWithFrame:CGRectMake(130, 190, 60, 20)];
        _pageControll.userInteractionEnabled = YES;
        _pageControll.numberOfPages = 2;
        [_pageControll setCurrentPageIndicatorTintColor:[PBConsoleContans colorMainBlue]];
        _pageControll.backgroundColor = [UIColor clearColor];
        _pageControll.pageIndicatorTintColor = [PBConsoleContans colorBorderGrey];
        
        [self addSubview:_pageControll];
    }
    else if ([viewMode isEqualToString:@"EMOJI"]) {
        _mainScrollView.scrollEnabled = YES;
        _mainScrollView.pagingEnabled = YES;
        _emojiView = [[EmojiLauncherView alloc] init];
        _emojiView = [[[NSBundle mainBundle] loadNibNamed:@"EmojiLauncherView" owner:nil options:nil] objectAtIndex:0];
        
        finalRect = _emojiView.frame;
        [_mainScrollView addSubview:_emojiView];
        
        _pageControll = [[UIPageControl alloc] initWithFrame:CGRectMake(130, 190, 60, 20)];
        _pageControll.userInteractionEnabled = YES;
        _pageControll.numberOfPages = 2;
        [_pageControll setCurrentPageIndicatorTintColor:[PBConsoleContans colorMainBlue]];
        _pageControll.backgroundColor = [UIColor clearColor];
        _pageControll.pageIndicatorTintColor = [PBConsoleContans colorBorderGrey];
        
        [self addSubview:_pageControll];
    }
    else if ([viewMode isEqualToString:@"STICKERS"]) {
        _mainScrollView.scrollEnabled = YES;
        _mainScrollView.pagingEnabled = YES;
        _stickerView = [[StickerView alloc] init];
        
        finalRect = _stickerView.frame;
        [_mainScrollView addSubview:_stickerView];
        
        _pageControll = [[UIPageControl alloc] initWithFrame:CGRectMake(130, 190, 60, 20)];
        _pageControll.userInteractionEnabled = YES;
        _pageControll.numberOfPages = _stickerView.frame.size.width / _mainScrollView.frame.size.width;
        [_pageControll setCurrentPageIndicatorTintColor:[PBConsoleContans colorMainBlue]];
        _pageControll.backgroundColor = [UIColor clearColor];
        _pageControll.pageIndicatorTintColor = [PBConsoleContans colorBorderGrey];
        
        [self addSubview:_pageControll];
    }
    
    CGSize scrollViewContentSize = CGSizeMake(finalRect.size.width, finalRect.size.height);
    [_mainScrollView setContentSize:scrollViewContentSize];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    CGFloat pageWidth = _mainScrollView.frame.size.width;
    int page = floor((_mainScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    _pageControll.currentPage = page;
}

@end
