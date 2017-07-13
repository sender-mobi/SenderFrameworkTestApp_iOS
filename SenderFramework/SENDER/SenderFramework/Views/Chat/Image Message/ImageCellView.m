//
//  ImageCellView.m
//  SENDER
//
//  Created by Eugene on 1/7/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "ImageCellView.h"
#import "PBConsoleConstants.h"
#import "ParamsFacade.h"
#import "Contact.h"
#import "CoreDataFacade.h"
#import "File.h"
#import "SenderNotifications.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+Resize.h"
#import "CoreDataFacade.h"
#import "UIImage+animatedGIF.h"
#import "FileManager.h"
#import "UIAlertView+CompletionHandler.h"
#import <AssetsLibrary/AssetsLibrary.h>

NSString * const ShowFullScreenPicture = @"ShowFullScreenPicture";

@implementation ImageCellView
{
    UIImageView * imageFromMessage;
    UIActivityIndicatorView * progressView;
    UILabel * loadingLabel;
    UIButton * actionBtt;
    
    UIButton * mainButton;
    UIView * labelBackground;
    
    BOOL isObservingMessage;
    BOOL isObservingFile;

    ImageDownloader * imageDownloader;
}

- (void)dealloc
{
    imageDownloader.delegate = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (isObservingMessage)
        [self stopObservingKeyPathsOfMessage:self.viewModel];
    if (isObservingFile)
        [self stopObservingKeyPathsOfFile:self.viewModel.file];
}

- (void)initWithModel:(Message *)submodel width:(CGFloat)maxWidth timeLabelSize:(CGSize)timeLabelSize;
{
    if (isObservingMessage)
        [self stopObservingKeyPathsOfMessage:self.viewModel];
    if (isObservingFile)
        [self stopObservingKeyPathsOfFile:self.viewModel.file];

    self.viewModel = submodel;
    
    if (self)
    {
        self.frame = CGRectMake(0, 0, 208.0f, 208.0f);
        
        CGRect innerRect = CGRectMake(4.0f, 4.0f, 200.0, 200.0);
       
        imageFromMessage = [[UIImageView alloc] initWithFrame:innerRect];
        imageFromMessage.contentMode = UIViewContentModeScaleAspectFill;
        
        if (self.viewModel.file.getFileUrl)
            [imageFromMessage sd_setImageWithURL:self.viewModel.file.getFileUrl
                                placeholderImage:[UIImage imageFromSenderFrameworkNamed:@"_media"]];

        imageFromMessage.layer.cornerRadius = 14.0;
        imageFromMessage.clipsToBounds = YES;
        
        [self addSubview:imageFromMessage];
        [self addTimeBackgroud];
        [self fixWidthForTimeLabelSize:timeLabelSize maxWidth:maxWidth];
        
        actionBtt = [[UIButton alloc] initWithFrame:innerRect];
        
        [self addSubview:actionBtt];
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
        if ([file isKindOfClass:[File class]])
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

- (void)configureMainButton
{
    if (self.viewModel.file.localUrl)
        [actionBtt setImage:[UIImage imageFromSenderFrameworkNamed:@"_resend"] forState:UIControlStateNormal];
}

- (void)enableSwitch
{
    if ([self.viewModel.file.isDownloaded boolValue])
    {
        [self enableImage];
    }
    else
    {
        self.userInteractionEnabled = NO;
        self.alpha = 0.5;
        if (!isObservingMessage)
        {
            [self startObservingKeyPathsOfMessage:self.viewModel];
            [self startObservingKeyPathsOfFile:self.viewModel.file];
        }
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
        if ((File*)object == self.viewModel.file)
            [self enableImage];
    }
}

- (void)enableImage
{
    if (self.viewModel.file.prev_url) {
        [actionBtt removeTarget:self action:@selector(reloadPrevImage) forControlEvents:UIControlEventTouchUpInside];
    }
    [actionBtt addTarget:self action:@selector(imageAction) forControlEvents:UIControlEventTouchUpInside];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.userInteractionEnabled = YES;
    self.alpha = 1;
    [progressView stopAnimating];
    [progressView removeFromSuperview];
    [loadingLabel removeFromSuperview];
    progressView = nil;
    loadingLabel = nil;
    
    UIImage * image = [UIImage imageWithContentsOfFile:self.viewModel.file.getFileUrl.absoluteString];

    if(image)
        imageFromMessage.image = image;
    else
        imageFromMessage.image = [UIImage imageFromSenderFrameworkNamed:@"media@3x"];
}

- (void)imageAction
{
    NSURL * referenceURL = [NSURL URLWithString:self.viewModel.file.localUrl];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library assetForURL:referenceURL resultBlock:^(ALAsset *asset) {
       
        if ([[asset defaultRepresentation] fullResolutionImage]) {
            NSDictionary * data = [NSDictionary dictionaryWithObjectsAndKeys:imageFromMessage,@"imageView",self.viewModel,@"message", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:ShowFullScreenPicture object:data];

        }
        else {
            self.userInteractionEnabled = NO;
            self.alpha = 0.8;
            [self addSpinerAndLabel];

            imageDownloader = [[ImageDownloader alloc] initWithModel:self.viewModel];
            imageDownloader.delegate = self;
        }
    } failureBlock:^(NSError *error) {
        [self showPhotoLibraryNotAvailableError];
    }];
}

-(void)getImageFromLibrary
{
    // NSLog(@"======\n\nI am getting an image\n\n========");
    NSURL * referenceURL = [NSURL URLWithString:self.viewModel.file.localUrl];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library assetForURL:referenceURL resultBlock:^(ALAsset *asset) {
        if ([[asset defaultRepresentation] fullResolutionImage]) {
            NSDictionary * data = [NSDictionary dictionaryWithObjectsAndKeys:imageFromMessage,@"imageView",self.viewModel,@"message", nil];
            self.userInteractionEnabled = YES;
            self.alpha = 1;
            [progressView stopAnimating];
            [progressView removeFromSuperview];
            [loadingLabel removeFromSuperview];
            progressView = nil;
            loadingLabel = nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:ShowFullScreenPicture object:data];
        }
        else
        {
            // NSLog(@"======\n\nDidn't find an image\n\n========");
            [self performSelector:@selector(getImageFromLibrary) withObject:nil afterDelay:2.0];
        }
    } failureBlock:^(NSError *error) {
        [self showPhotoLibraryNotAvailableError];
    }];

}

- (void)showPhotoLibraryNotAvailableError
{
    NSString * title = SenderFrameworkLocalizedString(@"error_photo_library_not_available", nil);
    NSString * goToSettings = SenderFrameworkLocalizedString(@"error_photo_library_not_available_go_to_settings", nil);

    UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:title
                                                          message:nil
                                                         delegate:nil
                                                cancelButtonTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                otherButtonTitles: goToSettings, nil];
    [myAlertView showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != alertView.cancelButtonIndex)
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];
}

- (void)didFinishDownloadingImage:(ImageDownloader *)imageDownloader
{
    [self getImageFromLibrary];
}

- (void)reloadPrevImage
{
    [[FileManager sharedFileManager] downloadVideoPreviewForMessage:self.viewModel];
}

- (void)addSpinerAndLabel
{
    progressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    progressView.color = [[SenderCore sharedCore].stylePalette mainAccentColor];
    progressView.frame = CGRectMake(52,55,100,100);

    /*
     * Calling asynchronously in order to fix CATransaction completionHandler bug.
     * http://stackoverflow.com/questions/27470130/catransaction-completion-block-never-fires
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        [progressView startAnimating];
    });

    loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,135,180,50)];
    loadingLabel.text = SenderFrameworkLocalizedString(@"loading_image_ios", nil);
    loadingLabel.numberOfLines = 2;
    loadingLabel.textColor = [UIColor blackColor];
    [loadingLabel setTextAlignment:NSTextAlignmentCenter];
    [loadingLabel setFont:[[SenderCore sharedCore].stylePalette timeMarkerFont]];
    [imageFromMessage addSubview:progressView];
    [imageFromMessage addSubview:loadingLabel];
    
    if (!self.viewModel.file.prev_url) {
        [actionBtt addTarget:self action:@selector(reloadPrevImage) forControlEvents:UIControlEventTouchUpInside];
    }
    [imageFromMessage addSubview:progressView];
}

@end
