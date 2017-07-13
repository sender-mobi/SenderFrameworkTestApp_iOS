//
//  DialogMembersViewController.m
//  SENDER
//
//  Created by Roman Serga on 21/4/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "DialogMembersViewController.h"
#import "RightPanelCell.h"
#import "ChatPickerManager.h"
#import "ChatViewController.h"
#import "ContactPageViewController.h"
#import "ServerFacade.h"
#import "ChatMember+CoreDataClass.h"
#import "ParamsFacade.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface DialogMembersViewController ()

@property (nonatomic, strong) NSArray<ChatMember *> * members;

@end

@implementation DialogMembersViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.title = SenderFrameworkLocalizedString(@"chat_settings_members", nil);
    [self.presenter viewWasLoaded];
    [[SenderCore sharedCore].stylePalette customizeNavigationItem:self.navigationItem];
    self.view.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;
    self.tableView.backgroundColor = self.view.backgroundColor;
}

- (void)setChat:(Dialog *)chat
{
    _chat = chat;
    NSArray * members = _chat.members.allObjects;
    NSArray * sortDescriptors = [[ParamsFacade sharedInstance]getSortDescriptorsBy:@"contact.name"
                                                                         ascending:YES];
    self.members = [members sortedArrayUsingDescriptors:sortDescriptors];

    if (self.isViewLoaded)
        [self.tableView reloadData];
}

-(ChatMember *)memberForIndexPath:(NSIndexPath *)indexPath
{
    return self.members[indexPath.row];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.members count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RightPanelCell * cell = [self.tableView dequeueReusableCellWithIdentifier:@"RightPanelCell" forIndexPath:indexPath];
    cell.chatMember = [self memberForIndexPath:indexPath];
    cell.delegate = self;
    cell.contentView.backgroundColor = self.view.backgroundColor;

    //User cannot delete himself from chat. He must leave from it
    NSString * ownerID = [[CoreDataFacade sharedInstance] ownerUDID];
    cell.isDeletingEnabled = ![cell.chatMember.contact.userID isEqualToString:ownerID];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 49.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RightPanelCell * cell = (RightPanelCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:NO animated:YES];
    if (cell.isDeleting)
    {
        [cell stopDeleting];
    }
    else
    {
        if ([self isMemberSelectable:cell.chatMember])
            [self.presenter showContactPageWithP2pChat:cell.chatMember.contact.p2pChat];
    }
}

-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    RightPanelCell * cell = (RightPanelCell *)[tableView cellForRowAtIndexPath:indexPath];
    return [self isMemberSelectable:cell.chatMember];
}

- (BOOL)isMemberSelectable:(ChatMember *)member
{
    Contact * contact = member.contact;
    NSString * userID = contact.userID;
    NSString * ownerID = [[CoreDataFacade sharedInstance]getOwner].ownerID;
    return [contact.isCompany boolValue] ||
    (userID && ![userID isEqualToString:@"0"] && ![userID isEqualToString:ownerID]);

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

-(void)showContactPage:(Contact *)contact
{
    if (contact)
        [self.presenter showContactPageWithP2pChat:contact.p2pChat];
}

#pragma mark - RightPanelCell Delegate Methods

-(void)deleteRightPanelCell:(RightPanelCell *)cell
{
    ChatMember * member = cell.chatMember;
    [self.presenter deleteMember:member];
}

- (void)updateWithViewModel:(Dialog *)viewModel
{
    self.chat = viewModel;
}


@end
