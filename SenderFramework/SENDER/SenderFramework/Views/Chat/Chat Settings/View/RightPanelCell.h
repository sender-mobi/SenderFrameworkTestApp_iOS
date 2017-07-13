//
//  RightPanelCell.h
//  Sender
//
//  Created by Eugene Gilko on 9/16/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Contact.h"
#import "Owner.h"

@class RightPanelCell;
@class ChatMember;

@protocol RightPanelCellDelegate <NSObject>

-(void)deleteRightPanelCell:(RightPanelCell *)cell;

@end

@interface RightPanelCell : UITableViewCell

@property (nonatomic, weak) id<RightPanelCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIImageView * userImage;
@property (nonatomic, weak) IBOutlet UILabel * userNameLabel;

@property (nonatomic, weak) ChatMember * chatMember;
@property (nonatomic) BOOL isDeletingEnabled;
@property (nonatomic) BOOL isDeleting;

-(void)stopDeleting;

@end
