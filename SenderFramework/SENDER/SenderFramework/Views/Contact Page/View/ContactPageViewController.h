//
//  ContactPageViewController.h
//  Sender
//
//  Created by Nick Gromov on 9/15/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ComplainPopUp.h"
#import "SBCoordinator.h"

@class Contact;

@protocol ChatsChangesHandler;
@protocol ContactPageViewProtocol;
@protocol ContactPagePresenterProtocol;
@protocol ModalInNavigationWireframeEventsHandler;

@interface ContactPageViewController : UIViewController <UIGestureRecognizerDelegate,
                                                         UITextViewDelegate,
                                                         UIAlertViewDelegate,
                                                         UIImagePickerControllerDelegate,
                                                         UINavigationControllerDelegate,
                                                         UITextFieldDelegate,
                                                         SBCoordinatorDelegate,
                                                         ComplainPopUpDelegate,
                                                         UICollectionViewDelegateFlowLayout,
                                                         UICollectionViewDataSource,
                                                         UIActionSheetDelegate,
                                                         ChatsChangesHandler,
                                                         ContactPageViewProtocol,
                                                         ModalInNavigationWireframeEventsHandler>

@property (nonatomic, strong, nullable) UIImage * leftBarButtonImage;
@property (nonatomic, strong) Dialog * p2pChat;
@property (nonatomic, strong, nullable) id<ContactPagePresenterProtocol> presenter;

@end
