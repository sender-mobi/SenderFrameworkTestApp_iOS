//
//  StickerMessageView.m
//  SENDER
//
//  Created by Eugene on 2/23/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "StickerMessageView.h"
#import "ParamsFacade.h"
#import "PBConsoleConstants.h"
#import "ServerFacade.h"

@implementation StickerMessageView
{
    UIImageView * stickerView;
    UIView * labelBackground;
}

- (void)initWithModel:(Message *)submodel width:(CGFloat)maxWidth timeLabelSize:(CGSize)timeLabelSize
{
    if (self)
    {
        self.viewModel = submodel;
        
        __block UIImage * sticker;
        
        if ([submodel.type isEqualToString:@"VIBRO"])
        {
            sticker = [UIImage imageFromSenderFrameworkNamed:@"_vibro_big"];
        }
        else {
            
            NSDictionary * info = [[ParamsFacade sharedInstance]dictionaryFromNSData:self.viewModel.data];
            sticker = [UIImage imageFromSenderFrameworkNamed:info[@"id"]];
            
            if (!sticker) {
                
                sticker = [[UIImage alloc] init];
                
                NSString * imgURL = [NSString stringWithFormat:@"https://s.sender.mobi/stickers/%@.png",info[@"id"]];
                
                [[ServerFacade sharedInstance] downloadImageWithBlock:[^(UIImage * image) {
                    stickerView.image = image;
                    
                } copy] forUrl:imgURL];
            }
        }
        
        stickerView = [[UIImageView alloc]init];
        stickerView.image = sticker;
        CGFloat delta = ([submodel.type isEqualToString:@"VIBRO"]) ? 40.0f : 15.0f;
        stickerView.frame = CGRectMake(delta, 0.0f, sticker.size.width > 0 ? sticker.size.width:150, sticker.size.height > 0 ? sticker.size.height:75);
        self.frame = CGRectMake(0.0f, 0.0f, stickerView.frame.size.width + delta * 2, stickerView.frame.size.height + delta);
        [self addSubview:stickerView];
        [self addTimeBackground];
        [self fixWidthForTimeLabelSize:timeLabelSize maxWidth:maxWidth];
    }
}

- (void)addTimeBackground
{
    labelBackground = [[UIView alloc]init];
    labelBackground.backgroundColor = self.viewModel.owner ? [SenderCore sharedCore].stylePalette.myMessageBackgroundColor  : [SenderCore sharedCore].stylePalette.foreignMessageBackgroundColor;
    labelBackground.clipsToBounds = YES;
    [self addSubview:labelBackground];
}

- (void)fixWidthForTimeLabelSize:(CGSize)timeSize maxWidth:(CGFloat)maxWidth
{
    CGFloat newWidth = timeSize.width + 7.0f;
    CGFloat newHeight = timeSize.height + 10.0f;
    
    labelBackground.frame = CGRectMake(self.frame.size.width - newWidth, self.frame.size.height - newHeight, newWidth, newHeight);
    labelBackground.layer.cornerRadius = labelBackground.frame.size.height / 2;
}

@end
