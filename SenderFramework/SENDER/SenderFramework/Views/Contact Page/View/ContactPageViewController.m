//
//  ContactPageViewController.m
//  Sender
//
//  Created by Nick Gromov on 9/15/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "ContactPageViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "Contact.h"
#import "Item.h"
#import "PBConsoleConstants.h"
#import "SenderNotifications.h"
#import "ServerFacade.h"
#import "Dialog.h"
#import "ChatViewController.h"
#import "NSString+PBMessages.h"
#import "UIView+subviews.h"
#import "UIImageView (UITextFieldBackground).h"
#import "UIImage+Resize.h"
#import "UIAlertView+CompletionHandler.h"
#import "DialogSetting.h"
#import "MainButtonCell.h"
#import "DefaultContactImageGenerator.h"
#import "ImagesManipulator.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import <libPhoneNumber_iOS/NBPhoneNumberUtil.h>

void SetLabelSize(UILabel * label, float height)
{
    if(height > label.frame.size.height)
    {
        CGRect rect = label.frame;
        rect.size = (CGSize){label.frame.size.width, height};
        label.frame = rect;
    }
}

@interface ContactPageViewController ()
{
    IBOutlet UIImageView * userImage;
    IBOutlet UITextField * username;
    IBOutlet UILabel * infoLabel;
    IBOutlet UITextField * phoneField;
    
    IBOutlet UIButton * changePhotoButton;
    
    BOOL isEditing;
    BOOL tempBlocked;
    BOOL tempFavorite;
    BOOL hasAddedSendbar;

    IBOutlet UIButton * acceptButton;
    
    UIBarButtonItem * favoriteButton;
    
    CALayer * sendBarTopBorder;
    CALayer * userNameBottomBorder;
    CALayer * phoneBottomBorder;

    NSString * savedName;
    NSString * savedPhone;
    
    NSString * phoneNumber;
    UIView * reportUserView;
    
    NSArray * mainActions;
    
    MainActionModel * blockModel;
    MainActionModel * callModel;
    MainActionModel * editModel;
    MainActionModel * deleteModel;
    MainActionModel * complaintModel;
    MainActionModel * settingModel;
    MainActionModel * hideSettingModel;

    MWChatEditManager * chatEditManager;
}

@property (strong, nonatomic) SBCoordinator * sendBar;
@property (strong, nonatomic) UIView * sendBarView;

@property (nonatomic, strong) UISwipeGestureRecognizer * swipeGestureRecognizerDown;

@property (nonatomic, weak) IBOutlet UIView * inputPanel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * bottomSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * inputPanelHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollBottomSpace;

@property (weak, nonatomic) IBOutlet UICollectionView * mainCollectionView;

@end

@implementation ContactPageViewController

@synthesize presenter = _presenter;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.sendBarView = nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self.sendBar];
    if (self.sendBar)
        self.sendBar = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.presenter viewWasLoaded];
    [self customizeNavigationBar];

    MWChatEditManagerInput * chatEditManagerInput = [[MWChatEditManagerInput alloc] init];
    chatEditManager = [[MWChatEditManager alloc]initWithInput:chatEditManagerInput];
    [chatEditManager updateWithChat:self.p2pChat completionHandler:nil];

    isEditing = NO;
    [self customizeViewForEditingState:isEditing];

    username.textColor = [SenderCore sharedCore].stylePalette.mainTextColor;
    username.attributedPlaceholder = [[SenderCore sharedCore].stylePalette placeholderWithString:SenderFrameworkLocalizedString(@"contact_name_ph_ios", nil)];

    phoneField.attributedPlaceholder = [[SenderCore sharedCore].stylePalette placeholderWithString:SenderFrameworkLocalizedString(@"phone_number", nil)];

    self.swipeGestureRecognizerDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handleSwipeGesturesDown)];
    self.swipeGestureRecognizerDown.delegate  = self;
    [self.swipeGestureRecognizerDown setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [self.inputPanel addGestureRecognizer:self.swipeGestureRecognizerDown];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    self.view.backgroundColor = [[SenderCore sharedCore].stylePalette controllerCommonBackgroundColor];
    self.mainCollectionView.backgroundColor = self.view.backgroundColor;

    [[SenderCore sharedCore].interfaceUpdater addUpdatesHandler:self];
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

- (void)setP2pChat:(Dialog *)p2pChat
{
    _p2pChat = p2pChat;
    if ([self isViewLoaded])
        [self updateView];
}

- (void)updateView
{
    [self setData];
    [self setUpRightBarButton];
    [self setMainActions];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (!hasAddedSendbar)
    {
        [self addSendBarToView];
        hasAddedSendbar = YES;
    }
    
    if ([[UIDevice currentDevice]systemVersion].floatValue < 8.0)
        [self.view layoutIfNeeded];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[self navigationController]setNavigationBarHidden:NO animated:animated];
    [self customizeNavigationBar];
}

- (void)addSendBarToView
{
    if (self.p2pChat.hasSendBar)
        self.sendBar = [[SBCoordinator alloc]initWithBarModel:self.p2pChat.sendBar];
    else
        self.sendBar = [[SBCoordinator alloc]initWithBarModel:[[CoreDataFacade sharedInstance]senderBar]];

    self.sendBar.dumbMode = YES;
    self.sendBar.delegate = self;
    self.sendBarView = self.sendBar.view;

    [self addChildViewController:self.sendBar];

    [self.inputPanel addSubview:self.sendBarView];
    [self.inputPanel pinSubview:self.sendBarView];
    [self.sendBarView layoutIfNeeded];
    [self.sendBar initSendBar];

    [self.inputView removeAllSubviews];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (([self.p2pChat.dialogSetting.blockChat boolValue] != tempBlocked) ||
        ([self.p2pChat.dialogSetting.favChat boolValue] != tempFavorite))
    {
        MWChatSettingsEditModel * editModel = [[MWChatSettingsEditModel alloc] initWithChatSettings:self.p2pChat.dialogSetting];
        editModel.isBlocked = tempBlocked;
        editModel.isFavorite = tempFavorite;
        [chatEditManager changeSettingsOfChat:self.p2pChat
                                  newSettings:editModel
                            completionHandler:nil];
    }
}

- (void)customizeNavigationBar
{
    UINavigationBar * navigationBar = self.navigationController.navigationBar;
    [[SenderCore sharedCore].stylePalette customizeNavigationBar:navigationBar];
    [[SenderCore sharedCore].stylePalette customizeNavigationItem:self.navigationItem];
    if (self.leftBarButtonImage)
    {
        UIBarButtonItem * leftBarButton = [[UIBarButtonItem alloc] initWithImage:self.leftBarButtonImage
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(closeContactPage)];
        self.navigationItem.leftBarButtonItem = leftBarButton;
    }
    else
    {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (void)closeContactPage
{
    [self.presenter closeContactPage];
}

- (void)setUpRightBarButton
{
    if (self.p2pChat.isSaved)
    {
        UIImage * starImage = [UIImage imageFromSenderFrameworkNamed:@"_star"];
        favoriteButton = [[UIBarButtonItem alloc]initWithImage:starImage
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(setFavorite)];
        [self changeFavButtonColorForState:[self.p2pChat.dialogSetting.favChat boolValue]];
    }
    else
    {
        UIBarButtonItem * addContactButton = [[UIBarButtonItem alloc]initWithImage:nil
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(addToContacts)];
        addContactButton.title = SenderFrameworkLocalizedString(@"add_to_contacts_ios", nil);
        [self.navigationItem setRightBarButtonItem:addContactButton];
    }
}

-(void)addToContacts
{
    [chatEditManager saveWithP2pChat:self.p2pChat
                   completionHandler:^(Dialog *chat, NSError *error)
                   {
                       [self updateView];
                   }];
}

-(void)changeFavButtonColorForState:(BOOL)favState
{
    CGFloat alpha = favState ? 1.0f : 0.3f;
    favoriteButton.tintColor = [[[SenderCore sharedCore].stylePalette mainAccentColor]colorWithAlphaComponent:alpha];
    self.navigationItem.rightBarButtonItem = favoriteButton;
}

-(void)setFavorite
{
    tempFavorite = !tempFavorite;
    [self changeFavButtonColorForState:tempFavorite];
}

- (void)setData
{
    tempBlocked = [self.p2pChat.dialogSetting.blockChat boolValue];
    tempFavorite = [self.p2pChat.dialogSetting.favChat boolValue];

    [ImagesManipulator setImageForImageView:userImage
                                   withChat:self.p2pChat
                         imageChangeHandler:^(BOOL isDefaultImage) {
        userImage.contentMode = isDefaultImage ? UIViewContentModeCenter : UIViewContentModeScaleAspectFit;
    }];

    userImage.layer.cornerRadius = userImage.frame.size.height/2;
    userImage.clipsToBounds = YES;
    userImage.layer.borderWidth = 1.0f;
    userImage.layer.borderColor = [[SenderCore sharedCore].stylePalette lineColor].CGColor;
    changePhotoButton.layer.cornerRadius = changePhotoButton.frame.size.width/2;
    changePhotoButton.clipsToBounds = YES;

    username.text = self.p2pChat.name;
    username.hidden = ([self.p2pChat.name length] <= 0);

    savedName = self.p2pChat.name;

    NSString * phone = [self.p2pChat getPhoneFormatted:NO];

    if (phone)
        phoneField.text = savedPhone = [phone hasPrefix:@"+"] ? phone : [@"+" stringByAppendingString:phone];
    else
        phoneField.text = savedPhone = SenderFrameworkLocalizedString(@"phone_number_unavailable_ios", nil);

    phoneNumber = phone;

    [phoneField setTextColor:[[SenderCore sharedCore].stylePalette secondaryTextColor]];

    if([self.p2pChat.chatDescription length])
        infoLabel.text = self.p2pChat.chatDescription;
    else
        infoLabel.hidden = YES;

    [infoLabel setTextColor:[[SenderCore sharedCore].stylePalette secondaryTextColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (void)callContact
{
    NSString * r = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    r = [r hasPrefix:@"+"] ? r : [@"+" stringByAppendingString:r];
    NSString * phoneUrl = [@"tel://" stringByAppendingString:r];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneUrl]];
}

- (void)startKeysSetup
{
    NSDictionary * firstRow;

    firstRow = @{@"header" : @"", @"actionModels" : @[callModel, settingModel]};
    //            secondRow = @{@"header" : @"", @"actionModels" : @[deleteModel, blockModel, complaintModel]};
//            secondRow = @{@"header" : @"", @"actionModels" : @[deleteModel]};
    mainActions = @[firstRow];

    [self.mainCollectionView reloadData];
}

- (void)expandSettingKeys
{
    NSDictionary * firstRow;
    NSDictionary * secondRow;

    if (self.p2pChat.isSaved)
    {
        firstRow = @{@"header" : @"", @"actionModels" : @[callModel, editModel, hideSettingModel]};
        secondRow = @{@"header" : @"", @"actionModels" : @[deleteModel, blockModel, complaintModel]};
        mainActions = @[firstRow,secondRow];
    }
    else
    {
        firstRow = @{@"header" : @"", @"actionModels" : @[callModel, hideSettingModel]};
        secondRow = @{@"header" : @"", @"actionModels" : @[blockModel, complaintModel]};
        mainActions = @[firstRow,secondRow];
    }
    
    [self.mainCollectionView reloadData];
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
                                                             [chatEditManager deleteWithChat:self.p2pChat
                                                                           completionHandler:^(Dialog * chat, NSError * error) {
                                                                               if (!error)
                                                                                   [self updateView];
                                                                           }];
                                                         }];

    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];

    [alertController addAction:leaveAction];
    [alertController addAction:cancelAction];
    [alertController mw_safePresentInViewController:self animated:YES completion:nil];
}

#pragma mark - NSNotification

- (NSString *)normalizePhone:(NSString *)phone
{
    NSString * normalized = [phone stringByReplacingOccurrencesOfString:@" " withString:@""];
    normalized = [normalized stringByReplacingOccurrencesOfString:@")" withString:@""];
    normalized = [normalized stringByReplacingOccurrencesOfString:@"(" withString:@""];
    normalized = [normalized stringByReplacingOccurrencesOfString:@"+" withString:@""];
    normalized = [normalized stringByReplacingOccurrencesOfString:@"-" withString:@""];

    return normalized;
}

- (NSIndexPath *)indexPathOfActionCellForModel:(MainActionModel *)model
{
    NSIndexPath * path;
    for (NSDictionary * sectionDict in mainActions) {
        NSArray * actionsArray = sectionDict[@"actionModels"];
        if ([actionsArray containsObject:model])
        {
            path = [NSIndexPath indexPathForItem:[actionsArray indexOfObject:model] inSection:[mainActions indexOfObject:sectionDict]];
        }
    }
    return path;
}

- (void)blockContact
{
    tempBlocked = !tempBlocked;
    if (tempBlocked)
        blockModel.localizedName = SenderFrameworkLocalizedString(@"act_unblock_user_ios", nil);
    else
        blockModel.localizedName = SenderFrameworkLocalizedString(@"act_block_user_ios", nil);
    
    [UIView animateWithDuration:0.1f animations:^{
        [self.mainCollectionView performBatchUpdates:^{
            [self.mainCollectionView reloadItemsAtIndexPaths:@[[self indexPathOfActionCellForModel:blockModel]]];
        } completion:nil];
    }];
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
    if (reportText.length > 0)
    {
        [[ServerFacade sharedInstance] sendComplaintAboutUserWithID:self.p2pChat.p2pContact.userID
                                                         withReason:reportText];
    }
}

- (void)handleSwipeGesturesDown
{
    id firstResponder = [[[UIApplication sharedApplication] keyWindow] performSelector:@selector(findFirstResponder)];
    [firstResponder endEditing:YES];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGFloat offset = IS_IPHONE_4_OR_LESS ? 150.0f : (IS_IPHONE_5 ? 60.0f: 0.0f);
    
    if (offset > 1.0f)
    {
        [UIView animateWithDuration:0.3f animations:^{
            self.view.transform = CGAffineTransformMakeTranslation(0, -offset);
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (IS_IPHONE_4_OR_LESS || IS_IPHONE_5)
    {
        [UIView animateWithDuration:0.3f animations:^{
            self.view.transform = CGAffineTransformIdentity;
        }];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Editing

- (void)editContact
{
    isEditing = !isEditing;
    [self customizeViewForEditingState:isEditing];
}

- (IBAction)actAccept:(id)sender
{
    NSString *newName;
    NSString *newPhone;
    NSString * normalizedPhone = [self normalizePhone:phoneField.text];
    
    if (phoneField.text && ![normalizedPhone isEqualToString:phoneNumber] && ![phoneField.text isEqualToString: SenderFrameworkLocalizedString(@"phone_number_unavailable_ios", nil)])
        newPhone = normalizedPhone;
    if (username.text && ![username.text isEqualToString:savedName])
        newName = username.text;
    
    if (!newName && !newPhone)
    {
        isEditing = NO;
        [self customizeViewForEditingState:isEditing];
    }
    else
    {
        if (![newName length])
        {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"wrong_name_format_title", nil)
                                                                            message:SenderFrameworkLocalizedString(@"wrong_name_format_message", nil)
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"ok_ios", nil)
                                                                    style:UIAlertActionStyleCancel
                                                                  handler:^(UIAlertAction * _Nonnull action) {
                                                                      [username becomeFirstResponder];
                                                                  }];
            [alert addAction:cancelAction];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        __weak __typeof(self) weakSelf = self;
        

        [chatEditManager editWithP2pChat:self.p2pChat
                                withName:newName
                                   phone:newPhone
                       completionHandler:^(Dialog * chat, NSError * error) {
                           [[CoreDataFacade sharedInstance] saveContext];
                           isEditing = NO;
                           [weakSelf customizeViewForEditingState:isEditing];
                       }];
    }
}

- (void)customizeViewForEditingState:(BOOL)editingState
{
    if (editingState)
    {
        changePhotoButton.hidden = NO;
        self.mainCollectionView.hidden = YES;
        UIBarButtonItem * cancel = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self
                                                                                action:@selector(cancelEditing)];
        self.navigationItem.leftBarButtonItem = cancel;
        
        self.scrollBottomSpace.constant = -self.inputPanel.frame.size.height;
        
        userNameBottomBorder = [[CALayer alloc]init];
        userNameBottomBorder.frame = CGRectMake(0, username.frame.size.height - 1, username.frame.size.width, 1);
        userNameBottomBorder.backgroundColor = [[SenderCore sharedCore].stylePalette.lineColor colorWithAlphaComponent:0.2f].CGColor;
        [username.layer addSublayer:userNameBottomBorder];
        
        phoneBottomBorder = [[CALayer alloc]init];
        phoneBottomBorder.frame = CGRectMake(0, phoneField.frame.size.height - 1, phoneField.frame.size.width, 1);
        phoneBottomBorder.backgroundColor = [[SenderCore sharedCore].stylePalette.lineColor colorWithAlphaComponent:0.2f].CGColor;
        [phoneField.layer addSublayer:phoneBottomBorder];
        
        username.enabled = YES;
        phoneField.enabled = NO;
    }
    else
    {
        changePhotoButton.hidden = YES;

        self.mainCollectionView.hidden = NO;

        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:nil
                                                                    action:nil];
        [self.navigationItem setBackBarButtonItem:backItem];
        self.navigationItem.leftBarButtonItem = nil;
        
        self.scrollBottomSpace.constant = 0;
        [username resignFirstResponder];
        [phoneField resignFirstResponder];
        
        [userNameBottomBorder removeFromSuperlayer];
        [phoneBottomBorder removeFromSuperlayer];
        userNameBottomBorder = nil;
        phoneBottomBorder = nil;
        
        username.enabled = NO;
        phoneField.enabled = NO;
    }
}

- (void)cancelEditing
{
    isEditing = NO;
    [self customizeViewForEditingState:isEditing];
    username.text = savedName;
    phoneField.text = savedPhone;
}

#pragma mark - SendBarDelegate

-(void)coordinator:(SBCoordinator *)coordinator didSelectItemWithActions:(NSArray *)actionsArray
{
    [self.presenter goToChatWithActions:actionsArray];
}

-(BOOL)coordinator:(SBCoordinator *)coordinator isCurrentChatEncripted:(BOOL)unnessesaryParameter
{
    return NO;
}

-(void)coordinator:(SBCoordinator *)coordinator didChangeItsHeight:(CGFloat)newHeight
{
    
}

#pragma mark - UICollectionView Delegate Methods

-(void)setMainActions
{
    acceptButton.backgroundColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    acceptButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0f];
    [acceptButton setTitle:SenderFrameworkLocalizedString(@"accept_ios", nil) forState:UIControlStateNormal];
    
    __weak __typeof(self) weakSelf = self;
    
    callModel = [[MainActionModel alloc]initWithName:SenderFrameworkLocalizedString(@"call", nil)
                                               image:[UIImage imageFromSenderFrameworkNamed:@"_call"]
                                          tapHandler:^{
        [weakSelf callContact];
    }];
    
    editModel = [[MainActionModel alloc]initWithName:SenderFrameworkLocalizedString(@"edit", nil)
                                               image:[UIImage imageFromSenderFrameworkNamed:@"_edit"]
                                          tapHandler:^{
        [weakSelf editContact];
    }];
    
    deleteModel = [[MainActionModel alloc]initWithName:SenderFrameworkLocalizedString(@"delete_ios", nil)
                                                 image:[UIImage imageFromSenderFrameworkNamed:@"_delete"]
                                            tapHandler:^{
        [weakSelf deleteContact];
    }];

    BOOL isBlockedChat = [self.p2pChat.dialogSetting.blockChat boolValue];
    NSString * blockTitleKey = isBlockedChat ? @"act_unblock_user_ios" : @"act_block_user_ios";
    
    blockModel = [[MainActionModel alloc]initWithName:SenderFrameworkLocalizedString(blockTitleKey, nil)
                                                image:[UIImage imageFromSenderFrameworkNamed:@"_block"]
                                           tapHandler:^{
        [weakSelf blockContact];
    }];
    
    complaintModel = [[MainActionModel alloc]initWithName:SenderFrameworkLocalizedString(@"complain_ios", nil)
                                                    image:[UIImage imageFromSenderFrameworkNamed:@"_complaint"]
                                               tapHandler:^{
        [weakSelf complain];
    }];
    
    settingModel = [[MainActionModel alloc]initWithName:SenderFrameworkLocalizedString(@"settings", nil)
                                                  image:[UIImage imageFromSenderFrameworkNamed:@"_settings"]
                                             tapHandler:^{
        [weakSelf expandSettingKeys];
    }];
    
    hideSettingModel = [[MainActionModel alloc]initWithName:SenderFrameworkLocalizedString(@"cancel", nil)
                                                      image:[UIImage imageFromSenderFrameworkNamed:@"_cancel"]
                                                 tapHandler:^{
        [weakSelf startKeysSetup];
    }];
    
    [self startKeysSetup];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [mainActions count];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray * actionsArray = mainActions[section][@"actionModels"];
    return [actionsArray count];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MainActionModel * action = [self modelForIndexPath:indexPath];
    if (action.tapHandler)
        action.tapHandler();
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MainButtonCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MainButtonCell"
                                                                      forIndexPath:indexPath];
    [cell customizeWithModel:[self modelForIndexPath:indexPath]];
    [cell.mainImage setTintColor:[[SenderCore sharedCore].stylePalette lineColor]];
    [cell setTintColor:[[SenderCore sharedCore].stylePalette lineColor]];
    [cell.title setTextColor:[[SenderCore sharedCore].stylePalette lineColor]];
    return cell;
}

-(MainActionModel *)modelForIndexPath:(NSIndexPath *)indexPath
{
    MainActionModel * resultModel;
    NSArray * actionsArray = mainActions[indexPath.section][@"actionModels"];
    if ([actionsArray[indexPath.row] isKindOfClass:[MainActionModel class]])
        resultModel = (MainActionModel *)actionsArray[indexPath.row];
    return resultModel;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self sizeForItem];
}

-(CGSize)sizeForItem
{
    DeviceType device;
    if (IS_IPHONE_4_OR_LESS)
        device = DeviceTypeIphone4;
    else if (IS_IPHONE_5)
        device = DeviceTypeIphone5;
    else if (IS_IPHONE_6)
        device = DeviceTypeIphone6;
    else if (IS_IPHONE_6P)
        //Temporary size. Use templateSizeForDeviceType when there are more than 2 rows of actions
        return CGSizeMake(120.0f, 130.0f);
//            device = DeviceTypeIphone6p;
    else if (IS_IPAD)
        return CGSizeMake(120.0f, 130.0f);

    return [MainButtonCell templateSizeForDeviceType:device];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    NSInteger viewsPerRow = [self.mainCollectionView numberOfItemsInSection:section];
    CGFloat result = (self.mainCollectionView.frame.size.width - viewsPerRow * [self sizeForItem].width) / (viewsPerRow + 1);
    /*
     * Subtracting one, because collectionViews's items may be displayed wrong
     * if sum of their widths plus sum of all spacings is equal to collectionView's width
     */
    return result - 1.0f;
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    NSInteger viewsPerRow = [self.mainCollectionView numberOfItemsInSection:section];
    CGFloat offsetX = (self.mainCollectionView.frame.size.width - viewsPerRow * [self sizeForItem].width) / (viewsPerRow + 1);
    
    NSUInteger rowsPerPage = (NSUInteger)(self.mainCollectionView.frame.size.height / [self sizeForItem].height);
    rowsPerPage = (rowsPerPage <= 3) ? rowsPerPage : 3;

    CGFloat offsetY = (self.mainCollectionView.frame.size.height - rowsPerPage * [self sizeForItem].height) / (rowsPerPage + 1);

    UIEdgeInsets result = UIEdgeInsetsMake(offsetY, offsetX, 0.0f, offsetX);

    return result;
}

- (void)collectionView:(UICollectionView *)colView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell * cell = [colView cellForItemAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
}

- (void)collectionView:(UICollectionView *)colView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor clearColor];
}

- (void)updateWithViewModel:(Dialog *)viewModel
{
    self.p2pChat = viewModel;
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

@interface ContactPageViewController (UpdatesHandler)
@end

@implementation ContactPageViewController (UpdatesHandler)

-(void)handleChatsChange:(NSArray<Dialog *> *)chats
{
    for (Dialog * chat in chats)
    {
        if ([chat.chatID isEqualToString:self.p2pChat.chatID])
            self.p2pChat = chat;
    }
}
@end
