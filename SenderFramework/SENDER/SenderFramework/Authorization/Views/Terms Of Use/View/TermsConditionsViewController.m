//
//  TermsConditionsViewController.m
//  SENDER
//
//  Created by Roman Serga on 23/3/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "TermsConditionsViewController.h"
#import "PBConsoleConstants.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface TermsConditionsViewController ()

@property (nonatomic, weak) IBOutlet UITextView * mainTextView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem * doneButton;
@property (nonatomic) BOOL hasSetUpTextView;

@end

@implementation TermsConditionsViewController

@synthesize presenter = _presenter;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = SenderFrameworkLocalizedString(@"user_agreement_title", nil);
    [self.presenter viewWasLoaded];
    
    [self.mainTextView setEditable:NO];
    self.doneButton.tintColor = [[SenderCore sharedCore].stylePalette mainAccentColor];

    self.view.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;
    self.mainTextView.backgroundColor = self.view.backgroundColor;
}

-(void)viewDidLayoutSubviews
{
    if (!self.hasSetUpTextView)
    {
        self.mainTextView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0.0f, 0.0f, 0.0f);
        self.mainTextView.contentOffset = CGPointMake(0.0, -self.topLayoutGuide.length);
        self.hasSetUpTextView = YES;
    }
    [super viewDidLayoutSubviews];
}

- (void)textWasUpdatedWithText:(NSAttributedString *)text
{
    self.mainTextView.attributedText = text;
}

-(IBAction)done:(id)sender
{
    [self.presenter accept];
}

@end
