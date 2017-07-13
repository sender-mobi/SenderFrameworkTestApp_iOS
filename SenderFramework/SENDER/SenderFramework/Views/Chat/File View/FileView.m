//
//  FileView.m
//  SENDER
//
//  Created by Eugene Gilko on 12.05.15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "CommonTextMessageView.h"
#import "FileView.h"
#import "PBConsoleConstants.h"
#import "ParamsFacade.h"
#import "Contact.h"
#import "File.h"
#import "SenderNotifications.h"
#import "CoreDataFacade.h"
#import "ServerFacade.h"
#import "FileManager.h"
#import "SenderNotifications.h"
#import <SenderFramework/SenderFramework-Swift.h>

#define contentSideOffset 4.0f
#define contentTopOffset 4.0f
#define imageSideOffset 10.0f
#define imageTopOffset 10.0f

#define contentWidth 200.0f
#define contentHeight 200.0f

@implementation FileView
{
    UIButton * fileOpenButton;
    UIActivityIndicatorView * progressView;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initWithModel:(Message *)submodel width:(CGFloat)maxWidth timeLabelSize:(CGSize)timeLabelSize
{
    [super initWithModel:submodel width:maxWidth timeLabelSize:timeLabelSize];
    
    if (self)
    {
        fileOpenButton = [[UIButton alloc]init];
        [fileOpenButton addTarget:self action:@selector(imageAction) forControlEvents:UIControlEventTouchUpInside];
        fileOpenButton.backgroundColor = [UIColor clearColor];
        [self addSubview:fileOpenButton];
        [self setLeftIcon:[[UIImage imageFromSenderFrameworkNamed:@"_doc_s"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        leftIcon.tintColor = [SenderCore sharedCore].stylePalette.lineColor;
        [self setText:self.viewModel.file.name];
    }
}


- (void)imageAction
{
    //Files of some type can be opened only in safari
    NSArray * specialFilesExtensions = @[@"mobileconfig"];
    if ([specialFilesExtensions containsObject:self.viewModel.file.url.pathExtension])
    {
        NSURL * remoteURL = [NSURL URLWithString:self.viewModel.file.url];
        if (remoteURL)
            [[UIApplication sharedApplication] openURL:remoteURL];
    }
    else
    {
        if (!self.viewModel.file.localUrl || ![self.viewModel.file.isDownloaded boolValue])
        {
            [self addProgressIndicator];
            fileOpenButton.enabled = NO;
            [[ServerFacade sharedInstance] downloadFileWithBlock:^(NSData *data) {
                [self removeProgressIndicator];
                fileOpenButton.enabled = YES;
                if ([[FileManager sharedFileManager]saveData:data toMessage:self.viewModel.moId])
                {
                    NSString * documentsDirectory = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
                    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:self.viewModel.file.getFilePathName];
                    NSError *error;
                    BOOL success = [data writeToFile:fullPath options:NSDataWritingAtomic error:&error];
                    if (success)
                    {
                        self.viewModel.file.isDownloaded = @YES;
                        self.viewModel.file.localUrl = [[[NSURL alloc]initFileURLWithPath:fullPath]absoluteString];
//                        [[CoreDataFacade sharedInstance] saveContext];
                        [self openFile];
                    }
                }
            } forUrl:self.viewModel.file.url];
        }
        else
        {
            [self openFile];
        }
    }
}

-(void)fixWidthForTimeLabelSize:(CGSize)timeSize maxWidth:(CGFloat)maxWidth
{
    [super fixWidthForTimeLabelSize:timeSize maxWidth:maxWidth];
    fileOpenButton.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
}

-(void)openFile
{
    [self.fileViewDelegate fileView:self didSelectMessage:self.viewModel];
}

- (void)addProgressIndicator
{
    progressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    progressView.color = [[SenderCore sharedCore].stylePalette mainAccentColor];
    progressView.center = self.center;

    /*
     * Calling asynchronously in order to fix CATransaction completionHandler bug.
     * http://stackoverflow.com/questions/27470130/catransaction-completion-block-never-fires
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        [progressView startAnimating];
    });

    [self addSubview:progressView];
}

- (void)removeProgressIndicator
{
    [progressView removeFromSuperview];
    progressView = nil;
}

@end
