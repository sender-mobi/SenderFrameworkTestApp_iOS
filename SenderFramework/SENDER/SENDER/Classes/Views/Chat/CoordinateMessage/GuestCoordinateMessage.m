//
//  GuestCoordinateMessage.m
//  SENDER
//
//  Created by Eugene on 11/25/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "GuestCoordinateMessage.h"
#import "PBConsoleContans.h"
#import "ParamsFacade.h"
#import "File.h"
#import "Notifications.h"
#import "UIImageView+WebCache.h"
#import "UIImage+Resize.h"
#import "Contact.h"
#import "CoreDataFacade.h"

@implementation GuestCoordinateMessage
{
    float xStart;
    UIImageView * imageFromMessage;
    UIActivityIndicatorView * progressView;
    UILabel * loadingLabel;
    UILabel * userNameLabel;
    UIImageView * userPicture;
    UIImageView * isOnlineImage;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initViewWithModel:(Message *)submodel
{
    self.viewModel = submodel;
    
    if (self) {
        [self initImageMessage];
    }
}

- (void)initImageMessage
{
    Contact * contactModel = [[CoreDataFacade sharedInstance] selectContactById:self.viewModel.fromId];
    self.frame = CGRectMake(0, 0, 320, 210);
    
    userPicture = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40.0)];
    userPicture.image = [UIImage imageWithData:contactModel.imageData];
    
    [PBConsoleContans imageSetRounds:userPicture];
    [self addSubview:userPicture];
    
    if (![contactModel.userID isEqualToString:@"0"]) {
        
        isOnlineImage = [[UIImageView alloc] initWithFrame:CGRectMake(35, 35, 8, 8.0)];
        isOnlineImage.hidden = NO;
        isOnlineImage.image = contactModel.isOnline.boolValue ? [UIImage imageNamed:@"on_line"] : [UIImage imageNamed:@"off_line"];
        [self addSubview:isOnlineImage];
    }
    
    self.frame = CGRectMake(0, 0, 320, 50);
    
    booble = [PBConsoleContans guestBoobleImage];
    
    [self addSubview:booble];
    
    CGRect rect = CGRectMake(50, 0, 199, 196);
    
    booble.frame = rect;
    rect = userPicture.frame;
    rect.origin.y = booble.frame.size.height - rect.size.height;
    rect.origin.x = 8.0;
    userPicture.frame = rect;
    rect = self.frame;
    
    
    rect.size.height = booble.frame.size.height + 15.0;
    self.frame = rect;
    
    rect = CGRectMake(booble.frame.origin.x + 10.0, rect.origin.y - 20, rect.size.width - 40, 20.0);
    userNameLabel = [[UILabel alloc] initWithFrame:rect];
    userNameLabel.text = contactModel.name;
    [userNameLabel setFont:[PBConsoleContans timeMarkerFont]];
    [userNameLabel setTextColor:[PBConsoleContans colorMainBlue]];
    
    [self addSubview:userNameLabel];
    
    rect = booble.frame;
    
    rect.origin.x += 1;
    rect.origin.y += 1;
    
    imageFromMessage = [[UIImageView alloc] initWithFrame:rect];
    imageFromMessage.contentMode = UIViewContentModeScaleAspectFill;
    [imageFromMessage sd_setImageWithURL:self.viewModel.file.getFileUrl placeholderImage:[UIImage imageNamed:@""]];
    
    imageFromMessage.image = [PBConsoleContans maskImageWithCustomImage:imageFromMessage.image maskImage:[UIImage imageNamed:@"guest_mask.png"]];
    //    imageFromMessage.layer.borderWidth = 1;
    //    imageFromMessage.layer.borderColor = [UIColor grayColor].CGColor;
    imageFromMessage.clipsToBounds = YES;
    
    UIButton * actionBtt = [[UIButton alloc] initWithFrame:rect];
    [actionBtt addTarget:self action:@selector(imageAction) forControlEvents:UIControlEventTouchUpInside];
    
    progressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    progressView.frame = CGRectMake(50,50,100,100);
    [progressView startAnimating];
    
    loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(65,130,100,20)];
    loadingLabel.text = NSLocalizedString(@"loading_image_ios", nil);
    loadingLabel.textColor = [UIColor whiteColor];
    [loadingLabel setFont:[PBConsoleContans timeMarkerFont]];
    [self addSubview:imageFromMessage];
    [self addSubview:actionBtt];
    [imageFromMessage addSubview:progressView];
    [imageFromMessage addSubview:loadingLabel];
    
    
    rect = self.frame;
    rect.size.height = booble.frame.size.height + 10.0;
    
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
            imageFromMessage.image = [UIImage imageNamed:@""];
        imageFromMessage.image = [PBConsoleContans maskImageWithCustomImage:imageFromMessage.image maskImage:[UIImage imageNamed:@"guest_mask.png"]];
        //        imageFromMessage.layer.borderWidth = 1;
        //        imageFromMessage.layer.borderColor = [UIColor grayColor].CGColor;
        imageFromMessage.clipsToBounds = YES;
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
}


- (void)hideName
{
    [userNameLabel removeFromSuperview];
    [isOnlineImage removeFromSuperview];
}

- (void)imageAction
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SendMyLocaton
                                                        object:self.viewModel];
}

@end
