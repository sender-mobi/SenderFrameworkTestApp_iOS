//
// Created by Roman Serga on 7/6/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import "CompanyPageViewController.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "ServerFacade.h"
#import "PBConsoleConstants.h"
#import "UIAlertView+CompletionHandler.h"
#import "UIActionSheet+Blocks.h"
#import "ParamsFacade.h"
#import "DialogSetting.h"
#import "Owner.h"
#import "SenderNotifications.h"

@interface CompanyPageViewController ()
{
    UIView * reportUserView;
}

@end

@implementation CompanyPageViewController
{

}

- (void)viewDidLoad
{
    [self.presenter viewWasLoaded];
    self.hasCompletedInitialLoad = YES;
    [SENDER_SHARED_CORE.interfaceUpdater addUpdatesHandler:self];
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)createScrollToBottomButton {}

- (void)updateTitleImage
{
    [self.titleImageView setImage:nil];
    self.titleImageWidth.constant = 0.0f;
    [self.view layoutIfNeeded];
}

- (void)handleAction:(NSNotification *)notification
{
    [self.presenter handleAction:[notification userInfo]];
}

- (void)addSendBarToView
{
    [super addSendBarToView];
}

- (void)sendReadForMessage:(Message *)message {}

- (void)coordinator:(SBCoordinator *)coordinator didSelectItemWithActions:(NSArray *)actionsArray
{
    [self.presenter goToChatWithActions:actionsArray];
}

-(void)handleMessagesChange:(NSArray<Message *> *)messages
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (Message * message in messages)
        {
            if ([message isEqual:self.companyChat.companyCard])
                [self drawCompanyCard];
        }
    });
}

- (void)initialMessagesLoadWithCompletionHandler:(void (^ _Nullable)())completionHandler
{
    [CATransaction setCompletionBlock:^{
        [self drawCompanyCard];
    }];
    [self getUpdatedCompanyCard];
}

- (void)drawCompanyCard
{
    NSComparator comparator = ^NSComparisonResult(Message * msg1, Message * msg2){return [msg1.created compare:msg2.created];};
    NSArray * messagesToLoad = self.companyChat.companyCard ? @[self.companyChat.companyCard] : @[];
    MessageStorage * storage = [[MessageStorage alloc] initWithOrderComparator:comparator
                                                                      messages:messagesToLoad];
    self.messages = storage;
    for (Message * message in self.messages.visibleMessages) [self buildMessage:message];
    [self.tableView reloadData];
}

- (void)createSendBar
{
    if (self.companyChat.hasSendBar)
        self.sendBar = [[SBCoordinator alloc]initWithBarModel:self.companyChat.sendBar];
    else
        self.sendBar = [[SBCoordinator alloc]initWithBarModel:[[CoreDataFacade sharedInstance]senderBar]];
    self.sendBar.dumbMode = YES;
}

- (UIBarButtonItem *)createRightBarButton
{
    NSArray * buttons = @[];

    if([[self.companyChat getPhoneFormatted:NO]length])
    {
        UIButton *callButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [callButton setImage:[UIImage imageFromSenderFrameworkNamed:@"_call"] forState:UIControlStateNormal];
        callButton.frame = CGRectMake(0.0f, 0.0f, 44.0f, 44.0f);
        [callButton addTarget:self action:@selector(callContact) forControlEvents:UIControlEventTouchUpInside];

        buttons = [buttons arrayByAddingObject:callButton];
    }

    UIButton * optionsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    optionsButton.frame = CGRectMake(0.0f, 0.0f, 44.0f, 44.0f);
    [optionsButton setImage:[UIImage imageFromSenderFrameworkNamed:@"_more"] forState:UIControlStateNormal];
    [optionsButton addTarget:self action:@selector(showCompanyPageOptions:) forControlEvents:UIControlEventTouchUpInside];
    buttons = [buttons arrayByAddingObject:optionsButton];

    return [self barButtonItemWithButtons:buttons];
}

- (BOOL)shouldAddPullToRefresh
{
    return NO;
}

-(void)setChatNameTitle
{
    [super setChatNameTitle];
    self.titleLabel.text = self.companyChat.name;
}

- (void)callContact
{
    NSString *phone = [[self.companyChat getPhoneFormatted:NO] stringByReplacingOccurrencesOfString:@" "
                                                                                         withString:@""];
    phone = [phone hasPrefix:@"+"] ? phone : [@"+" stringByAppendingString:phone];
    NSString *phoneUrl = [@"tel://" stringByAppendingString:phone];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneUrl]];
}

- (void)getUpdatedCompanyCard
{
    [[ServerFacade sharedInstance]loadCompanyCardForP2PChat:self.companyChat completionHandler:nil];
}

#pragma mark - Company Page Options

-(void)showCompanyPageOptions:(id)sender
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:nil
                                                                              message:nil
                                                                       preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction * complaintAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"complain_ios", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {
                                                                    [self complain];
                                                                }];

    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];

    BOOL isBlockedCompany = [self.companyChat.chatSettings.blockChat boolValue];
    NSString * blockTitleKey = isBlockedCompany ? @"act_unblock_user_ios" : @"act_block_user_ios";
    UIAlertAction * blockAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(blockTitleKey, nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self blockContact];
                                                         }];

    if (self.companyChat.isSaved)
    {
        NSString * senderChatID = [[CoreDataFacade sharedInstance] getOwner].senderChatId;
        BOOL isSenderChat = [self.companyChat.chatID isEqualToString:senderChatID];
        if (!isSenderChat)
        {
            UIAlertAction * deleteAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"delete_ios", nil)
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                                                                      [self deleteContact];
                                                                  }];
            [alertController addAction:deleteAction];
        }
    }
    else
    {
        UIAlertAction * addToContactsAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"add_to_contacts_ios", nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
                                                                  [self.chatEditManager saveWithP2pChat:self.companyChat completionHandler:nil];
                                                              }];
        [alertController addAction:addToContactsAction];
    }
    [alertController addAction:cancelAction];
    [alertController addAction:complaintAction];
    [alertController addAction:blockAction];

    [alertController mw_safePresentInViewController:self animated:YES completion:nil];
}

- (void)deleteContact
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"delete_contact", nil)
                                                                              message:SenderFrameworkLocalizedString(@"delete_contact_message_ios", nil)
                                                                       preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction * leaveAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"remove", nil)
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action)
                                                         {
                                                             [self.chatEditManager deleteWithChat:self.companyChat
                                                                                completionHandler:nil];
                                                         }];

    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];

    [alertController addAction:leaveAction];
    [alertController addAction:cancelAction];
    [alertController mw_safePresentInViewController:self animated:YES completion:nil];
}

- (void)blockContact
{
    MWChatSettingsEditModel * editModel = [[MWChatSettingsEditModel alloc] initWithChatSettings:self.companyChat.dialogSetting];
    editModel.isBlocked = YES;
    [self.chatEditManager changeSettingsOfChat:self.companyChat
                                   newSettings:editModel
                             completionHandler:nil];
}

- (void)complain
{
    reportUserView = [[UIView alloc]initWithFrame:CGRectMake(0.0f, 0.0f, SCREEN_WIDTH, SCREEN_HEIGHT)];
    reportUserView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];

    ComplainPopUp * popUp = [[ComplainPopUp alloc] init];
    popUp.delegate = self;
    popUp.frame = CGRectMake((SCREEN_WIDTH - popUp.frame.size.width) / 2, 60, popUp.frame.size.width, popUp.frame.size.height);

    [reportUserView addSubview:popUp];

    [SENDER_SHARED_CORE.window addSubview:reportUserView];

    [UIView animateWithDuration:0.2f animations:^{
        reportUserView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    }];
}

- (void)removeReportForm
{
    [reportUserView removeFromSuperview];
    reportUserView = nil;
}

- (void)complainPopUpDidFinishEnteringText:(NSString *)reportText
{
    [self removeReportForm];
    NSString * userID = self.companyChat.p2pContact.userID;
    if ([reportText length] && userID)
        [[ServerFacade sharedInstance] sendComplaintAboutUserWithID:userID withReason:reportText];
}

- (void)updateChatBackground {}

- (void)updateWithViewModel:(Dialog *)viewModel
{
    self.companyChat = viewModel;
}


@end
