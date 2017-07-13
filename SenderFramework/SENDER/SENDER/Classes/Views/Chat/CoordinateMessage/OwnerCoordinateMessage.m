//
//  OwnerCoordinateMessage.m
//  SENDER
//
//  Created by Eugene on 11/25/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "OwnerCoordinateMessage.h"
#import "PBConsoleContans.h"
#import "ParamsFacade.h"
#import "File.h"
#import "Notifications.h"
#import "UIImageView+WebCache.h"
#import "UIImage+Resize.h"

@implementation OwnerCoordinateMessage
{
    float xStart;
    UIImageView * imageFromMessage;
    UIActivityIndicatorView * progressView;
    UILabel * loadingLabel;
    UILabel * timeLabel;
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
    self.frame = CGRectMake(0, 0, 320, 210);
    
    booble = [PBConsoleContans ownerBoobleImage];
    
    [self addSubview:booble];
    
    CGRect rect = CGRectMake(112, 0, 199, 196);
    booble.frame = rect;
    
    rect.origin.x += 1;
    rect.origin.y += 1;
    
    imageFromMessage = [[UIImageView alloc] initWithFrame:rect];
    imageFromMessage.contentMode = UIViewContentModeScaleAspectFill;
    [imageFromMessage sd_setImageWithURL:self.viewModel.file.getFileUrl placeholderImage:[UIImage imageNamed:@""]];
    
    imageFromMessage.image = [PBConsoleContans maskImageWithCustomImage:imageFromMessage.image maskImage:[UIImage imageNamed:@"owener_mask.png"]];
    imageFromMessage.clipsToBounds = YES;
    //    imageFromMessage.layer.borderWidth = 1;
    //    imageFromMessage.layer.borderColor = [UIColor grayColor].CGColor;
    
    UIButton * actionBtt = [[UIButton alloc] initWithFrame:rect];
    [actionBtt addTarget:self action:@selector(imageAction) forControlEvents:UIControlEventTouchUpInside];
    
    progressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    progressView.frame = CGRectMake(50,50,100,100);
    [progressView startAnimating];
    
    loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(50,130,100,20)];
    loadingLabel.text = NSLocalizedString(@"loading_image_ios", nil);;
    loadingLabel.textColor = [UIColor whiteColor];
    [loadingLabel setFont:[PBConsoleContans timeMarkerFont]];
    [self addSubview:imageFromMessage];
    [self addSubview:actionBtt];
    [imageFromMessage addSubview:progressView];
    [imageFromMessage addSubview:loadingLabel];
    
    
    rect = self.frame;
    rect.size.height = booble.frame.size.height + 10.0;
    
    rect = CGRectMake(booble.frame.origin.x - 35.0, booble.frame.size.height/2 - 10.0, 35.0, 20.0);
    
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
        
        imageFromMessage.image = [PBConsoleContans maskImageWithCustomImage:imageFromMessage.image maskImage:[UIImage imageNamed:@"owener_mask.png"]];
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

- (void)buildDeliverd
{
    CGRect rect = self.frame;
    
    rect = CGRectMake(220.0 , rect.size.height - 10, 70.0, 20.0);
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
        
        rect.size.height += 17;
    }
    else {
        rect.size.height -= 17;
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

- (void)imageAction
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SendMyLocaton
                                                        object:self.viewModel];
}

@end
