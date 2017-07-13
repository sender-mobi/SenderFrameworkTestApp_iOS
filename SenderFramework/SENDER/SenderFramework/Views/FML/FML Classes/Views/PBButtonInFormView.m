//
//  PBButtonInFormView.m
//  SENDER
//
//  Created by Eugene on 10/25/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBButtonInFormView.h"
#import "SenderNotifications.h"
#import "ServerFacade.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIButton+WebCache.h>
#import "ConsoleCaclulator.h"
#import "BitcoinManager.h"
#import <GoogleSignIn/GoogleSignIn.h>
#import "Owner.h"
#import "MainConteinerModel.h"

@implementation PBButtonInFormView
@dynamic viewModel;

-(void)dealloc
{
    NSLog(@"");
}

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainConteinerModel *)submodel
{
    [super settingViewWithRect:mainRect andModel:submodel];
    float startX = 0;
    if (mainRect.origin.x > 0)
        startX = mainRect.origin.x;
    
    //self.frame = CGRectMake(startX, mainRect.origin.y + topIndent, mainRect.size.width, mainRect.size.height);
    
    self.frame = CGRectMake(startX, mainRect.origin.y, mainRect.size.width, 0);

    self.viewModel = submodel;
    [self setupButton];
    self.backgroundColor = [UIColor clearColor];
    if  (_doneButton) {
        [self addSubview:_doneButton];
    }
    
    if ([self.viewModel.state isEqualToString:@"invisible"]) {
        self.hidden = YES;
    }
    if ([self.viewModel.state isEqualToString:@"disable"]) {
        self.userInteractionEnabled = NO;
    }
}

- (void)setupButton
{
    int cHeight = 55;
    int cWidth = self.frame.size.width;
    if (self.viewModel.h > 0) {
        cHeight = (int)[self.viewModel.h integerValue];
    }
    
    if (self.viewModel.w > 0) {
        cWidth = (int)[self.viewModel.w integerValue];
    }
    
    CGRect bttRect = CGRectMake(0, 0, cWidth, cHeight);
    
    _doneButton = [[UIButton alloc] initWithFrame:bttRect];

    if (self.viewModel.bg) {
        
        NSString * firstBg = [self.viewModel.bg substringToIndex:1];
        if ([firstBg isEqualToString:@"#"]) {

            _doneButton.backgroundColor = [PBConsoleConstants colorWithHexString:self.viewModel.bg];
        }
        else {
            [_doneButton sd_setImageWithURL:[NSURL URLWithString:[self.viewModel.bg stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                                   forState:UIControlStateNormal];
        }
    }
    else {
        _doneButton.backgroundColor = [UIColor clearColor];
    }

    if (self.viewModel.title.length) {
        [_doneButton setTitle:self.viewModel.title forState:UIControlStateNormal];
    }
    else {
        [_doneButton setTitle:self.viewModel.val forState:UIControlStateNormal];
    }

    if (self.viewModel.color) {
        [_doneButton setTitleColor:[PBConsoleConstants colorWithHexString:self.viewModel.color] forState:UIControlStateNormal];
    }
    else {
        [_doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }

    UIFont * buttonFont = [PBConsoleConstants inputTextFieldFontStyle:self.viewModel.fontStyle andSize:self.viewModel.fontSize];
    [_doneButton.titleLabel setFont:buttonFont];
    [_doneButton addTarget:self action:@selector(buttonPushedAction) forControlEvents:UIControlEventTouchUpInside];

    self.frame = _doneButton.frame;
    [PBConsoleConstants settingViewBorder:_doneButton andModel:self.viewModel];
}

- (void)actionSendBitCoin:(NSDictionary *)action
{
    MainConteinerModel * addressModel = [self.viewModel findModelWithName:action[@"addr"]];
    MainConteinerModel * amountModel = [self.viewModel findModelWithName:action[@"summ"]];
    
    if (addressModel && amountModel)
    {
        __block NSString * address = addressModel.val;
        __block NSString * amount = amountModel.val;
        BitcoinWallet * ownerWallet = [[[CoreDataFacade sharedInstance]getOwner]getMainWallet:nil];
        
        BitcoinManager * btcManager = [[BitcoinManager alloc]init];
        
        [btcManager transferMoneyFromWallet:ownerWallet toAddress:address withAmount:amount completionHandler:^(NSDictionary *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSString * resuSting = error ? error.localizedDescription : response[@"result"];
                
                if (!resuSting) {
                    resuSting = @"Error";
                }
                
                NSDictionary * transactionResut = @{@"name" : self.viewModel.name,
                                                    @"val" : self.viewModel.val,
                                                    @"addr" : address,
                                                    @"summ" : amount,
                                                    @"result" : resuSting};
                
                [self.delegate pushOnButton:self didFinishEnteringItem:transactionResut];
            });
        }];
    }
}

- (void)buttonPushedAction
{
    [self setActive:NO];

    if (self.viewModel.action) {
        [super doAction:self.viewModel.action];
        
        if ([self.viewModel detectAction:self.viewModel.action] == SetGoogleToken) {
            [self removeBlockTimer];
            return;
        }
        
        if ([self.viewModel detectAction:self.viewModel.action] == RunRobots)
            [self confirmButtonAction];
    }
    else if (self.viewModel.actions) {
        
        BOOL isGoogleAction = NO;
        
        for (NSDictionary * action in self.viewModel.actions) {
            
            if ([self.viewModel detectAction:action] == SetGoogleToken) {
                [super doAction:action];
                isGoogleAction = YES;
            }
        }
        
        if (isGoogleAction) {
            [self removeBlockTimer];
            return;
        }
        
        for (NSDictionary * action in self.viewModel.actions) {
            [super doAction:action];
        }
    }
    else {
        
        [self confirmButtonAction];
    }
    
    [self removeBlockTimer];
}

- (void)removeBlockTimer
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (self)
            [self setActive:YES];
    });
}

- (void)confirmButtonAction
{
    if (self.viewModel.name && self.viewModel.val) {
        NSDictionary * bttData = @{@"name": self.viewModel.name, @"val": self.viewModel.val};
        [self.delegate pushOnButton:self didFinishEnteringItem:bttData];
    }
}

- (void)setActive:(BOOL)active
{
    self.userInteractionEnabled = active;
    self.alpha = active ? 1 : 0.2f;

}

@end
