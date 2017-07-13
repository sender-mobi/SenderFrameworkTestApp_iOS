//
//  ChatSettingsViewController.h
//  SENDER
//
//  Created by Roman Serga on 22/7/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Contact.h"
#import "ValueSelectTableViewController.h"
#import <StaticDataTableViewController/StaticDataTableViewController.h>

@class ChatSettingsViewController;

@protocol ChatSettingsViewProtocol;
@protocol ChatSettingsPresenterProtocol;

@interface ChatSettingsViewController : StaticDataTableViewController <ValueSelectTableViewControllerDelegate,
        ChatSettingsViewProtocol>

@property (nonatomic, strong, nullable) id<ChatSettingsPresenterProtocol> presenter;
@property (nonatomic, strong) Dialog * dialog;

@end
