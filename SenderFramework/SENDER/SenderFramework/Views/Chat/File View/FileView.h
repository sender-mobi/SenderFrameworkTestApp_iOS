//
//  FileView.h
//  SENDER
//
//  Created by Eugene Gilko on 12.05.15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"
#import "CommonTextMessageView.h"

@class FileView;

@protocol FileViewDelegate

- (void)fileView:(FileView *)fileView didSelectMessage:(Message *)message;

@end

@interface FileView : CommonTextMessageView <UIDocumentInteractionControllerDelegate>

@property (nonatomic, weak) id<FileViewDelegate> fileViewDelegate;

@end
