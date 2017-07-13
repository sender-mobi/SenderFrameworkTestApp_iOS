//
//  ChatViewController.m
//  SENDER
//
//  Created by Eugene Gilko on 10/6/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "ChatViewController.h"
#import "UIView+subviews.h"
#import "SenderNotifications.h"
#import "CellWithWebView.h"
#import "CoreDataFacade.h"
#import "MainConteinerModel.h"
#import "ServerFacade.h"
#import "PBConsoleManager.h"
#import "PBConsoleConstants.h"
#import "MessageEmpy.h"
#import "Contact.h"
#import "ParamsFacade.h"
#import "NSString+PBMessages.h"
#import "AudioRecorder.h"
#import "ParamsFacade.h"
#import "MyLocationCellView.h"
#import "ImageCellView.h"
#import "VideoCellView.h"
#import "AudioCellView.h"
#import "FileManager.h"
#import "Message.h"
#import "UIImage+Resize.h"
#import "UIView+ResizeAnimated.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "VideoManager.h"
#import "UIImage+animatedGIF.h"
#import "TextCellView.h"
#import "ConsoleCaclulator.h"
#import "ProgressView.h"
#import "ContactPageViewController.h"
#import "TypingIndicatorView.h"
#import "UIAlertView+CompletionHandler.h"
#import "CometController.h"
#import "SBCoordinator.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "ImagesManipulator.h"
#import "ChatViewController+UpdatesHandling.h"
#import "Owner.h"
#import "ValueSelectTableViewController.h"
#import "Dialog.h"
#import "ImagePresenter.h"
#import "MessagesGap.h"
#import <GoogleSignIn/GoogleSignIn.h>
#import <objc/runtime.h>
#import "ChatNotification.h"
#import "GapMessage.h"
#import "ChatHistoryLoader.h"
#import "ChatPickerViewController.h"
#import "ChatViewModel.h"
#import "ChatPickerManager.h"
#import "ChatPickerOneCompanyViewController.h"
#import "ChatMember+CoreDataClass.h"
#import "MWLocationFacade.h"
#import "FileView.h"

#define slideTime 0.3f

#ifndef dispatch_main_sync_safe
     #define dispatch_main_sync_safe(block)\
        if ([NSThread isMainThread]) {\
            block();\
        } else {\
            dispatch_sync(dispatch_get_main_queue(), block);\
        }
#endif

#ifndef dispatch_main_async_safe

#define dispatch_main_async_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }
#endif

static NSString * FormViewCellIdentifier = @"FormViewCell";

@implementation UITableView (BlockUpdates)

- (void)performUpdates:(void(^_Nullable)())updates
{
    [self beginUpdates];
    if (updates)
        updates();
    [self endUpdates];
}

@end

@implementation NSMutableArray (RemoveFirstOccurrenceOfObjects)

- (void)removeFirstOccurrenceOfObject:(id)object
{
    NSUInteger objectIndex = [self indexOfObject:object];
    if (objectIndex != NSNotFound)
        [self removeObjectAtIndex:objectIndex];
}

- (void)removeFirstOccurrenceOfObjectsInArray:(NSArray *)array
{
    for (id object in array)
    {
        NSUInteger objectIndex = [self indexOfObject:object];
        if (objectIndex != NSNotFound)
            [self removeObjectAtIndex:objectIndex];
    }
}

@end

@implementation MessageStorage
{
    NSArray * _visibleMessages;
}

- (instancetype)initWithOrderComparator:(NSComparator)comparator messages:(NSArray<Message *> *)messages
{
    self = [super init];
    if (self)
    {
        _orderComparator = comparator;
        NSPredicate * hasCreated = [NSPredicate predicateWithBlock:^BOOL(Message* msg, NSDictionary* bindings) {
            return msg.created != nil;
        }];
        NSArray * messagesWithCreated = [messages filteredArrayUsingPredicate:hasCreated];
        _allMessages = [[messagesWithCreated sortedArrayUsingComparator:_orderComparator] mutableCopy];
    }
    return self;
}

- (void)setVisibleStartIndex:(NSUInteger)visibleStartIndex
{
    if (visibleStartIndex != _visibleStartIndex)
        _visibleMessages = nil;
    _visibleStartIndex = visibleStartIndex;
}

- (NSArray <id<MessageObject>>*)visibleMessages
{
    if (!_visibleMessages)
        _visibleMessages = [self.allMessages subarrayWithRange:[self visibleRange]];
    return _visibleMessages;
}

- (void)addMessages:(NSArray <id<MessageObject>>*)messages
{
    _visibleMessages = nil;
    for (NSUInteger index = 0; index < [messages count]; index++)
    {
        Message *newMessage = messages[index];
        NSUInteger newIndex = [self.allMessages indexOfObject:newMessage
                                                inSortedRange:(NSRange) {0, [self.allMessages count]}
                                                      options:NSBinarySearchingInsertionIndex
                                              usingComparator:self.orderComparator];
        [self.allMessages insertObject:newMessage atIndex:newIndex];
    }
}

-(NSRange)visibleRange
{
    return NSMakeRange(self.visibleStartIndex, [self.allMessages count] - self.visibleStartIndex);
}

@end

@interface MessageTableViewCell : UITableViewCell
@end

@implementation MessageTableViewCell

- (void)prepareForReuse
{
    [self.contentView removeAllSubviews];
}

@end

@interface ChatViewController () <GIDSignInUIDelegate>
{
    NSMutableOrderedSet * tableViewsArrayChild;
    CameraManager * cameraManager;
    VideoManager * videoManager;
    UIActivityIndicatorView * startProgressView;

    BOOL statusBarHidden;
    BOOL rightPanelVisible;

    BOOL keyboardIsVisible;

    CGFloat originalTitleImageViewWidth;
    
    Message * messageForEdit;
    NSTimer * updateTimer;
    NSArray * pendingNewMessages;

    NSString * oldChatBackgroundURL;

    ImagePresenter * imagePresenter;
    PBSubviewFacade * googleModel;

    NSData * oldKeysData;
    NSData * oldChatKey;

    BarModel * oldSendBar;

    ChatPickerManagerOneCompany * pickerManager;
}

@property (nonatomic, strong) UIImageView * chatBg;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint * titleViewCenter;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * inputFieldHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * bottomSpace;

@property (strong, nonatomic) UITapGestureRecognizer * hideKeyboardRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer * swipeGestureRecognizerDown;

@end

@implementation ChatViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden
{
    return statusBarHidden;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    originalTitleImageViewWidth = self.titleImageView.frame.size.width;
    statusBarHidden = NO;

    imagePresenter = [[ImagePresenter alloc]init];
    imagePresenter.delegate = self;

    self.gapMessages = @[];
    self.tableView.scrollsToTop = YES;
    self.tableView.layer.masksToBounds = YES;
    [self.tableView registerClass:[MessageTableViewCell class] forCellReuseIdentifier:FormViewCellIdentifier];

    if ([self shouldAddPullToRefresh])
        [self addPullToRefresh];

    [self addGestureRecognizers];
    [self addLocalNotifications];

    if ([(NSObject *)self.presenter respondsToSelector:@selector(viewWasLoaded)])
        [self.presenter viewWasLoaded];

    [self updateActiveStateOfChat];
    [self customizeNavigationBarAppearance];
    [self updateNavigationBar];
    [self updateChatBackground];
    [self createScrollToBottomButton];

    self.historyLoader = [[ChatHistoryLoader alloc]init];

    NSComparator orderComparator = ^NSComparisonResult(Message * msg1, Message * msg2) { return [msg1.created compare: msg2.created]; };
    self.messages = [[MessageStorage alloc] initWithOrderComparator:orderComparator messages:@[]];

    [SENDER_SHARED_CORE.interfaceUpdater addUpdatesHandler:self];

    [self initialMessagesLoadWithCompletionHandler:^{
        if (self.historyDialog.needSync == nil || [self.historyDialog.needSync boolValue])
            [[ServerFacade sharedInstance] getChatHistory:self.historyDialog.chatID withRequestHandler:nil];
    }];

    self.view.backgroundColor = [[SenderCore sharedCore].stylePalette controllerCommonBackgroundColor];

    MWChatEditManagerInput * editManagerInput = [[MWChatEditManagerInput alloc] init];
    self.chatEditManager = [[MWChatEditManager alloc] initWithInput:editManagerInput];
    [self.chatEditManager updateWithChat:self.historyDialog completionHandler:nil];

    if (self.hidesSendBar)
        self.inputFieldHeight.constant = 0.0f;
}

- (BOOL)isChatActive:(Dialog *)chat
{
    return !(chat.isGroup && (chat.chatState == ChatStateInactive || chat.chatState == ChatStateRemoved));
}

- (void)createScrollToBottomButton
{
    CGFloat width = 44.0f;
    CGFloat height = 44.0f;

    self.scrollToBottomButton = [[UIButton alloc]init];
    self.scrollToBottomButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollToBottomButton.layer.cornerRadius = height / 2;

    [self.scrollToBottomButton setTintColor:[[SenderCore sharedCore].stylePalette mainAccentColor]];
    UIImage * arrowImage = [[UIImage imageFromSenderFrameworkNamed:@"icDown"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.scrollToBottomButton setImage:arrowImage forState:UIControlStateNormal];

    self.scrollToBottomButton.layer.borderColor = [[SenderCore sharedCore].stylePalette.lineColor CGColor];
    self.scrollToBottomButton.layer.borderWidth = 0.5f;

    [self.scrollToBottomButton setBackgroundColor:[SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor];
    [self.scrollToBottomButton addTarget:self
                               action:@selector(tableViewScrollToNewMessage)
                     forControlEvents:UIControlEventTouchUpInside];

    [self.view insertSubview:self.scrollToBottomButton aboveSubview:self.tableView];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.scrollToBottomButton
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0f
                                                           constant:23.0f]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.inputPanel
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.scrollToBottomButton
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0f
                                                           constant:10.0f]];

    [self.scrollToBottomButton addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollToBottomButton
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0f
                                                                        constant:width]];

    [self.scrollToBottomButton addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollToBottomButton
                                                                       attribute:NSLayoutAttributeHeight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0f
                                                                        constant:height]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSArray * visibleMessages = @[];
    for (NSIndexPath * indexPath in [self.tableView indexPathsForVisibleRows])
        visibleMessages = [visibleMessages arrayByAddingObject:self.messages.visibleMessages[indexPath.row]];
    for (Message * message in self.messages.visibleMessages)
    {
        if (![visibleMessages containsObject:message])
            message.viewForCell = nil;
    }
}

- (void)viewDidLayoutSubviews
{
    if (!self.sendBar)
        [self addSendBarToView];
    /*
     edgesForExtendedLayout and automaticallyAdjustsScrollViewInsets
     doesn't work for custom view controllers. So, we have to do it manually.
    */
    [self setEdgeInsetsForScrollView:self.tableView];
    [self fixScrollToBottomButton];

    /*
     * Move title label a bit to be positioned in center of view rather then in center of titleView
     */
    self.titleViewCenter.constant =  self.view.center.x - self.navigationItem.titleView.center.x;
}

-(void)setEdgeInsetsForScrollView:(UIScrollView *)scrollView
{
    UIEdgeInsets insets = UIEdgeInsetsMake(self.topLayoutGuide.length,
            0.0,
            0.0,
            0.0);
    scrollView.scrollIndicatorInsets = insets;
    scrollView.contentInset = insets;
}

-(void)viewWillAppear:(BOOL)animated
{
    [[self navigationController]setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
    
    //Workaround for quick swipe-to-back to ChatListViewController and back to ChatViewController
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self navigationController]setNavigationBarHidden:NO animated:animated];
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];

    if ([(NSObject *)self.presenter respondsToSelector:@selector(viewDidAppear)])
        [self.presenter viewDidAppear];
    [[self navigationController]setNavigationBarHidden:NO animated:animated];

    if (self.historyDialog.chatType == ChatTypeP2P)
    {
        Contact * p2pContact = self.historyDialog.p2pContact;
        if ([NSDate date].timeIntervalSince1970 - p2pContact.lastOnlineCallTime.doubleValue > 60.0)
        {
            if (p2pContact.userID)
                [[ServerFacade sharedInstance] checkOnlineStatusForUserIDs:@[p2pContact.userID]];
            p2pContact.lastOnlineCallTime = @([NSDate date].timeIntervalSince1970);
        }
    }

    if (self.lastReadPosition)
    {
        Message * tempM = (Message *)[[CoreDataFacade sharedInstance] findFirstObjectWithName:@"Message"
                                                                                   byProperty:@"moId"
                                                                                    withValue:self.lastReadPosition];
        if (tempM) {
            [self.tableView scrollToRowAtIndexPath:tempM.indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        }
        self.lastReadPosition = nil;
    }

    _historyDialog.unreadCount = @0;
    if (_historyDialog)
        [[SenderCore sharedCore].interfaceUpdater chatsWereChanged:@[_historyDialog]];

    self.navigationController.interactivePopGestureRecognizer.enabled = !rightPanelVisible;

    if (!self.hidesSendBar && self.sendBarActions)
    {
        [self.sendBar handleActions:self.sendBarActions];
        self.sendBarActions = nil;
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.historyDialog.unsentText = self.sendBar.text;
    [self removeExtraViews];
    self.sendBarActions = nil;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:YES];
    if ([(NSObject *)self.presenter respondsToSelector:@selector(viewDidDisappear)])
        [self.presenter viewDidDisappear];
//    [[CoreDataFacade sharedInstance]saveContext];
    for (NSTimer * timer in [self.timers allValues])
        [timer invalidate];
    self.typingUsers = nil;
    [self.view endEditing:YES];
    [[NSNotificationCenter defaultCenter]  postNotificationName:@"stopPlayingAudio" object:nil];
}

- (void)dealloc
{
    [self prepareForDealloc];
}

-(void)prepareForDealloc
{
    self.scrollToBottomButton = nil;
    self.tableView.delegate = nil;
    [self removeLocalNotifications];
    self.sendBarView = nil;
    if (self.sendBar) self.sendBar = nil;

    @autoreleasepool {
        for (Message * visibleMessage in self.messages.visibleMessages) visibleMessage.viewForCell = nil;
    }
}

- (void)addGestureRecognizers
{
    self.swipeGestureRecognizerDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(endEditing)];
    self.swipeGestureRecognizerDown.delegate  = self;
    [self.swipeGestureRecognizerDown setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [self.inputPanel addGestureRecognizer:self.swipeGestureRecognizerDown];

    self.hideKeyboardRecognizer  = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(endEditing)];
    self.hideKeyboardRecognizer.numberOfTapsRequired = 1;
    self.hideKeyboardRecognizer.numberOfTouchesRequired = 1;
    [self.tableView addGestureRecognizer:self.hideKeyboardRecognizer];
}

- (BOOL)shouldAddPullToRefresh { return YES; }

#pragma - Navigation bar customization

- (void)customizeNavigationBarAppearance
{
    UINavigationBar * navigationBar = self.navigationController.navigationBar;
    [[SenderCore sharedCore].stylePalette customizeNavigationBar:navigationBar];
    [[SenderCore sharedCore].stylePalette customizeNavigationItem:self.navigationItem];
}

- (void)updateNavigationBar
{
    [self updateTitleImage];
    [self setChatNameTitle];
    [self.view layoutSubviews];

    self.navigationItem.rightBarButtonItem = [self createRightBarButton];
    if (self.leftBarButtonImage)
    {
        UIBarButtonItem * leftBarButton = [[UIBarButtonItem alloc] initWithImage:self.leftBarButtonImage
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(closeChat)];
        self.navigationItem.leftBarButtonItem = leftBarButton;
    }
    else
    {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (void)closeChat
{
    if ([(NSObject *)self.presenter respondsToSelector:@selector(closeChat)])
        [self.presenter closeChat];
    else if ([(NSObject *)self.presenter respondsToSelector:@selector(closeContactPage)])
        [(NSObject *)self.presenter performSelector:@selector(closeContactPage)];
}

-(void)setChatNameTitle
{
    self.titleLabel.text = self.historyDialog.name;
    if (self.navigationController.navigationBar.titleTextAttributes[NSForegroundColorAttributeName])
        self.titleLabel.textColor = self.navigationController.navigationBar.titleTextAttributes[NSForegroundColorAttributeName];
    else
        self.titleLabel.textColor = [[SenderCore sharedCore].stylePalette colorWithHexString:@"#3B3B3B"];
    if (self.navigationController.navigationBar.titleTextAttributes[NSFontAttributeName])
        self.titleLabel.font = self.navigationController.navigationBar.titleTextAttributes[NSFontAttributeName];
    else
        [UIFont systemFontOfSize:18.0f weight:UIFontWeightSemibold];
}

- (void)updateTitleImage
{
    if ([self.historyDialog isEncrypted])
        [self.titleImageView setImage:[UIImage imageFromSenderFrameworkNamed:@"locked"]];
    else if (self.historyDialog.chatType == ChatTypeOperator)
        [self.titleImageView setImage:[UIImage imageFromSenderFrameworkNamed:@"operator"]];
    else
        [self.titleImageView setImage:nil];

    self.titleImageWidth.constant = self.titleImageView.image ? originalTitleImageViewWidth : 0.0f;
    [self.view layoutIfNeeded];
}

- (UIBarButtonItem *)createRightBarButton
{
    NSArray * buttons = @[];

    if (self.historyDialog.isP2P)
    {
        if ([[self.historyDialog getPhoneFormatted:NO]length])
        {
            UIButton * callButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [callButton setImage:[UIImage imageFromSenderFrameworkNamed:@"_call"] forState:UIControlStateNormal];
            callButton.frame = CGRectMake(0.0f, 0.0f, 44.0f, 44.0f);
            [callButton addTarget:self action:@selector(callContact) forControlEvents:UIControlEventTouchUpInside];

            buttons = [buttons arrayByAddingObject:callButton];
        }
    }

    UIButton * menuButtonRaw = [UIButton buttonWithType:UIButtonTypeSystem];
    menuButtonRaw.frame = CGRectMake(0.0f, 0.0f, 44.0f, 44.0f);
    [menuButtonRaw setImage:[UIImage imageFromSenderFrameworkNamed:@"_menu"] forState:UIControlStateNormal];
    [menuButtonRaw addTarget:self action:@selector(toggleRightPanel) forControlEvents:UIControlEventTouchUpInside];

    buttons = [buttons arrayByAddingObject:menuButtonRaw];

    return [self barButtonItemWithButtons:buttons];
}

-(UIBarButtonItem *)barButtonItemWithButtons:(NSArray *)buttons
{
    UIView * buttonsBackground = [[UIView alloc]initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 44.0f)];
    CGFloat menuButtonX = 0.0f;
    CGFloat buttonsSpace = 5.0f;
    UIBarButtonItem * accessoryItem;

    if ([buttons count])
    {
        for (UIButton * button in buttons) {
            buttonsBackground.frame = CGRectMake(buttonsBackground.frame.origin.x, 0.0f, CGRectGetWidth(buttonsBackground.frame) + button.frame.size.width, CGRectGetHeight(buttonsBackground.frame));
            button.frame = CGRectMake(menuButtonX, 0.0f, CGRectGetWidth(button.frame), CGRectGetHeight(button.frame));
            menuButtonX += (buttonsSpace + button.frame.size.width);

            [buttonsBackground addSubview:button];
        }

        accessoryItem = [[UIBarButtonItem alloc]initWithCustomView:buttonsBackground];
    }

    return accessoryItem;
}

- (void)callContact
{
    [self endEditing];
    NSString * r = [[self.historyDialog getPhoneFormatted:NO] stringByReplacingOccurrencesOfString:@" " withString:@""];
    r = [r hasPrefix:@"+"] ? r : [@"+" stringByAppendingString:r];
    NSString * phoneUrl = [@"tel://" stringByAppendingString:r];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneUrl]];
}

- (void)updateActiveStateOfChat
{
    if ([self isChatActive:self.historyDialog])
        [self activateChat];
    else
        [self deactivateChat];
}

- (void)addSendBarToView
{
    [self.inputView removeAllSubviews];

    self.sendBar = nil;
    [self createSendBar];

    self.sendBar.dumbMode = NO;
    self.sendBar.delegate = self;

    [self addChildViewController:self.sendBar];
    self.sendBarView = self.sendBar.view;
    [self.inputPanel addSubview:self.sendBarView];

    NSLayoutAttribute attributes[] = {NSLayoutAttributeTop, NSLayoutAttributeLeft, NSLayoutAttributeRight, NSLayoutAttributeBottom};
    for (int i = 0; i < 4; i++)
    {
        NSLayoutAttribute attribute = attributes[i];
        NSLayoutConstraint  * constraint = [NSLayoutConstraint constraintWithItem:self.inputPanel
                                                                        attribute:attribute
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.sendBarView
                                                                        attribute:attribute
                                                                       multiplier:1.0f
                                                                         constant:0.0f];
        [self.view addConstraint:constraint];
    }

    [self.sendBarView layoutIfNeeded];
    BOOL isChatWithUser = self.historyDialog.chatType == ChatTypeP2P;
    self.sendBar.expandTextButtonSize = (isChatWithUser || self.historyDialog.isGroup);
    [self.sendBar initSendBar];

    if ([self.historyDialog.unsentText length])
        [self.sendBar setInputText:self.historyDialog.unsentText];
}

- (void)createSendBar
{
    BarModel * barModel;
    if (self.historyDialog.hasSendBar)
        barModel = self.historyDialog.sendBar;
    else
        barModel = [[CoreDataFacade sharedInstance] senderBar];

    self.sendBar = [[SBCoordinator alloc] initWithBarModel:barModel];
    oldSendBar = barModel;
}

-(void)setHistoryDialog:(Dialog *)historyDialog
{
    BOOL isNewChat = ![_historyDialog.chatID isEqualToString:historyDialog.chatID];
    _historyDialog = historyDialog;

    if ([self isViewLoaded])
    {
        if (historyDialog && [historyDialog.needSync boolValue])
            [[ServerFacade sharedInstance] getChatHistory:historyDialog.chatID withRequestHandler:nil];

        if (isNewChat)
        {
            [self updateNavigationBar];
            [self updateChatBackground];
            [self initialMessagesLoadWithCompletionHandler:nil];
            [self addSendBarToView];
            [self updateActiveStateOfChat];
        }
    }

    [self cacheMainGroupChatKey:historyDialog.encryptionKey keysData:historyDialog.oldGroupKeysData];
}

- (void)addLocalNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(endEditing)
                                                 name:HideKeyboard
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(gotoGoolgeAuthScreen:)
                                                 name:GotoGoolgeAuth
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showMessageImageFromNotification:)
                                                 name:ShowFullScreenPicture
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addSelectViewToScene:)
                                                 name:PBAddSelectViewToScene
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeViewFromScene:)
                                                 name:PBRemoveViewFromScene
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sendMyLocaton:)
                                                 name:SendMyLocaton
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showHideQrScanner)
                                                 name:SNotificationQRScanShow
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(exitFromChat)
                                                 name:@"LEAVE_FOR_RESTART"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showProgress)
                                                 name:SNotificationShowProgress
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideProgress)
                                                 name:SNotificationHideProgress
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showAlertFromNotification:)
                                                 name:SNotificationShowMessage
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shareFMLString:)
                                                 name:SNotificationShare
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAction:)
                                                 name:SNotificationCallRobot
                                               object:nil];
}

- (void)removeLocalNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)exitFromChat
{
    [self deactivateChat];
    [self removeLocalNotifications];
    [self showProgress];
}

- (void)deactivateChat
{
    [self endEditing];
    self.inputPanel.hidden = YES;
    [self hideRightPanel];
    self.navigationItem.rightBarButtonItem = nil;
    if ([(NSObject *)self.presenter respondsToSelector:@selector(setChatSettingsEnabled:)])
        [self.presenter setChatSettingsEnabled:NO];
}

- (void)activateChat
{
    self.inputPanel.hidden = NO;
    self.navigationItem.rightBarButtonItem = [self createRightBarButton];
    if ([(NSObject *)self.presenter respondsToSelector:@selector(setChatSettingsEnabled:)])
        [self.presenter setChatSettingsEnabled:YES];
}

- (void)removeExtraViews
{
    [self keyboardWillHide:nil];
    if (imagePresenter.isPresentingImage)
        [imagePresenter dismissWindowWithImage];
}

- (void)showProgress
{
    CGRect rect = SENDER_SHARED_CORE.window.frame;
    startProgressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [startProgressView setColor:[SenderCore sharedCore].stylePalette.lineColor];
    startProgressView.frame = CGRectMake(rect.size.width/2 - 50,rect.size.height/2 - 50,100,100);
    [startProgressView startAnimating];
    [self.view addSubview:startProgressView];
    self.tableView.userInteractionEnabled = NO;
}

- (void)hideProgress
{
    [startProgressView stopAnimating];
    [startProgressView removeFromSuperview];
    startProgressView = nil;
    self.tableView.userInteractionEnabled = YES;
}

- (void)showAlertFromNotification:(NSNotification *)notification
{
    if ([[notification object] isKindOfClass:[NSString class]])
        [self showAlertWithText:(NSString *)[notification object]];
}

- (void)showAlertWithText:(NSString *)text
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:text
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"ok_ios", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Presenting Image From Message

-(void)presentImageFromMessageWithURL:(NSURL *)URL withExpansionFromFrame:(CGRect)fromFrame
{
    if (!imagePresenter.isPresentingImage)
    {
        [imagePresenter presentWindowWithImageWithLocalURL:URL
                                    withTransformFromFrame:fromFrame
                                                   toFrame:self.view.frame];
        statusBarHidden = YES;
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)imagePresenter:(ImagePresenter *)presenter didDismissed:(BOOL)unused
{
    self.tableView.userInteractionEnabled = YES;
    statusBarHidden = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - Right panel related methods

-(void)toggleRightPanel
{
    rightPanelVisible = !rightPanelVisible;
    if (rightPanelVisible)
    {
        if ([(NSObject *)self.presenter respondsToSelector:@selector(openChatSettings)])
            [self.presenter openChatSettings];
    }
    else
    {
        if ([(NSObject *)self.presenter respondsToSelector:@selector(closeChatSettings)])
            [self.presenter closeChatSettings];
    }
}

-(void)hideRightPanel
{
    rightPanelVisible = NO;
    if ([(NSObject *)self.presenter respondsToSelector:@selector(closeChatSettings)])
        [self.presenter closeChatSettings];
}

- (void)sendReadForMessage:(Message *)message
{
    if (message) [[ServerFacade sharedInstance] sayReadStatus:message];
}

#pragma mark - Notifications Handlers

- (void)handleAction:(NSNotification *)notification
{
    if ([(NSObject *)self.presenter respondsToSelector:@selector(handleAction:)])
        [self.presenter handleAction:notification.userInfo];
}

- (void)sendMyLocaton:(NSNotification *)notification
{
    [[MWLocationFacade sharedInstance].locationManager deviceLocation];
    [self endEditing];
    ShowMapViewController * smV = [[ShowMapViewController alloc] init];
    smV.delegate = self;

    if ([notification object]) {
        Message * locMessage = [notification object];
        smV.incommingLocale = [[ParamsFacade sharedInstance] dictionaryFromNSData:locMessage.modelData];
    }

    [self presentViewController:smV animated:YES completion:NULL];
}

- (void)locationSelect:(ShowMapViewController *)controller
        didFinishEnteringLocation:(CLLocation *)location
        withDesc:(NSString *)description
{

}

- (void)pushOnLocation:(ShowMapViewController *)controller
                                        didFinishEnteringLocation:(CLLocation *)location
                                        andImge:(UIImage *)image
                                        withDesc:(NSString *)description
{

   [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    if (!image) {
        return;
    }

    NSData * imageData = UIImageJPEGRepresentation(image, 0.4);

    NSNumber * latitude = @(location.coordinate.latitude);
    NSNumber * longitude = @(location.coordinate.longitude);

    NSDictionary * locDict = @{@"lat" : latitude, @"lon" : longitude, @"textMsg" : description};

    [[ServerFacade sharedInstance]shareMyLocation:locDict
                                        imageData:imageData
                                           inChat:self.historyDialog
                                completionHandler:nil];
}

- (void)shareFMLString:(NSNotification *)notification
{
    NSString * parsedString = notification.userInfo[@"parsedString"];
    UIActivityViewController *activityViewController =
            [[UIActivityViewController alloc] initWithActivityItems:@[parsedString]
                                              applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion: nil];
}

#pragma mark - Building Messages Views

- (MessageEmpy *)createSeparatorModelBeforeMessage:(Message *)message
{
    MessageEmpy *divModel = [[MessageEmpy alloc] init];
    divModel.created = [message.created dateByAddingTimeInterval:-20];
    divModel.dialog = self.historyDialog;
    divModel.type = @"DIVDATE";
    divModel.deliver = @"read";
    return divModel;
}

-(MessageEmpy *)createTypingModelForUser:(Contact *)user
{
    MessageEmpy * typingModel = [[MessageEmpy alloc] init];
    typingModel.dialog = self.historyDialog;
    typingModel.fromId = user.userID;
    typingModel.type = @"TYPING";
    typingModel.deliver = @"read";
    return typingModel;
}

-(void)updateTypingModelTitle:(MessageEmpy *)model withTypingUsers:(NSSet *)typingUsers
{
    NSString * name;
    name = [self.typingUsers count] ? [[ParamsFacade sharedInstance]buildStringFromUsersSet:typingUsers] : SenderFrameworkLocalizedString(@"add_friend", nil);
    NSString * typingText = [NSString stringWithFormat:SenderFrameworkLocalizedString(@"user_typing_ios", nil), name];
    [[(ChatTypingCell *)model.viewForCell notification] setText:typingText];
}

- (void)buildMessage:(id<MessageObject>)message
{
    if (!message) {
        return;
    }

    @try {
        UIView * messageView;

        if ([message.type isEqualToString:@"FORM"]) {
            messageView = [self formForMessage:message];
        } else if ([message.type isEqualToString:@"TEXT"] ||
                  [message.type isEqualToString:@"IMAGE"] ||
                  [message.type isEqualToString:@"VIDEO"] ||
                  [message.type isEqualToString:@"AUDIO"] ||
                  [message.type isEqualToString:@"SELFLOCATION"] ||
                  [message.type isEqualToString:@"STICKER"] ||
                  [message.type isEqualToString:@"VIBRO"] ||
                  [message.type isEqualToString:@"FILE"]) {
            messageView = [self regularMessageViewForMessage:message];
        } else if ([message.type isEqualToString:@"NOTIFICATION"] ||
                    [message.type isEqualToString:@"KEYCHAT"]) {
            messageView = [self notificationViewForMessage:message];
        } else if ([message.type isEqualToString:@"DIVDATE"]) {
            messageView = [self separatorViewForMessage:message];
        } else if ([message.type isEqualToString:@"TYPING"]) {
            messageView = [self typingViewForMessage:message];
        } else if ([message.type isEqualToString:@"MESSAGES_GAP"]) {
            messageView = [self buildMessagesGap:message];
        } else {
        }

        message.viewForCell = messageView;
    }
    @catch (NSException *exception) {

    }
    @finally {

    }
}

- (PBConsoleView *)formForMessage:(Message *)message
{
    return [PBConsoleManager buildConsoleViewFromDate:message forViewController:self];
}

- (UIView *)notificationViewForMessage:(Message *)message
{
    NSDate * notificationDate = message.created ?: [NSDate date];
    NSString * dateString = [[ParamsFacade sharedInstance]formatedStringFromNSDate:notificationDate];
    NSString * fullNotification = [NSString stringWithFormat:@"%@ %@", dateString, message.lasttext];

    ChatNotificationCell * notificationCell = [[ChatNotificationCell alloc] initWithFrame:CGRectZero
                                                                                     text:fullNotification];
    CGSize notificationCellSize = [notificationCell sizeThatFits:CGSizeMake(self.tableView.frame.size.width, FLT_MAX)];
    notificationCell.frame = CGRectMake(0.0f, 0.0f, self.tableView.frame.size.width, notificationCellSize.height);

    return notificationCell;
}

-(UIView *)separatorViewForMessage:(id<MessageObject>)message
{
    NSString *dividerDate = [[ParamsFacade sharedInstance] getDayAndMonthFromTime:message.created];

    ChatNotificationCell * notificationCell = [[ChatNotificationCell alloc] initWithFrame:CGRectZero
                                                                                     text:dividerDate];
    CGSize notificationCellSize = [notificationCell sizeThatFits:CGSizeMake(self.tableView.frame.size.width, FLT_MAX)];
    notificationCell.frame = CGRectMake(0.0f, 0.0f, self.tableView.frame.size.width, notificationCellSize.height);

    return notificationCell;
}

- (UIView *)typingViewForMessage:(id<MessageObject>)message
{
    ChatTypingCell * typingIndicatorView = [[ChatTypingCell alloc] initWithFrame:CGRectZero
                                                                            text:@""];
    CGSize typingIndicatorCellSize = [typingIndicatorView sizeThatFits:CGSizeMake(self.tableView.frame.size.width, FLT_MAX)];
    typingIndicatorView.frame = CGRectMake(0.0f, 0.0f, self.tableView.frame.size.width, typingIndicatorCellSize.height);

    return typingIndicatorView;
}

- (UIView *)buildMessagesGap:(id<MessageObject>)messagesGap
{
    if ([messagesGap isKindOfClass:[GapMessage class]] && ![(GapMessage *)messagesGap isActive])
        return nil;

    NSString * gapText = SenderFrameworkLocalizedString(@"loading_msg", nil);
    ChatNotificationCell * notificationCell = [[ChatNotificationCell alloc] initWithFrame:CGRectZero
                                                                                     text:gapText];
    CGSize notificationCellSize = [notificationCell sizeThatFits:CGSizeMake(self.tableView.frame.size.width, FLT_MAX)];
    notificationCell.frame = CGRectMake(0.0f, 0.0f, self.tableView.frame.size.width, notificationCellSize.height);

    return notificationCell;
}

- (CellProtoType *)regularMessageViewForMessage:(id<MessageObject>)msgModel
{
    CellProtoType * cellProt = [[CellProtoType alloc] initWithModel:msgModel andWidth:self.tableView.frame.size.width];
    // disabled
    cellProt.delegate = self;
    cellProt.fileViewDelegate = self;
    BOOL showImage = YES;

    Message * lastMsg = [tableViewsArrayChild lastObject];
    if ([lastMsg.viewForCell isKindOfClass:[CellProtoType class]] &&
            [lastMsg.fromId isEqualToString:msgModel.fromId] &&
            ![lastMsg.type isEqualToString:@"FORM"]) {
        if ([[ParamsFacade sharedInstance] compare3MinutesRange:lastMsg.created withTime:msgModel.created]) {
            showImage = NO;
        }
    }

    [cellProt configureCell:msgModel showUserImage:showImage];
    return cellProt;
}

- (void)tableViewScrollToNewMessage
{
    [self tableViewScrollToBottomAnimated:YES];
}

#pragma mark - UITextField

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Keyboard related methods

- (void)keyboardWillShow:(NSNotification *)notification
{
    keyboardIsVisible = YES;
    id firstResponder = [[[UIApplication sharedApplication] keyWindow] performSelector:@selector(findFirstResponder)];

    NSIndexPath * index = [self.tableView indexPathForCell:(UITableViewCell *)[[[[[[firstResponder superview] superview] superview] superview] superview] superview]];

    if (index)
        [self.tableView scrollToRowAtIndexPath:index atScrollPosition:UITableViewScrollPositionBottom animated:YES];

    [self.view layoutIfNeeded];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    if (self.sendBar.isEnteringText)
        [self tableViewScrollToBottomAnimated:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    keyboardIsVisible = NO;
    [self.view layoutIfNeeded];
}

- (void)endEditing
{
    id firstResponder = [[[UIApplication sharedApplication] keyWindow] performSelector:@selector(findFirstResponder)];
    [firstResponder endEditing:YES];
    [self.sendBar initSendBar];
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowNumber = 1;
    if (section == 0)
        rowNumber = self.hasCompletedInitialLoad ? [self.messages.visibleMessages count] : 0;
    return rowNumber;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [self createCellAtIndexPath:indexPath];
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1)
    {
        if (self.typingIndicatorModel)
            [cell.contentView addSubview:self.typingIndicatorModel.viewForCell];
    }
    else
    {
        id<MessageObject> currentMessage = self.messages.visibleMessages[indexPath.row];

        [self configureMessageCell:cell atIndexPath:indexPath];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        currentMessage.indexPath =  indexPath;

        if ([currentMessage isKindOfClass:[GapMessage class]] && [(GapMessage *)currentMessage isActive])
        {
            __weak Dialog * weakHistoryDialog = self.historyDialog;
            [self.historyLoader loadHistoryForMessagesGap:[(GapMessage *)currentMessage gap]
                                        completionHandler:^(BOOL success) {
                                            if (success)
                                            {
                                                [weakHistoryDialog removeGapsObject:[(GapMessage *)currentMessage gap]];
                                                [[SenderCore sharedCore].interfaceUpdater chatsWereChanged:@[weakHistoryDialog]];
                                            }
                                        }];
        }
    }
    [UIView performWithoutAnimation:^{ [cell layoutIfNeeded]; }];
}

- (UITableViewCell *)createCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:FormViewCellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];

    if (indexPath.section == 1)
    {
        if (self.typingIndicatorModel)
        {
            if (!self.typingIndicatorModel.viewForCell)
                self.typingIndicatorModel.viewForCell = [self typingViewForMessage:self.typingIndicatorModel];

            [self updateTypingModelTitle:self.typingIndicatorModel withTypingUsers:[self.typingUsers copy]];

            cell.contentView.frame = CGRectMake(cell.contentView.frame.origin.x,
            cell.contentView.frame.origin.y,
            cell.contentView.frame.size.width,
            self.typingIndicatorModel.viewForCell.frame.size.height);
        }
    }
    else
    {
        [UIView performWithoutAnimation:^{
            Message * currentMessage = self.messages.visibleMessages[indexPath.row];
            if (!currentMessage.viewForCell)
                [self buildMessage:currentMessage];

            if ([currentMessage.viewForCell isKindOfClass:[CellProtoType class]])
            {
                if ([self isUserImageVisibleForMessage:currentMessage atIndexPath:indexPath])
                    [(CellProtoType*)currentMessage.viewForCell showCellImage];
                else
                    [(CellProtoType*)currentMessage.viewForCell hideCellImage];

                if ([self isStatusVisibleForMessage:currentMessage atIndexPath:indexPath])
                    [(CellProtoType*)currentMessage.viewForCell showStatus];
                else
                    [(CellProtoType*)currentMessage.viewForCell hideStatus];
            }
        }];
    }

    return cell;
}

- (void)configureMessageCell:(UITableViewCell *)cell
                 atIndexPath:(NSIndexPath *)indexPath
{
    Message *model = self.messages.visibleMessages[indexPath.row];
    model.indexPath = indexPath;
    [cell.contentView addSubview:model.viewForCell];

    if (model.viewForCell)
    {
        model.viewForCell.translatesAutoresizingMaskIntoConstraints = NO;

        [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:cell.contentView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:model.viewForCell
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:model.viewForCell.frame.origin.y]];

        [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:cell.contentView
                                                                     attribute:NSLayoutAttributeLeft
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:model.viewForCell
                                                                     attribute:NSLayoutAttributeLeft
                                                                    multiplier:1.0
                                                                      constant:-model.viewForCell.frame.origin.x]];

        [model.viewForCell addConstraint:[NSLayoutConstraint constraintWithItem:model.viewForCell
                                                                      attribute:NSLayoutAttributeWidth
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:nil
                                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                                     multiplier:1.0f
                                                                       constant:model.viewForCell.frame.size.width]];

        [model.viewForCell addConstraint:[NSLayoutConstraint constraintWithItem:model.viewForCell
                                                                      attribute:NSLayoutAttributeHeight
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:nil
                                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                                     multiplier:1.0f
                                                                       constant:model.viewForCell.frame.size.height]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForConsoleFormMessageCellAtIndexPath:indexPath];
}

- (CGFloat)heightForConsoleFormMessageCellAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1)
    {
        if (!self.typingIndicatorModel.viewForCell) [self buildMessage:self.typingIndicatorModel];
        return self.typingIndicatorModel.viewForCell.frame.size.height;
    }
    else
    {
        Message * model = self.messages.visibleMessages[indexPath.row];
        if (!model.viewForCell) [self buildMessage:model];
        return model.heightConsoleForm;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableViewScrollToBottomAnimated:(BOOL)animated
{
    NSIndexPath * lastCellPath = [NSIndexPath indexPathForRow:0 inSection:1];
    [self.tableView scrollToRowAtIndexPath:lastCellPath
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:animated];
}

- (void)cellCallForModel:(Message *)model doAction:(CellAction)action
{
    if (action == DELETE)
    {
        [self editMessage:model withText:@"" encryptionEnabled:NO failHandler: ^{

            UIAlertController * alert = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"unable_to_delete_message_title", nil)
                                                                            message:nil
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * okAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"ok_ios", nil)
                                                                style:UIAlertActionStyleCancel
                                                              handler:nil];
            [alert addAction:okAction];
            [alert mw_safePresentInViewController:self animated:YES completion:nil];
        }];
    }
    else if (action == EDIT)
    {
        messageForEdit = model;
        [self.sendBar runEditText:model.textMessage];
    }
}

- (void)editMessage:(Message *)message
           withText:(NSString *)text
  encryptionEnabled:(BOOL)eEnabled
        failHandler:(void(^_Nullable)())failHandler
{
    NSString * oldText = [message.textMessage copy];
    NSNumber * oldEncrypted = [message.encrypted copy];
    NSData * oldData = [message.data copy];
    NSString  * oldLastText = [message.lasttext copy];
    BOOL oldDeletedMessage = message.deletedMessage;

    [message updateWithText:text encryptionEnabled:eEnabled];
    [[ServerFacade sharedInstance] sendMessage:message
                                    withDialog:self.historyDialog
                             completionHandler:^(NSDictionary *response, NSError *error) {
                                 NSString * crCode;
                                 id cr = response[@"cr"];
                                 if ([cr isKindOfClass:[NSArray class]] && [[response[@"cr"] firstObject] isKindOfClass:[NSDictionary class]])
                                     crCode = [response[@"cr"] firstObject][@"code"];
                                 if (error || [crCode isEqual:@13])
                                 {
                                     message.lasttext = oldLastText;
                                     message.encrypted = oldEncrypted;
                                     message.data = oldData;
                                     message.textMessage = oldText;
                                     message.deletedMessage = oldDeletedMessage;
                                     [SENDER_SHARED_CORE.interfaceUpdater messagesWereChanged:@[message]];
                                     if (failHandler)
                                         failHandler();
                                 }
                             }
    ];
}

- (void)takePhoto
{
    if (!cameraManager) {
        cameraManager = [[CameraManager alloc] initWithParentController:self chat:self.historyDialog];
        cameraManager.delegate = self;
    }

    [cameraManager showCamera];
}

- (void)cameraManager:(CameraManager *)camera sendImageToServer:(UIImage *)image forURL:(NSString *)urlSting
{
    [[ServerFacade sharedInstance] uploadImage:image withLocalURL:urlSting chatID:self.historyDialog.chatID];

    camera = nil;
    camera.delegate = nil;

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)showMessageImageFromNotification:(NSNotification *)notification
{
    [self endEditing];
    NSDictionary * data = [notification object];
    self.tableView.userInteractionEnabled = NO;
    self.hideKeyboardRecognizer.enabled = NO;

    UIImageView * cellImg = (UIImageView *)data[@"imageView"];
    Message * cellMessage = (Message *)data[@"message"];
    CGRect fromFrame = [[cellImg superview] convertRect:cellImg.frame toView:self.view];
    NSURL * imageURL = [NSURL URLWithString:cellMessage.file.localUrl];

    if (imageURL)
        [self presentImageFromMessageWithURL:imageURL withExpansionFromFrame:fromFrame];
}

- (void)addSelectViewToScene:(NSNotification *)notification
{
    [self hideRightPanel];
    [self endEditing];

    self.hideKeyboardRecognizer.enabled = NO;
    self.tableView.scrollsToTop = NO;
    
    UIView * subview = (UIView *)[notification object];
    UIView * superview = [SenderCore sharedCore].window;
    
    [superview addSubview:subview];
    subview.translatesAutoresizingMaskIntoConstraints = NO;
    [superview pinSubview:subview];
}

- (void)removeViewFromScene:(NSNotification *)notification
{
    self.hideKeyboardRecognizer.enabled = YES;
    self.tableView.scrollsToTop = YES;
    [[notification object] removeFromSuperview];
}

- (void)addPullToRefresh
{
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(loadHistoryAfterPullToRefresh:)
             forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
}

- (void)addUsersToChat
{
    if ([(NSObject *)self.presenter respondsToSelector:@selector(addMembersToChat)])
        [self.presenter addMembersToChat];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self fixScrollToBottomButton];
}

- (void)fixScrollToBottomButton
{
    CGFloat lastVisiblePointY = self.tableView.contentOffset.y + self.tableView.frame.size.height;
    lastVisiblePointY -= (self.tableView.contentInset.bottom + self.tableView.contentInset.top);
    CGFloat contentHeight = self.tableView.contentSize.height;
    CGFloat maxBottomOffset = self.tableView.frame.size.height / 2.0f;
    BOOL shouldHideButton = lastVisiblePointY >= contentHeight || contentHeight - lastVisiblePointY <= maxBottomOffset;
    self.scrollToBottomButton.hidden = shouldHideButton;
}

#pragma mark - SBCoordinator Delegate

- (void)coordinator:(SBCoordinator *)coordinator didExpandTextView:(BOOL)unnessesaryParameter
{
    [self tableViewScrollToBottomAnimated:YES];
}

- (void)coordinator:(SBCoordinator *)coordinator didSelectItemWithActions:(NSArray *)actionsArray
{
    if (rightPanelVisible) [self hideRightPanel];

    for (NSDictionary * actionDictionary in actionsArray)
    {
        NSString * operation = actionDictionary[@"oper"];

        if ([operation isEqualToString:@"sendMedia"])
        {
            if ([actionDictionary[@"type"] isEqualToString:@"sticker"])
            {
                [self.sendBar showActionsView:SBCoordinatorViewStickers];
            }
            else if ([actionDictionary[@"type"]isEqualToString:@"file"])
            {
            }
            else if ([actionDictionary[@"type"]isEqualToString:@"smile"])
            {
                [self.sendBar startEmojiInput];
            }
            else if ([actionDictionary[@"type"]isEqualToString:@"voice"])
            {
                [self.sendBar showActionsView:SBCoordinatorViewAudio];
            }
            else if ([actionDictionary[@"type"]isEqualToString:@"vibro"])
            {
                Message * mesg = [[CoreDataFacade sharedInstance]writeVibroMessageInChat:self.historyDialog.chatID];
                self.historyDialog.lastMessageStatus = MessageStatusSent;
                [[ServerFacade sharedInstance] sendVibroMessage:mesg];
                self.writtenOwnerMessage = mesg;
            }
            else if ([actionDictionary[@"type"]isEqualToString:@"photo"]) {
                [self endEditing];

                if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {

                    UIAlertController * alert = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"error_ios", nil)
                                                                                    message:SenderFrameworkLocalizedString(@"device_without_camera_ios", nil)
                                                                             preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction * okAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"ok_ios", nil)
                                                                        style:UIAlertActionStyleCancel
                                                                      handler:nil];
                    [alert addAction:okAction];
                    [alert mw_safePresentInViewController:self animated:YES completion:nil];
                }
                else
                {
                    [self takePhoto];
                }
            }
            else if ([actionDictionary[@"type"]isEqualToString:@"video"]) {
                [self endEditing];
                if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                    UIAlertController * alert = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"error_ios", nil)
                                                                                    message:SenderFrameworkLocalizedString(@"device_without_camera_ios", nil)
                                                                             preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction * okAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"ok_ios", nil)
                                                                        style:UIAlertActionStyleCancel
                                                                      handler:nil];
                    [alert addAction:okAction];
                    [alert mw_safePresentInViewController:self animated:YES completion:nil];
                }
                else
                {
                    videoManager = [[VideoManager alloc] initWithParentController:self chatId:self.historyDialog.chatID];
                    [videoManager showCamera];
                }
            }
            else if ([actionDictionary[@"type"]isEqualToString:@"location"]) {
                [self sendMyLocaton:nil];
            }
            else if ([actionDictionary[@"type"]isEqualToString:@"twitch"])
            {
                NSDictionary * runData = @{@"class": @".alert.sender"};
                if ([(NSObject *)self.presenter respondsToSelector:@selector(handleAction:)])
                    [self.presenter handleAction:runData];
            }
        }
        else if ([operation isEqualToString:@"addUser"]) {
            [self addUsersToChat];
        }
        else if ([operation isEqualToString:@"switchCrypto"])
        {
            [self toggleEncryption];
        }
        else if ([operation isEqualToString:@"qrScan"])
        {
            [self showHideQrScanner];
        }
        else if ([operation isEqualToString:@"goTo"])
        {
//            [[SenderCore sharedCore].router presentMainViewControllerAnimated:YES modally:NO];
        }
        else if ([operation isEqualToString:@"viewLink"])
        {
            if ([actionDictionary[@"link"] length])
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionDictionary[@"link"]]];
        }
        else if ([operation isEqualToString:@"callPhone"])
        {
            NSString * phoneUrl = [@"telprompt://" stringByAppendingString:actionDictionary[@"phone"]];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneUrl]];
        }
        else if ([operation isEqualToString:@"callRobotInP2PChat"] ||
                [operation isEqualToString:@"callRobot"] ||
                [operation isEqualToString:@"startP2PChat"])
        {
            if ([(NSObject *)self.presenter respondsToSelector:@selector(handleAction:)])
                [self.presenter handleAction:actionDictionary];
        }

        /*
         * Internal actions are actions, we've created for ourselves to simplify actions handling.
         * They are used for native elements.
         */
        else if ([operation isEqualToString:@"__internal__sendSticker"])
        {
            NSString * stickerID = actionDictionary[@"stickerID"];
            Message * mesg = [[CoreDataFacade sharedInstance] writeMessageWithSticker:stickerID
                                                                               inChat:self.historyDialog.chatID];
            self.historyDialog.lastMessageStatus = MessageStatusSent;
            [[ServerFacade sharedInstance] sendStickerMessage:mesg];
            self.writtenOwnerMessage = mesg;
        }
        else if ([operation isEqualToString:@"__internal__sendAudio"])
        {
            NSData * trackData = actionDictionary[@"trackData"];
            Message * voice = [[CoreDataFacade sharedInstance] writeVoiceMessageToChat:self.historyDialog.chatID];
            NSDictionary * messageDict = @{@"type":voice.type,
                                           @"chat":voice.chat,
                                           @"moId":voice.moId,
                                           @"target":@"upload"};
            self.historyDialog.lastMessageStatus = MessageStatusSent;
            [[ServerFacade sharedInstance] uploadFileToServer:trackData previewImage:nil byMessage:messageDict];
            self.writtenOwnerMessage = voice;
        }
        else if ([operation isEqualToString:@"__internal__sendText"])
        {
            NSString * text = actionDictionary[@"text"];
            text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [self sendTextMessageWithText:text];
        }
    }
}

- (void)coordinatorDidType:(SBCoordinator *)coordinator
{
    [[ServerFacade sharedInstance] sendTypingToChatWithID:self.historyDialog.chatID requestHandler:nil];
}

- (void)toggleEncryption
{
    if (![[SenderCore sharedCore] isBitcoinEnabled])
    {
        [self showEncryptionUnavailableInRestrictedAlert];
        return;
    }

    [self updateTitleImage];
    if (self.historyDialog.isGroup)
    {
        BOOL newEncryptionStatus = ![self.historyDialog isEncrypted];
        [self.chatEditManager setEncryptionStateOfChat:self.historyDialog
                                       encryptionState:newEncryptionStatus
                                     completionHandler:^(Dialog * chat, NSError * error) {

                                     }];
    }
}

- (void)showEncryptionUnavailableInRestrictedAlert
{
    NSString * title = SenderFrameworkLocalizedString(@"encryption_restricted_mode_unavailable_alert_title", nil);
    NSString *  message = SenderFrameworkLocalizedString(@"encryption_restricted_mode_unavailable_alert_message", nil);
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:title
                                                                              message:message
                                                                       preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"ok_ios", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:nil];

    [alertController addAction:cancelAction];
    [alertController mw_safePresentInViewController:self animated:YES completion:nil];
}

- (void)coordinator:(SBCoordinator *)coordinator didFinishEditingText:(NSString *)text
{
    BOOL enc = [self.historyDialog isEncrypted];

    if (self.historyDialog.isP2P)
        enc = (self.historyDialog.p2pBTCKeyData.length > 10) ? [self.historyDialog isEncrypted] : NO;

    if (messageForEdit) {
        [self editMessage:messageForEdit withText:text encryptionEnabled:enc failHandler: ^{
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"unable_to_edit_message_title", nil)
                                                                            message:nil
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * okAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"ok_ios", nil)
                                                                style:UIAlertActionStyleCancel
                                                              handler:nil];
            [alert addAction:okAction];
            [alert mw_safePresentInViewController:self animated:YES completion:nil];
        }];
        [self tableViewScrollToBottomAnimated:YES];
    }

    messageForEdit = nil;
}

- (void)coordinator:(SBCoordinator *)coordinator didChangeItsHeight:(CGFloat)newHeight
{
    if (self.hidesSendBar)
        return;

    CGFloat oldHeight = self.inputFieldHeight.constant;
    self.inputFieldHeight.constant = newHeight;

    [UIView animateWithDuration:0.3f animations:^{
        [self.view layoutIfNeeded];
        CGFloat heightChange = newHeight - oldHeight;
        if (heightChange > 0) {
            CGPoint newContentOffset = self.tableView.contentOffset;
            newContentOffset.y += heightChange;
            if (!CGPointEqualToPoint(self.tableView.contentOffset, newContentOffset))
                [self.tableView setContentOffset:newContentOffset];
        }
    }];
}

-(BOOL)coordinator:(SBCoordinator *)coordinator isCurrentChatEncripted:(BOOL)unnessesaryParameter
{
    return [self.historyDialog isEncrypted];
}

- (void)sendTextMessageWithText:(NSString *)text
{
    NSString * textToSend = text;
    NSString * restOfText;
    if ([text length] > 5000)
    {
        textToSend = [text substringToIndex:5000];
        restOfText = [text substringFromIndex:5000];
    }
    BOOL enc = [self.historyDialog isEncrypted];

    if ([[CoreDataFacade sharedInstance] getOwner].walletState == BitcoinWalletStateReady)
    {    
		if (self.historyDialog.isP2P)
        	enc = self.historyDialog.p2pBTCKeyData.length > 10; //[self.historyDialog.encrypted boolValue] : NO;
	    else
    	    if (!self.historyDialog.encryptionKey.length) enc = NO;
	}

    Message * message = [[CoreDataFacade sharedInstance] writeMessageWithText:textToSend
                                                                    inChat:self.historyDialog.chatID
                                                                 encripted:enc];
    if (message)
    {
        self.historyDialog.lastMessageStatus = MessageStatusSent;
        [[ServerFacade sharedInstance] sendMessage:message
                                        withDialog:self.historyDialog
                                 completionHandler:^(NSDictionary *response, NSError *error) {
                                 }];
    }
    if (restOfText)
        [self sendTextMessageWithText:restOfText];

    self.writtenOwnerMessage = message;
}

#pragma mark - Chat controller updating

- (void)updateChatBackground
{
    __weak __typeof(self)wself = self;
    void (^ imageSetCompletion)(UIImage *) = ^void(UIImage * image) {
        if (!wself.chatBg)
        {
            CGFloat imageWidth = wself.view.bounds.size.width;
            CGFloat imageHeight = wself.view.bounds.size.height;
            wself.chatBg = [[UIImageView alloc]initWithFrame:CGRectMake(0.0f, 0.0f, imageWidth, imageHeight)];
            [wself.view insertSubview:wself.chatBg atIndex:0];
        }
        if (image)
        {
            wself.chatBg.contentMode = UIViewContentModeScaleAspectFill;
            wself.chatBg.image = image;
            wself.chatBg.clipsToBounds = YES;
        }
    };

    if (self.customBackgroundImage)
    {
        [ImagesManipulator backgroundImageWithImage:self.customBackgroundImage completionHandler:imageSetCompletion];
    }
    else if (self.customBackgroundImageURL)
    {
        [ImagesManipulator backgroundImageWithURL:self.customBackgroundImageURL completionHandler:imageSetCompletion];
    }
    else
    {
        oldChatBackgroundURL = self.historyDialog.imageURL;
        [ImagesManipulator backgroundImageWithChat:self.historyDialog completionHandler:imageSetCompletion];
    }
}

#pragma mark - QR

- (void)showHideQrScanner
{
    if ([(NSObject *)self.presenter respondsToSelector:@selector(showQRScanner)])
        [self.presenter showQRScanner];
}

#pragma mark - Utility Methods And Functions

BOOL isValidForSendingRead(Message * message) {
    return  !message.owner &&
            ![message.type isEqualToString:@"DIVDATE"];
    //![message.type isEqualToString:@"NOTIFICATION"] Depricated!!!
            //    &&
//            ![message.deliver isEqualToString:@"read"];
}

BOOL isSeparatorNeededBetweenMessages(id<MessageObject> previousMessage, id<MessageObject> nextMessage)
{
    return  previousMessage.created &&
            nextMessage.created &&
            [[ParamsFacade sharedInstance] compareTime:previousMessage.created withTime:nextMessage.created] &&
            ![previousMessage.type isEqualToString:@"DIVDATE"] &&
            ![nextMessage.type isEqualToString:@"DIVDATE"];
}

- (BOOL)needsUpdateChatBackgroundWithNewImageURL:(NSString *)imageURL
{
    BOOL imageHasChanged = (![imageURL isEqualToString:oldChatBackgroundURL] && imageURL);
    return  (!self.customBackgroundImage && !self.customBackgroundImageURL) && imageHasChanged;
}

- (BOOL)needsReloadEncryptedMessagesWithNewGroupChatKey:(NSData *)chatKey keysData:(NSData *)keysData
{
    return !isDataEqual(oldChatKey, chatKey) || !isDataEqual(oldKeysData, keysData);
}

- (BOOL)needsReloadSendBarWithChat:(Dialog *)chat
{
    return ([chat hasSendBar]) && ![oldSendBar isEqual:[chat sendBar]];
}

- (BOOL)isStatusVisibleForMessage:(Message *) message atIndexPath:(NSIndexPath *) indexPath
{
    return message.owner && (indexPath.row == [self.tableView numberOfRowsInSection:0] - 1);
}

-(BOOL)isUserImageVisibleForMessage:(Message *) message atIndexPath:(NSIndexPath *) indexPath
{
    if (indexPath.row == 0) return YES;
    Message * previousMessage = self.messages.visibleMessages[indexPath.row - 1];

    return  ![previousMessage.fromId isEqualToString:message.fromId] ||
            [previousMessage.type isEqualToString:@"form"] ||
            ![[ParamsFacade sharedInstance] compare3MinutesRange:previousMessage.created withTime:message.created];

}

- (Message *)getTopMessage
{
    Message * topMessage;
    for (NSIndexPath * visibleRowPath in [self.tableView indexPathsForVisibleRows])
    {
        if (visibleRowPath.section == 0)
        {
            Message * message = self.messages.visibleMessages[visibleRowPath.row];
            if (![message.type isEqualToString:@"DIVDATE"] && ![message.type isEqualToString:@"MESSAGES_GAP"])
            {
                topMessage = message;
                break;
            }
        }
    }
    return topMessage;
}

- (NSIndexPath * )indexPathForMessage:(Message *)message
{
    NSIndexPath * indexPath;
    NSUInteger messageIndex = [self.messages.visibleMessages indexOfObject:message];
    if (messageIndex != NSNotFound)
        indexPath = [NSIndexPath indexPathForRow:messageIndex inSection:0];

    return indexPath;
}

BOOL isDataEqual(NSData * data1, NSData * data2)
{
    if (!data1)
        return data2 == nil;
    else if (!data2)
        return data1 == nil;
    else
        return [data1 isEqualToData:data2];
}

- (void)cacheMainGroupChatKey:(NSData *)chatKey keysData:(NSData *)keysData {
    oldKeysData = keysData;
    oldChatKey = chatKey;
}

#pragma mark Google SignIn

- (void)gotoGoolgeAuthScreen:(NSNotification *)notification
{
    googleModel = [notification object];
    [GIDSignIn sharedInstance].delegate = self;
    [GIDSignIn sharedInstance].uiDelegate = self;
    [[GIDSignIn sharedInstance] signIn];
}

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error
{
    NSString * accessToken = user.authentication.accessToken ?: @"";
    NSString * userId = user.userID ? user.userID:@"";                  // For client-side use only!
    NSString * idToken = user.authentication.idToken ? user.authentication.idToken: @""; // Safe to send to the server
    NSString * fullName = user.profile.name ? user.profile.name:@"";
    NSString * givenName = user.profile.givenName ? user.profile.givenName:@"";
    NSString * familyName = user.profile.familyName ? user.profile.familyName:@"";
    NSString * email = user.profile.email ? user.profile.email:@"";
    
    [[CoreDataFacade sharedInstance].owner setGoogleAccount:@{@"accessToken": accessToken,
                                                           @"userId": userId,
                                                           @"idToken": idToken,
                                                           @"fullName": fullName,
                                                           @"givenName": givenName,
                                                           @"familyName": familyName,
                                                           @"email": email
                                                           }];
    
    [[ServerFacade sharedInstance] sendGoogleTokenToServer:accessToken completionHandler:^(NSDictionary *response, NSError *error) {
        if (!error) {
            for (NSDictionary * action in googleModel.viewModel.actions) {
                NSLog(@"%@",action);
                if ([googleModel.viewModel detectAction:action] == SubmitOnChange) {
                    
                    if (googleModel.viewModel.name && googleModel.viewModel.val) {
                        
                        NSMutableDictionary * outData = [[NSMutableDictionary alloc] initWithDictionary:action[@"data"]];
                        [outData setObject:googleModel.viewModel.val forKey:googleModel.viewModel.name];
                        [googleModel submitOnchangeAction:outData];
                    }
                }
            }
        }
    }];
}

- (void)signIn:(GIDSignIn *)signIn
didDisconnectWithUser:(GIDGoogleUser *)user
     withError:(NSError *)error
{
    // show allert *&&&????
}

#pragma mark - DragWireframe Delegate

- (void)dragWireframeWillStartMovingView:(DragFromRightWireframe *)dragWireframe
{
    [self endEditing];
}

- (void)dragWireframeDidEndMovingView:(DragFromRightWireframe *)dragWireframe
{
    BOOL draggableViewVisible = dragWireframe.isChildViewVisible;
    rightPanelVisible = draggableViewVisible;
    self.hideKeyboardRecognizer.enabled = !draggableViewVisible;
    self.tableView.scrollsToTop = !draggableViewVisible;
    self.navigationController.interactivePopGestureRecognizer.enabled = !draggableViewVisible;
}

- (void)updateWithViewModel:(Dialog *)viewModel
{
    self.historyDialog = viewModel;
}

- (void)dragWireframeDidDismissView:(DragFromRightWireframe *)dragWireframe
{
    rightPanelVisible = NO;
}


#pragma mark - ModalInNavigationWireframe Events Handler

- (void)prepareForPresentationWithModalInNavigationWireframe:(ModalInNavigationWireframe *)modalInNavigationWireframe
{
    UIImage *closeImage = [UIImage imageFromSenderFrameworkNamed:@"close"];
    self.leftBarButtonImage = [closeImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)prepareForDismissalWithModalInNavigationWireframe:(ModalInNavigationWireframe *)modalInNavigationWireframe
{

}

@end

@interface ChatViewController(FileViewDelegate) <FileViewDelegate, UIDocumentInteractionControllerDelegate>

@property(nonatomic, strong) UIDocumentInteractionController * documentInteractionController;

@end

@implementation ChatViewController(FileViewDelegate)

- (void)fileView:(FileView *)fileView didSelectMessage:(Message *)message
{
    if ([message.dialog.chatID isEqualToString:self.historyDialog.chatID])
    {
        NSURL * fileURL = [NSURL URLWithString:message.file.localUrl];
        if (fileURL)
        {
            self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
            self.documentInteractionController.delegate = self;
            [self.documentInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
        }
    }
}

- (UIDocumentInteractionController *)documentInteractionController
{
    return objc_getAssociatedObject(self, @selector(documentInteractionController));
}

- (void)setDocumentInteractionController:(UIDocumentInteractionController *)documentInteractionController
{
    objc_setAssociatedObject(self,
            @selector(documentInteractionController),
            documentInteractionController,
            OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
