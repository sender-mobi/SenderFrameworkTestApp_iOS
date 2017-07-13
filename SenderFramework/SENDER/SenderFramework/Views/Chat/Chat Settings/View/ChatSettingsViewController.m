//
//  ChatSettingsViewController.m
//  SENDER
//
//  Created by Roman Serga on 22/7/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "ChatSettingsViewController.h"
#import "CoreDataFacade.h"
#import "ContactPageViewController.h"
#import "PBConsoleConstants.h"
#import "ParamsFacade.h"
#import "DialogMembersViewController.h"
#import "ServerFacade.h"
#import "ImagesManipulator.h"
#import "DialogSetting.h"
#import "Dialog.h"
#import "UIAlertView+CompletionHandler.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "Dialog+HumanReadableSettings.h"

@interface ChatSettingsViewController ()

@property (nonatomic, weak) IBOutlet UIButton * chatImageButton;
@property (nonatomic, weak) IBOutlet UILabel * onlineStatusLabel;
@property (nonatomic, weak) IBOutlet UIButton * leaveChatButton;
@property (nonatomic, weak) IBOutlet UIButton * editChatButton;

@property (nonatomic, weak) IBOutlet UILabel * membersTitleLabel;

@property (nonatomic, weak) IBOutlet UILabel * addParticipantTitle;

@property (nonatomic, weak) IBOutlet UILabel * encryptionTitleLabel;
@property (nonatomic, strong) UISwitch * encryptionSwitch;

@property (nonatomic, weak) IBOutlet UILabel * favoriteTitleLabel;
@property (nonatomic, strong) UISwitch * favoriteSwitch;

@property (nonatomic, weak) IBOutlet UILabel * blockTitleLabel;
@property (nonatomic, strong) UISwitch * blockSwitch;

@property (nonatomic, weak) IBOutlet UILabel * soundSchemeTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel * soundSchemeValueLabel;

@property (nonatomic, weak) IBOutlet UILabel * soundTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel * soundValueLabel;

@property (nonatomic, weak) IBOutlet UILabel * notificationsTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel * notificationsValueLabel;

@property (nonatomic, weak) IBOutlet UILabel * smartNotificationsTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel * smartNotificationsValueLabel;

@property (nonatomic, weak) IBOutlet UILabel * hideTextTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel * hideTextValueLabel;

@property (nonatomic, weak) IBOutlet UILabel * counterTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel * counterValueLabel;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint * onlineLabelHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint * onlineLabelBottom;

@property (nonatomic, weak) IBOutlet UITableViewCell * headerCell;
@property (nonatomic, weak) IBOutlet UITableViewCell * membersCell;
@property (nonatomic, weak) IBOutlet UITableViewCell * addMemberCell;
@property (nonatomic, weak) IBOutlet UITableViewCell * encryptionCell;
@property (nonatomic, weak) IBOutlet UITableViewCell * favoriteCell;
@property (nonatomic, weak) IBOutlet UITableViewCell * blockCell;
@property (nonatomic, weak) IBOutlet UITableViewCell * soundSchemeCell;
@property (nonatomic, weak) IBOutlet UITableViewCell * soundCell;
@property (nonatomic, weak) IBOutlet UITableViewCell * notificationsCell;
@property (nonatomic, weak) IBOutlet UITableViewCell * smartNotificationsCell;
@property (nonatomic, weak) IBOutlet UITableViewCell * hideTextCell;
@property (nonatomic, weak) IBOutlet UITableViewCell * counterCell;

@property (nonatomic, weak) UITableViewCell * lastSelectedCell;
@property (nonatomic, strong) DialogMembersViewController * membersController;

@end

@implementation ChatSettingsViewController

@synthesize presenter = _presenter;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.presenter viewWasLoaded];

    [self initSwitches];

    [self customizeViewForDialog:self.dialog];
    [self localize];

    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    
    self.membersCell.textLabel.textColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    self.addMemberCell.textLabel.textColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    
    [self.leaveChatButton setImage:[UIImage imageFromSenderFrameworkNamed:@"_exit"] forState:UIControlStateNormal];
    self.leaveChatButton.tintColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    
    [self.editChatButton setImage:[UIImage imageFromSenderFrameworkNamed:@"_edit"] forState:UIControlStateNormal];
    self.editChatButton.tintColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    
    self.chatImageButton.contentMode = UIViewContentModeScaleAspectFit;
    self.chatImageButton.backgroundColor = [UIColor whiteColor];
    self.chatImageButton.tintColor = [UIColor clearColor];
    self.chatImageButton.clipsToBounds = YES;

    self.onlineStatusLabel.textColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    
    [self cells:@[self.soundSchemeCell, self.smartNotificationsCell] setHidden:YES];

    [self addBlurredBackground];
}

- (void)initSwitches
{
    self.encryptionSwitch = [[UISwitch alloc]init];
    self.encryptionSwitch.onTintColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
    [self.encryptionSwitch addTarget:self
                              action:@selector(encryptionSwitchValueChanged:)
                    forControlEvents:UIControlEventValueChanged];
    
    self.favoriteSwitch = [[UISwitch alloc]init];
    self.favoriteSwitch.onTintColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
    [self.favoriteSwitch addTarget:self
                                action:@selector(favoriteSwitchValueChanged:)
                      forControlEvents:UIControlEventValueChanged];

    self.blockSwitch = [[UISwitch alloc]init];
    self.blockSwitch.onTintColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
    [self.blockSwitch addTarget:self
                         action:@selector(blockSwitchValueChanged:)
               forControlEvents:UIControlEventValueChanged];
}

- (void)localize
{
    self.favoriteCell.textLabel.text = SenderFrameworkLocalizedString(@"chat_settings_favorite_chat", nil);
    self.membersCell.textLabel.text = SenderFrameworkLocalizedString(@"chat_settings_members", nil);
    self.encryptionCell.textLabel.text = SenderFrameworkLocalizedString(@"chat_settings_encryption", nil);
    self.addMemberCell.textLabel.text = SenderFrameworkLocalizedString(@"chat_settings_add_participant", nil);
    self.blockCell.textLabel.text = SenderFrameworkLocalizedString(@"chat_settings_block", nil);
    self.soundSchemeCell.textLabel.text = SenderFrameworkLocalizedString(@"chat_settings_sound_scheme", nil);
    self.soundCell.textLabel.text = SenderFrameworkLocalizedString(@"chat_settings_sound", nil);
    self.notificationsCell.textLabel.text = SenderFrameworkLocalizedString(@"chat_settings_notifications", nil);
    self.smartNotificationsCell.textLabel.text = SenderFrameworkLocalizedString(@"chat_settings_smart_notifications", nil);
    self.hideTextCell.textLabel.text = SenderFrameworkLocalizedString(@"chat_settings_hide_text", nil);
    self.counterCell.textLabel.text = SenderFrameworkLocalizedString(@"chat_settings_counter", nil);

    for (UILabel * title in @[self.encryptionCell.textLabel,
                              self.favoriteCell.textLabel,
                              self.membersCell.textLabel,
                              self.blockCell.textLabel,
                              self.soundSchemeCell.textLabel,
                              self.soundCell.textLabel,
                              self.notificationsCell.textLabel,
                              self.smartNotificationsCell.textLabel,
                              self.hideTextCell.textLabel,
                              self.counterCell.textLabel])
    {
        title.textColor = [SenderCore sharedCore].stylePalette.mainTextColor;
    }
}

- (void)updateWithViewModel:(Dialog *)viewModel
{
    self.dialog = viewModel;
}

- (void)customizeViewForDialog:(Dialog *)dialog
{
    [ImagesManipulator setImageForButton:self.chatImageButton
                                forState:UIControlStateNormal
                                withChat:dialog
                      imageChangeHandler:nil];
    self.chatImageButton.userInteractionEnabled = dialog.isP2P;

    if (dialog.isP2P)
    {
        Contact * interlocutor = dialog.p2pContact;
        BOOL onlineStatus = [interlocutor.isOnline boolValue] || [interlocutor.isCompany boolValue];
        [self setOnlineStatus:onlineStatus];
        [self cell:self.encryptionCell setHidden:[interlocutor.isCompany boolValue]];
    }

    self.favoriteSwitch.on = [self.dialog.chatSettings.favChat boolValue];
    self.encryptionSwitch.on = [self.dialog isEncrypted];
    self.blockSwitch.on = [self.dialog.chatSettings.blockChat boolValue];

    NSArray * settingCells = @[
            self.soundSchemeCell,
            self.soundCell,
            self.notificationsCell,
            self.smartNotificationsCell,
            self.hideTextCell,
            self.counterCell,
    ];

    for (UITableViewCell * cell in settingCells)
        [self addDetailToCell:cell];
    
    self.editChatButton.hidden = dialog.isP2P;
    self.leaveChatButton.hidden = dialog.isP2P;
    
    NSArray * groupChatCells = @[self.membersCell];
    NSArray * p2pChatCells = @[];
    
    self.onlineLabelHeight.constant = dialog.isP2P ? 21.0f : 0.0f;
    self.onlineLabelBottom.constant = dialog.isP2P ? 8.0f : 0.0f;
    [self cells:@[self.headerCell] setHeight:dialog.isP2P ? 174.0f : 145.0f];
    [self cells:groupChatCells setHidden:dialog.isP2P];
    [self cells:p2pChatCells setHidden:!dialog.isP2P];
    [self.tableView reloadData];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self customizeViewForDialog:self.dialog];
    [[self navigationController]setNavigationBarHidden:NO animated:YES];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.chatImageButton.layer.cornerRadius = self.chatImageButton.frame.size.height / 2;

    UIEdgeInsets insets = UIEdgeInsetsMake(self.topLayoutGuide.length,
            0.0,
            0.0,
            0.0);
    self.tableView.scrollIndicatorInsets = insets;
    self.tableView.contentInset = insets;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)setOnlineStatus:(BOOL)isOnline
{
    self.onlineStatusLabel.text = isOnline ? SenderFrameworkLocalizedString(@"online", nil) : SenderFrameworkLocalizedString(@"offline", nil);
    self.onlineStatusLabel.alpha = isOnline ? 1.0f : 0.5f;
}

-(void)addBlurredBackground
{
    UIColor * backgroundColor = [UIColor whiteColor];
    if ([SenderCore sharedCore].stylePalette.chatBackgroundImageType == ChatBackgroundImageTypeDarkBlur)
        backgroundColor = [UIColor blackColor];

    if (([[UIDevice currentDevice]systemVersion].floatValue >= 8.0) && !UIAccessibilityIsReduceTransparencyEnabled())
    {
        UIView * background = [[UIView alloc]init];

        self.tableView.backgroundColor = [UIColor clearColor];
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = self.view.frame;
        [background insertSubview:blurEffectView atIndex:0];
        
        UIView * blueView = [[UIView alloc]initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, self.view.bounds.size.height)];
        blueView.backgroundColor = backgroundColor;
        blueView.alpha = 0.6f;
        [background insertSubview:blueView atIndex:0];
        
        self.tableView.backgroundView = background;
    }
    else
    {
        self.view.backgroundColor = [backgroundColor colorWithAlphaComponent:0.8f];
    }
}

-(void)setDialog:(Dialog *)dialog
{
    _dialog = dialog;
    if ([self isViewLoaded]) [self customizeViewForDialog:dialog];
    [self updateMembersController];
}

-(BOOL)isCellWithSwitch:(UITableViewCell *)cell
{
    return (cell == self.encryptionCell || cell == self.favoriteCell || cell == self.blockCell);
}

-(BOOL)isCellWithDetail:(UITableViewCell *)cell
{
    return (cell == self.soundSchemeCell ||
            cell == self.soundCell ||
            cell == self.notificationsCell ||
            cell == self.smartNotificationsCell ||
            cell == self.hideTextCell ||
            cell == self.counterCell);
}

-(BOOL)isCellSelectable:(UITableViewCell *)cell
{
    return (cell == self.membersCell || cell == self.addMemberCell);
}

-(void)addSwitchToCell:(UITableViewCell *)cell
{
    if (cell == self.encryptionCell)
    {
        if ([self.dialog chatType] != ChatTypeP2P) {
            cell.accessoryView = self.encryptionSwitch;
        }
        else {
            self.encryptionCell.alpha = 0.3;
            self.encryptionCell.userInteractionEnabled = NO;
        }
    }
    else if (cell == self.favoriteCell)
        cell.accessoryView = self.favoriteSwitch;
    else if (cell == self.blockCell)
        cell.accessoryView = self.blockSwitch;
}

-(void)addDetailToCell:(UITableViewCell *)cell
{
    UILabel * detailLabel = cell.detailTextLabel;
    detailLabel.text = [self detailForCell:cell];
}

- (NSString *)detailForCell:(UITableViewCell *)cell
{
    NSString * result;

    DialogSetting * chatSettings = self.dialog.chatSettings;

    if (cell == self.soundSchemeCell)
        result = humanReadableSoundSchemeState(chatSettings.chatSoundScheme);
    else if (cell == self.soundCell)
        result = humanReadableStateForType(chatSettings.muteChatNotification);
    else if (cell == self.notificationsCell)
        result = humanReadableStateForType(chatSettings.hidePushNotification);
    else if (cell == self.smartNotificationsCell)
        result = humanReadableStateForType(chatSettings.smartPushNotification);
    else if (cell == self.hideTextCell)
        result = humanReadableStateForType(chatSettings.hideTextNotification);
    else if (cell == self.counterCell)
        result = humanReadableStateForType(chatSettings.hideCounterNotification);

    return result;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    if ([self isCellWithSwitch:cell])
        [self addSwitchToCell:cell];
    else if ([self isCellWithDetail:cell])
        [self addDetailToCell:cell];
}

-(NSArray<NSString *> *)valuesToSelectForCell:(UITableViewCell *)cell
{
    NSArray * values = nil;
    if ([self isCellWithDetail:cell])
    {
        if (cell == self.soundSchemeCell)
            [self.dialog allSoundSchemeValues];
        else
            [self.dialog allNotificationSelectorValues];
    }
    return values;
}

-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    return ([self isCellSelectable:cell] || [self isCellWithDetail:cell]);
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    BOOL deselectAnimated = ([self isCellSelectable:selectedCell] || [self isCellWithDetail:selectedCell]);
    [self.tableView deselectRowAtIndexPath:indexPath animated:deselectAnimated];

    if ([self isCellSelectable:selectedCell])
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        if (selectedCell == self.membersCell)
            [self.presenter showChatMembers];
        else if (selectedCell == self.addMemberCell)
            [self.presenter addParticipants];
    }
    else if ([self isCellWithDetail:selectedCell])
    {
        self.lastSelectedCell = selectedCell;
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

        ValueSelectTableViewController * selectController = [[ValueSelectTableViewController alloc]initWithStyle:UITableViewStyleGrouped];
        BOOL hasSelectedSoundSchemeCell = selectedCell == self.soundSchemeCell;
        selectController.title = selectedCell.textLabel.text;
        selectController.values = (hasSelectedSoundSchemeCell ? [self.dialog allSoundSchemeValues] : [self.dialog allNotificationSelectorValues]);
        NSString * currentValue = [self detailForCell:selectedCell];
        if (currentValue)
            selectController.indexOfSelectedValue = [selectController.values indexOfObject:currentValue];
        selectController.delegate = self;
        
        [self.navigationController pushViewController:selectController animated:YES];
    }
    else
    {
    }
}

- (void)updateMembersController
{
    self.membersController.chat = self.dialog;
}

-(void)valueSelectTableViewController:(ValueSelectTableViewController *)controller didFinishWithValue:(NSString *)value
{
    if (self.lastSelectedCell == self.soundSchemeCell)
    {
        ChatSettingsSoundScheme soundScheme = convertHumanReadableSoundSchemeToRaw(value);
        [self.presenter changeSoundSchemeTo:soundScheme];
    }
    else
    {
        ChatSettingsNotificationType ntfType = convertHumanReadableNotificationSettingToRaw(value);

        if (self.lastSelectedCell == self.soundCell)
            [self.presenter changeMuteChatStateTo:ntfType];
        else if (self.lastSelectedCell == self.notificationsCell)
            [self.presenter changeHidePushStateTo:ntfType];
        else if (self.lastSelectedCell == self.smartNotificationsCell)
            [self.presenter changeSmartPushStateTo:ntfType];
        else if (self.lastSelectedCell == self.hideTextCell)
            [self.presenter changeHideTextStateTo:ntfType];
        else if (self.lastSelectedCell == self.counterCell)
            [self.presenter changeHideCounterStateTo:ntfType];
    }
}

#pragma mark - Actions

-(void)encryptionSwitchValueChanged:(UISwitch *)sender
{
    if (![[SenderCore sharedCore] isBitcoinEnabled])
        [self showEncryptionUnavailableInRestrictedAlert];
    else
        [self.presenter changeEncryptionStateTo:sender.on];
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

-(void)favoriteSwitchValueChanged:(UISwitch *)sender
{
    [self.presenter changeFavoriteStateTo:sender.on];
}

-(void)blockSwitchValueChanged:(UISwitch *)sender
{
    [self.presenter changeBlockStateTo:sender.on];
}

-(IBAction)leaveChat:(id)sender
{
    NSString * chatName = self.dialog.name;
    NSString * title = [NSString stringWithFormat:SenderFrameworkLocalizedString(@"leave_chat_specific_ios", nil), chatName];
    NSString * message = [NSString stringWithFormat:SenderFrameworkLocalizedString(@"leave_chat_specific_message_ios", nil), chatName];
    NSString * destructiveButtonTitle = SenderFrameworkLocalizedString(@"leave_chat_ios", nil);

    UIAlertController * alert = [UIAlertController alertControllerWithTitle:title
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction * leaveAction = [UIAlertAction actionWithTitle:destructiveButtonTitle
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
                                                             [self.presenter leaveChat];
                                                         }];

    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];

    [alert addAction:leaveAction];
    [alert addAction:cancelAction];

    [alert mw_safePresentInViewController:self animated:YES completion:nil];
}

-(IBAction)editChat:(id)sender
{
    [self.presenter editChat];
}

-(IBAction)goToProfile:(id)sender
{
    [self.presenter showContactPage];
}

@end
