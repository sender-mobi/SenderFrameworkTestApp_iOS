//
//  GuestAudioMessage.h
//  SENDER
//
//  Created by Eugene on 11/4/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"
#import "AudioButton.h"

@interface GuestAudioMessage : UIView
{
    UILabel * delivLabel;
    UIImageView * booble;
    AudioButton * audioButton;
    UIImage * contactImage;
    UIImageView * userPicture;
}

- (void)initViewWithModel:(Message *)msgModel;
- (void)showHideDelivered:(BOOL)mode;
- (void)changeBgBooble;
- (void)hideImg;
- (void)checkDeliv;
- (void)hideName;
@property (nonatomic, strong) Message * viewModel;

@end