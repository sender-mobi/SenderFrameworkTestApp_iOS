//
//  ChatViewController.h
//  SENDER
//
//  Created by Eugene Gilko on 10/6/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"
#import "Dialog.h"
#import "MainConteinerModel.h"
#import "ShowMapViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "QRDisplayViewController.h"
#import "EditChatViewController.h"
#import "SBCoordinator.h"
#import "ComplainPopUp.h"
#import "CameraManager.h"
#import "ImagePresenter.h"
#import "CellProtoType.h"

@protocol MessagesChangesHandler;
@protocol TypingChangesHandler;
@protocol ChatsChangesHandler;
@protocol ChatViewProtocol;
@protocol ChatPresenterProtocol;
@protocol DragWireframeDelegate;
@protocol ModalInNavigationWireframeEventsHandler;

@class MessageEmpy;
@class PBConsoleView;
@class TypingIndicatorView;
@class GapMessage;
@class ChatHistoryLoader;
@class MWChatEditManager;

@interface UITableView (BlockUpdates)

- (void)performUpdates:(void(^_Nullable)())updates;

@end

@interface NSMutableArray (RemoveFirstOccurrenceOfObjects)

/*
 * Removes first occurrence of object in array.
 */
- (void)removeFirstOccurrenceOfObject:(id)object;

/*
 * For every object in array removes its first occurrence in given array.
 */
- (void)removeFirstOccurrenceOfObjectsInArray:(NSArray *)array;

@end

@interface MessageStorage : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<id<MessageObject>> * allMessages;
@property (nonatomic, copy, readonly) NSComparator orderComparator;
@property (nonatomic) NSUInteger visibleStartIndex;

- (instancetype)initWithOrderComparator:(NSComparator)comparator messages:(NSArray<Message *> *)messages;
- (NSArray <id<MessageObject>>*)visibleMessages;
- (void)addMessages:(NSArray <id<MessageObject>>*)messages;

@end

@interface ChatViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate,
        UIGestureRecognizerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate,
        UIImagePickerControllerDelegate, ShowMapViewControllerDelegate,UIScrollViewDelegate,
        SBCoordinatorDelegate, ComplainPopUpDelegate, CameraManagerDelegate,
        ChatCellDelegate, MessagesChangesHandler, TypingChangesHandler, ChatsChangesHandler,
        ImageModuleDelegate, ChatViewProtocol, DragWireframeDelegate,
        ModalInNavigationWireframeEventsHandler>
{
    UIRefreshControl * refreshControl;
}

@property (nonatomic, strong, nullable) UIImage * leftBarButtonImage;

@property (nonatomic, weak) IBOutlet UITableView * tableView;
@property (nonatomic, weak) IBOutlet UIView * inputPanel;

@property (nonatomic, weak) IBOutlet UILabel * titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView * titleImageView;

@property (strong, nonatomic) UIView * sendBarView;

@property (nonatomic, strong) NSArray * sendBarActions;
@property (nonatomic, strong) Dialog * historyDialog;
@property (nonatomic, strong) NSString * lastReadPosition;

@property (nonatomic, strong) MessageStorage * messages;
@property (nonatomic, strong) NSArray<GapMessage *> * gapMessages;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint * titleImageWidth;
@property (nonatomic, strong) SBCoordinator * sendBar;
@property (nonatomic) BOOL hasCompletedInitialLoad;

@property(nonatomic, strong) MessageEmpy * typingIndicatorModel;

@property (nonatomic) BOOL hidesSendBar;

/*
 * Set customBackgroundImage or customBackgroundImageURL if you want chat background to be
 * other then dialog's image.
 * If customBackgroundImage and customBackgroundImageURL are nil, dialog's image will be used.
 * If customBackgroundImage and customBackgroundImageURL are both set, customBackgroundImage will be used.
 * The custom image will be blurred and brightened the same way as default chat background.
 */

@property (nonatomic, strong) id<ChatPresenterProtocol> presenter;

@property(nonatomic, strong) UIImage * customBackgroundImage;
@property(nonatomic, strong) NSURL * customBackgroundImageURL;

@property (nonatomic, strong) ChatHistoryLoader * historyLoader;

@property (nonatomic, strong) UIButton * scrollToBottomButton;

@property (nonatomic, strong) id<MessageObject> writtenOwnerMessage;

@property (nonatomic, strong) MWChatEditManager *chatEditManager;


- (void)updateTitleImage;
- (void)setUserTypingStatusForContact:(Contact *)user;
- (void)deactivateChat;

- (void)sendReadForMessage:(Message *)message;
- (void)buildForm:(Message *)message;
- (void)addSendBarToView;
- (void)createSendBar;
- (UIBarButtonItem *)createRightBarButton;
- (UIBarButtonItem * )barButtonItemWithButtons:(NSArray *)buttons;
- (BOOL)shouldAddPullToRefresh;
- (void)setChatNameTitle;
- (void)callContact;
- (void)startUpdatingTableWithMessages:(NSArray<Message*>*)messages;
- (void)prepareForDealloc;
- (void)buildMessage:(id<MessageObject>)message;
- (void)updateActiveStateOfChat;
- (void)updateNavigationBar;
- (void)createScrollToBottomButton;

- (void)initialMessagesLoadWithCompletionHandler:(void (^_Nullable)())completionHandler;
- (void)updateChatBackground;

- (void)tableViewScrollToBottomAnimated:(BOOL)animated;
- (void)changeMessageLocalStatusToReadIfNeeded:(Message *)message;

- (MessageEmpy *)createSeparatorModelBeforeMessage:(Message *)message;
- (void)activateChat;

- (MessageEmpy *)createTypingModelForUser:(Contact *)user;
- (void)updateTypingModelTitle:(MessageEmpy *)model withTypingUsers:(NSSet *)typingUsers;

- (PBConsoleView *)formForMessage:(Message *)message;
- (UIView *)notificationViewForMessage:(Message *)message;
- (UIView *)separatorViewForMessage:(id<MessageObject>)message;
- (UIView *)typingViewForMessage:(id<MessageObject>)message;
- (CellProtoType *)regularMessageViewForMessage:(id<MessageObject>)msgModel;

- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardDidShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)handleAction:(NSNotification *)notification;

- (void)fixScrollToBottomButton;

#pragma mark - Utility Functions

BOOL isValidForSendingRead(Message * message);
BOOL isSeparatorNeededBetweenMessages(id<MessageObject> previousMessage, id<MessageObject> nextMessage);
BOOL isDataEqual(NSData * data1, NSData * data2);

- (BOOL)needsUpdateChatBackgroundWithNewImageURL:(NSString *)imageURL;
- (BOOL)needsReloadEncryptedMessagesWithNewGroupChatKey:(NSData *)chatKey keysData:(NSData *)keysData;

- (BOOL)needsReloadSendBarWithChat:(Dialog *)chat;

- (BOOL)isStatusVisibleForMessage:(Message *) message atIndexPath:(NSIndexPath *) indexPath;
- (BOOL)isUserImageVisibleForMessage:(Message *) message atIndexPath:(NSIndexPath *) indexPath;
- (Message *)getTopMessage;
- (NSIndexPath * )indexPathForMessage:(Message *)message;
- (BOOL)isLastCellVisible;
- (void)cacheMainGroupChatKey:(NSData *)chatKey keysData:(NSData *)keysData;

@end
