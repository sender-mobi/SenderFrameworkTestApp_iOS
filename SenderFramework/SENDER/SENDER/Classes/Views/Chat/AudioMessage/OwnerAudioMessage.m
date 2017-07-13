//
//  OwnerAudioMessage.m
//  SENDER
//
//  Created by Eugene on 11/4/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "OwnerAudioMessage.h"
#import "PBConsoleContans.h"
#import "ParamsFacade.h"
#import "File.h"
#import "AudioButton.h"
#import <AVFoundation/AVFoundation.h>
#import "Notifications.h"

@implementation OwnerAudioMessage
{
    float xStart;
    UILabel * timeLabel;
}

- (void)initViewWithModel:(Message *)submodel
{
    self.viewModel = submodel;
    
    if (self) {
        [self initAudioMessage];
    }
}

- (void)initAudioMessage
{
    self.frame = CGRectMake(0, 0, 320, 50);
    
    booble = [PBConsoleContans ownerBoobleImage];
    
    [self addSubview:booble];
    
    audioButton = [[AudioButton alloc] initWithFrame:CGRectMake(190, 10, 90, 30) forModel:self.viewModel];
    
    [self addSubview:audioButton];
    CGRect rect = audioButton.frame;
    rect.origin.x = 180;
    rect.origin.y = 0;
    rect.size.width = 120;
    rect.size.height = 50;
    booble.frame = rect;
    rect = self.frame;
    rect.size.height = booble.frame.size.height + 10.0;
    
    rect = CGRectMake(booble.frame.origin.x - 35.0, rect.size.height/2 - 10.0, 35.0, 20.0);
    
    timeLabel = [[UILabel alloc] initWithFrame:rect];
    timeLabel.text = [[ParamsFacade sharedInstance] formatedStringFromNSDate:self.viewModel.created];
    [timeLabel setFont:[PBConsoleContans timeMarkerFont]];
    [timeLabel setTextColor:[PBConsoleContans colorGrey]];
    
    [self addSubview:timeLabel];
    [self enableSwitch];
    [self buildDeliverd];
}

- (void)enableSwitch
{
    if ([self.viewModel.file.isDownloaded boolValue]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [audioButton getDuration];
        self.userInteractionEnabled = YES;
        self.alpha = 1;
    }
}

- (void)buildDeliverd
{
    CGRect rect = self.frame;
    
    rect = CGRectMake(220.0 , rect.size.height, 70.0, 20.0);
    delivLabel = [[UILabel alloc] initWithFrame:rect];
    
    delivLabel.textAlignment = NSTextAlignmentRight;
    [delivLabel setFont:[PBConsoleContans timeMarkerFont]];
    [delivLabel setTextColor:[PBConsoleContans colorGrey]];
    
    [self addSubview:delivLabel];
    [self showHideDelivered:YES];
    [self checkDeliv];
}

- (void)checkDeliv
{
    NSString * text = NSLocalizedString(@"status_sending", nil);
    
    if ([self.viewModel.deliver isEqualToString:@"SENT"]) {
        text = NSLocalizedString(@"status_sent", nil);
    }
    else if ([self.viewModel.deliver isEqualToString:@"deliv"]) {
        text = NSLocalizedString(@"status_deliv",nil);
    }
    else if ([self.viewModel.deliver isEqualToString:@"read"]) {
        text = NSLocalizedString(@"status_read",nil);
    }
    timeLabel.text = [[ParamsFacade sharedInstance] formatedStringFromNSDate:self.viewModel.created];
    delivLabel.text = text;
}


- (void)changeBgBooble
{
    [PBConsoleContans ownerBoobleSUBCELLImage:booble];
}

- (void)showHideDelivered:(BOOL)mode
{
    CGRect rect = self.frame;
    if (mode) {
        
        rect.size.height += 25;
    }
    else {
        rect.size.height -= 15;
        [delivLabel removeFromSuperview];
    }
    
    self.frame = rect;
}

- (void)hideImg;
{
    
}
- (void)hideName
{
 
}

@end
