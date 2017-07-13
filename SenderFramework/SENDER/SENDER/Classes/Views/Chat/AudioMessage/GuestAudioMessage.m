//
//  GuestAudioMessage.m
//  SENDER
//
//  Created by Eugene on 11/4/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "GuestAudioMessage.h"
#import "PBConsoleContans.h"
#import "ParamsFacade.h"
#import "File.h"
#import "AudioButton.h"
#import <AVFoundation/AVFoundation.h>
#import "Notifications.h"
#import "Contact.h"
#import "UIImageView+WebCache.h"
#import "CoreDataFacade.h"

@implementation GuestAudioMessage
{
    float xStart;
    UILabel * userNameLabel;
    UIImageView * isOnlineImage;
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
    Contact * conactModel = [[CoreDataFacade sharedInstance] selectContactById:self.viewModel.fromId];
    
    userPicture = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40.0)];
    
    if (conactModel.imgUrl.length)
    {
        [userPicture sd_setImageWithURL:[NSURL URLWithString: conactModel.imgUrl] placeholderImage:[UIImage imageNamed:[conactModel getDefaultImageName]]];
    }
    else
    {
        userPicture.image = [UIImage imageNamed:[conactModel getDefaultImageName]];
    }
    [PBConsoleContans imageSetRounds:userPicture];

    [self addSubview:userPicture];
    
    if (![conactModel.userID isEqualToString:@"0"]) {
        
        isOnlineImage = [[UIImageView alloc] initWithFrame:CGRectMake(35, 35, 8, 8.0)];
        isOnlineImage.hidden = NO;
        isOnlineImage.image = conactModel.isOnline.boolValue ? [UIImage imageNamed:@"on_line"] : [UIImage imageNamed:@"off_line"];
        [self addSubview:isOnlineImage];
    }
    
    self.frame = CGRectMake(0, 0, 320, 50);
    
    booble = [PBConsoleContans guestBoobleImage];
    
    [self addSubview:booble];
    
    audioButton = [[AudioButton alloc] initWithFrame:CGRectMake(65, 10, 90, 30) forModel:self.viewModel];
    
    [self addSubview:audioButton];
    CGRect rect = audioButton.frame;
    rect.origin.x = 50;
    rect.origin.y = 0;
    rect.size.width = 120;
    rect.size.height = 50;
    booble.frame = rect;
    rect = userPicture.frame;
    rect.origin.y = booble.frame.size.height - rect.size.height;
    rect.origin.x = 8.0;
    userPicture.frame = rect;
    rect = self.frame;
    
    rect.size.height = booble.frame.size.height + 10.0;
    self.frame = rect;
    
    rect = CGRectMake(booble.frame.origin.x + 10.0, rect.origin.y - 20, rect.size.width - 40, 20.0);
    userNameLabel = [[UILabel alloc] initWithFrame:rect];
    userNameLabel.text = conactModel.name;
    [userNameLabel setFont:[PBConsoleContans timeMarkerFont]];
    [userNameLabel setTextColor:[PBConsoleContans colorMainBlue]];
    
    [self addSubview:userNameLabel];

    rect = self.frame;
    rect = CGRectMake(booble.frame.origin.x + booble.frame.size.width + 4.0, rect.size.height/2 - 20.0, 35.0, 20.0);
    
    UILabel * timeLabel = [[UILabel alloc] initWithFrame:rect];
    timeLabel.text = [[ParamsFacade sharedInstance] formatedStringFromNSDate:self.viewModel.created];
    [timeLabel setFont:[PBConsoleContans timeMarkerFont]];
    [timeLabel setTextColor:[PBConsoleContans colorGrey]];
    
    [self addSubview:timeLabel];
    [self enableSwitch];
}

- (void)enableSwitch
{
    if ([self.viewModel.file.isDownloaded boolValue]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [audioButton getDuration];
        self.userInteractionEnabled = YES;
        self.alpha = 1;
    }
    else {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(enableSwitch)
                                                     name:SNotificationFileDidDownload
                                                   object:nil];
        self.userInteractionEnabled = NO;
        self.alpha = 0.5;
    }
}

- (void)checkDeliv
{
  
}

- (void)changeBgBooble
{
    [PBConsoleContans guestBoobleSUBCELLImage:booble];
}

- (void)showHideDelivered:(BOOL)mode
{
   
}

- (void)hideImg
{
    [userPicture removeFromSuperview];
     [isOnlineImage removeFromSuperview];
}

- (void)hideName
{
    [userNameLabel removeFromSuperview];
 
}
@end
