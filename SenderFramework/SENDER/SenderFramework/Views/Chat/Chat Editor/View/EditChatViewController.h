//
//  EditChatViewController.h
//  SENDER
//
//  Created by Roman Serga on 29/7/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Dialog.h"

@protocol ChatEditorViewProtocol;
@protocol ChatEditorPresenterProtocol;
@protocol ModalInNavigationWireframeEventsHandler;

@interface EditChatViewController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate,
        UIActionSheetDelegate, UITextFieldDelegate, ChatEditorViewProtocol, ModalInNavigationWireframeEventsHandler>

@property (nonatomic, strong) Dialog * dialog;

@property (nonatomic, strong, nullable) id<ChatEditorPresenterProtocol> presenter;

@end
