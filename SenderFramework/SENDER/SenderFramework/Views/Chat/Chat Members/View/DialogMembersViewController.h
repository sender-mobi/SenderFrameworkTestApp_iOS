//
//  DialogMembersViewController.h
//  SENDER
//
//  Created by Roman Serga on 21/4/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RightPanelCell.h"

@protocol ChatMembersViewProtocol;
@protocol ChatMembersPresenterProtocol;

@interface DialogMembersViewController : UITableViewController <RightPanelCellDelegate, ChatMembersViewProtocol>

@property (nonatomic, strong) Dialog * chat;
@property (nonatomic, strong, nullable) id<ChatMembersPresenterProtocol> presenter;

@end