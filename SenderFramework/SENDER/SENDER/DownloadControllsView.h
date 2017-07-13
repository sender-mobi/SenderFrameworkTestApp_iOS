//
//  DownloadControllsView.h
//  SENDER
//
//  Created by Roman Serga on 7/4/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DownloadControllsViewDelegate <NSObject>

- (void)downloadControllsViewDidPressPause;
- (void)downloadControllsViewDidPressResume;

@end

@interface DownloadControllsView : UIView

@property (nonatomic, weak) id<DownloadControllsViewDelegate> delegate;

@property (nonatomic) CGFloat progress;
@property (nonatomic, strong) UIColor * color;

- (void)startDownloading;

@end
