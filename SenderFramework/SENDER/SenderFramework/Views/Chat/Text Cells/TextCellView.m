//
//  TextCellView.m
//  SENDER
//
//  Created by Eugene on 1/5/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "TextCellView.h"

@implementation TextCellView

-(void)initWithModel:(Message *)submodel width:(CGFloat)maxWidth timeLabelSize:(CGSize)timeLabelSize
{
    [super initWithModel:submodel width:maxWidth timeLabelSize:timeLabelSize];
    
    if (self)
    {
        NSDictionary * data = [[ParamsFacade sharedInstance] dictionaryFromNSData:self.viewModel.data];
        NSString * testText = data[@"text"];
        
        if (testText.length == 0 && !self.viewModel.deletedMessage) {
            self.viewModel.textMessage = SenderFrameworkLocalizedString(@"Message deleted",nil);
            self.viewModel.lasttext = self.viewModel.textMessage;
            self.viewModel.deletedMessage = YES;
            self.userInteractionEnabled = NO;
        }
        
        if (![submodel.encrypted boolValue]) {
            
            messageTextView.dataDetectorTypes = UIDataDetectorTypeAll;

            [self setLeftIconHidden:YES];
            if (!self.viewModel.textMessage) {
                self.viewModel.textMessage = data[@"text"];
                [self setText:self.viewModel.textMessage];
            }
            else {
                [self setText:self.viewModel.textMessage];
            }
        }
    }
}

@end
