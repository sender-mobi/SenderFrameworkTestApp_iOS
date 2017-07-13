#import "UIView+subviews.h"

//
//  CellProtoType.m
//  SENDER
//
//  Created by Eugene on 2/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "CellProtoType.h"
#import "Contact.h"
#import "CoreDataFacade.h"
#import "PBConsoleConstants.h"
#import "ParamsFacade.h"
#import "TextCellView.h"
#import "ImageCellView.h"
#import "VideoCellView.h"
#import "AudioCellView.h"
#import "MyLocationCellView.h"
#import "StickerMessageView.h"
#import "SenderNotifications.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "FileView.h"
#import "EncryptedTextCellView.h"
#import "Owner.h"
#import "ImagesManipulator.h"
#import "Dialog.h"

@interface CellProtoType ()
{
    __weak IBOutlet NSLayoutConstraint * timeLabelBottomSpace;
    __weak IBOutlet NSLayoutConstraint * userNameLabelHeight;
    __weak IBOutlet NSLayoutConstraint * userNameLabelWidth;
    __weak IBOutlet NSLayoutConstraint * delivImageWidth;

    UIView * contentView;
    BOOL statusHidden;
    BOOL nameHidden;
    CGFloat maxWidth;
}

@end

@implementation CellProtoType

- (instancetype)initWithModel:(Message *)model andWidth:(CGFloat)width
{
    self = [super init];
    if (self)
    {
        NSString * nibName = model.owner ? @"OwnerView" : @"GuestView";
        NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
        self = [[NSBundle.senderFrameworkResourcesBundle loadNibNamed:nibName owner:nil options:nil] objectAtIndex:0];
        self.backgroundColor = [UIColor clearColor];
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, SCREEN_WIDTH, self.frame.size.height);
        [self layoutIfNeeded];

        viewModel = model;

        NSDate * currentDate = [NSDate date];
        if ([currentDate timeIntervalSinceDate:viewModel.created] <= 30 * 60)
        {
            CGRect rect = mainContainer.frame;
            CGRect targetRectangle = CGRectMake(rect.size.width/2, 0, rect.size.width, rect.size.height);
            [[UIMenuController sharedMenuController] setTargetRect:targetRectangle inView:self];

            NSMutableArray * itemsArray = [NSMutableArray new];
            UIMenuItem * menuItemEdit = [[UIMenuItem alloc] initWithTitle:SenderFrameworkLocalizedString(@"edit", nil) action:@selector(editAction:)];
            UIMenuItem * menuItemDelete = [[UIMenuItem alloc] initWithTitle:SenderFrameworkLocalizedString(@"delete_ios", nil) action:@selector(deleteAction:)];
            [itemsArray addObject:menuItemEdit];
            [itemsArray addObject:menuItemDelete];

            [[UIMenuController sharedMenuController] setMenuItems:itemsArray];
        }
    }
    return self;
}

- (BOOL)canBecomeFirstResponder
{
    return NO;
}

- (BOOL)canPerformAction:(SEL)action
              withSender:(id)sender
{
    BOOL result = NO;

    if (!viewModel.deletedMessage && viewModel.owner && [viewModel.type isEqualToString:@"TEXT"])
    {
        NSDate * currentDate = [NSDate date];
        BOOL editingAllowed = ([currentDate timeIntervalSinceDate:viewModel.created] <= 30 * 60);
        if (action == @selector(copy:))
            result = YES;
        else
            result = ((@selector(editAction:) == action || @selector(deleteAction:) == action) && editingAllowed);
    }
    return result;
}

- (void)copy:(id)sender
{
    LLog(@"Copy");
    [UIPasteboard generalPasteboard].string = viewModel.textMessage;
}

- (void)editAction:(id)sender
{
    LLog(@"Edit Action");
    
    [self.delegate cellCallForModel:viewModel doAction:EDIT];
    [contentView removeFromSuperview];
    contentView = nil;
    //     self.viewModel.textMessage = SenderFrameworkLocalizedString(@"Message deleted",nil);
    [self configureCell:viewModel showUserImage:nameHidden];
}

- (void)deleteAction:(id)sender {
    LLog(@"Delete Action");
    
    [self.delegate cellCallForModel:viewModel doAction:DELETE];
    
    [contentView removeFromSuperview];
    contentView = nil;
//     self.viewModel.textMessage = SenderFrameworkLocalizedString(@"Message deleted",nil);
//    
    CGRect rect = mainContainer.frame;
    rect.size.width = maxWidth;
    mainContainer.frame = rect;
    
    [self configureCell:viewModel showUserImage:nameHidden];
    [self fixNameLabelHeight];
}

- (void)clearContentView
{
    [contentView removeFromSuperview];
    contentView = nil;
}

- (void)resendAction:(id)sender {
    LLog(@"Resend Action");
}

- (void)configureCell:(Message *)model showUserImage:(BOOL)showImage
{
    if (viewModel.owner)
        [self loadOwnerModel];
    else
        [self loadGuestModel];

    cellTimeLabel.textColor = [SenderCore sharedCore].stylePalette.secondaryTextColor;
    cellTimeLabel.text = [[ParamsFacade sharedInstance] formatedStringFromNSDate:viewModel.created];
    
    UIView * content;

    if ([viewModel.type isEqualToString:@"TEXT"]) {
        content = [viewModel.encrypted boolValue] ? [[EncryptedTextCellView alloc] init] : [[TextCellView alloc] init];
    }
    else if ([viewModel.type isEqualToString:@"IMAGE"]) {
        content = [[ImageCellView alloc] init];
    }
    else if ([viewModel.type isEqualToString:@"FILE"]) {
        content = [[FileView alloc] init];
        [(FileView *) content setFileViewDelegate:self.fileViewDelegate];
    }
    else if ([viewModel.type isEqualToString:@"VIDEO"]) {
        content = [[VideoCellView alloc] init];
    }
    else if ([viewModel.type isEqualToString:@"AUDIO"]) {
        content = [[AudioCellView alloc] init];
    }
    else if ([viewModel.type isEqualToString:@"SELFLOCATION"]) {
        content = [[MyLocationCellView alloc] init];
    }
    else if ([viewModel.type isEqualToString:@"STICKER"] || [viewModel.type isEqualToString:@"VIBRO"]) {
        content = [[StickerMessageView alloc] init];
        mainContainer.backgroundColor = [UIColor clearColor];
        mainContainer.layer.borderColor = [UIColor clearColor].CGColor;
    }
    
    CGRect rect = mainContainer.frame;
    maxWidth = rect.size.width;

    CGSize timeLabelSize = CGSizeMake(cellTimeLabel.frame.size.width + delivImageWidth.constant, cellTimeLabel.frame.size.height);
    [(TextCellView *)content initWithModel:viewModel width:maxWidth timeLabelSize:timeLabelSize];
    
    nameHidden = !showImage;
    
    if (nameHidden)
        [self hideCellImage];
    
    [self addContentView:content];
}

- (void)addContentView:(UIView *)content
{
    contentView = content;
    
    [mainContainer addSubview:contentView];

    [self customizeNameLabel];
    
    [self fixNameLabelHeight];
    
    if ([viewModel.type isEqualToString:@"TEXT"] || [viewModel.type isEqualToString:@"AUDIO"])
        timeLabelBottomSpace.constant = 8.0f;
    else
        timeLabelBottomSpace.constant = 6.0f;
    
    [self layoutIfNeeded];
}

- (void)fixNameLabelHeight
{
    CGFloat contentTop = userNameLabelHeight.constant == 0.0f ? 0.0f : contentView.frame.origin.y + cellUserNameLabel.frame.origin.y + userNameLabelHeight.constant;
    CGFloat contentWidth = contentView.frame.size.width >= userNameLabelWidth.constant ? contentView.frame.size.width : userNameLabelWidth.constant;
    
    contentView.frame = CGRectMake(contentView.frame.origin.x, contentTop, contentWidth, contentView.frame.size.height);
    [self fixCellSize];
}

- (void)fixCellSize
{
    CGRect rect;
    rect.size.height = CGRectGetMaxY(contentView.frame);
    rect.size.width = contentView.frame.size.width;
    
    CGFloat newWidth = rect.size.width < maxWidth ? rect.size.width + 85.0f : maxWidth + 85.0f;
    CGFloat newX = viewModel.owner ? SCREEN_WIDTH - newWidth : 0.0f;
    CGFloat deltaY = 5.0f;
    CGFloat minHeight = 40.0f;
    CGFloat newHeight = rect.size.height + deltaY >= minHeight ? rect.size.height + deltaY : minHeight;
    
    self.frame = CGRectMake(newX, self.frame.origin.y, newWidth, newHeight);
    
    [self checkDelivery];
    [self layoutIfNeeded];
    
    CGSize timeLabelSize = CGSizeMake(cellTimeLabel.frame.size.width + delivImageWidth.constant, cellTimeLabel.frame.size.height);
    [(TextCellView *)contentView fixWidthForTimeLabelSize:timeLabelSize maxWidth:maxWidth];
}

- (void)customizeNameLabel
{
    if (!nameHidden)
    {
        if (viewModel.owner || viewModel.dialog.isP2P)
        {
            userNameLabelHeight.constant =  0.0f;
            userNameLabelWidth.constant = 0.0f;
        }
        else
        {
            CGSize nessesarySize = [cellUserNameLabel sizeThatFits:mainContainer.frame.size];
            userNameLabelWidth.constant = (nessesarySize.width + 18.0f) <= mainContainer.frame.size.width ? (nessesarySize.width + 18.0f) : mainContainer.frame.size.width;
            userNameLabelHeight.constant = 18.0f;
            cellUserNameLabel.layer.cornerRadius = userNameLabelHeight.constant / 2;
            cellUserNameLabel.clipsToBounds = YES;
            cellUserNameLabel.backgroundColor = [UIColor clearColor];
        }
    }
}

- (void)finishImage
{
    cellUserImage.backgroundColor = [UIColor whiteColor];
    [PBConsoleConstants imageSetRounds:cellUserImage];
}

- (void)loadOwnerModel
{

    mainContainer.backgroundColor =  [viewModel.encrypted boolValue] ? [[SenderCore sharedCore].stylePalette encryptedOwnerMessageBackgroundColor] : [[SenderCore sharedCore].stylePalette myMessageBackgroundColor];
    [self makeViewRound];
    Owner * owner = [[CoreDataFacade sharedInstance] getOwner];
    [ImagesManipulator setImageForImageView:cellUserImage withOwner:owner imageChangeHandler:^(BOOL isDefaultImage){
        [self finishImage];
    }];
    cellUserNameLabel.text = SenderFrameworkLocalizedString(@"you",nil);
}

- (void)loadGuestModel
{
    mainContainer.backgroundColor = [viewModel.encrypted boolValue] ? [[SenderCore sharedCore].stylePalette encryptedMessageBackgroundColor] : [[SenderCore sharedCore].stylePalette foreignMessageBackgroundColor];
    [self makeViewRound];

    Contact * contactModel = [[CoreDataFacade sharedInstance] selectContactById:viewModel.fromId];
    [self finishImage];
    [ImagesManipulator setImageForImageView:cellUserImage withContact:contactModel imageChangeHandler:nil];
    cellUserNameLabel.textColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    cellUserNameLabel.text = contactModel.name;
}

- (void)makeViewRound
{
    if (![viewModel.type isEqualToString:@"STICKER"] && ![viewModel.type isEqualToString:@"VIBRO"])
    {
        mainContainer.layer.cornerRadius = 17.5f;
        mainContainer.clipsToBounds = YES;
    }
}

- (void)hideCellImage
{
    if (!cellUserImage.hidden)
    {
        [cellUserImage setHidden:YES];
        userNameLabelHeight.constant = 0.0f;
        userNameLabelWidth.constant = 0.0f;
        [self fixNameLabelHeight];
    }
}

- (void)showCellImage
{
    if (cellUserImage.hidden)
    {
        [cellUserImage setHidden:NO];
        [self customizeNameLabel];
    }
}

- (void)hideStatus
{
    if (viewModel.owner)
    {
        statusHidden = YES;
        delivImageWidth.constant = 5.0f;
        [self fixStatus];
    }
}

- (void)showStatus
{
    statusHidden = NO;
    delivImageWidth.constant = 35.0f;
    [self fixStatus];
}

- (void)fixStatus
{
    [self layoutIfNeeded];
    if ([contentView respondsToSelector:@selector(fixWidthForTimeLabelSize:maxWidth:)])
    {
        CGSize timeLabelSize = CGSizeMake(cellTimeLabel.frame.size.width + delivImageWidth.constant, cellTimeLabel.frame.size.height);
        [(TextCellView *)contentView fixWidthForTimeLabelSize:timeLabelSize maxWidth:maxWidth];
        [self fixCellSize];
    }
    cellDelivIndicator.hidden = statusHidden;
}

- (BOOL)isStatusHidden
{
    return !statusHidden;
}

- (void)checkDelivery
{
    if (viewModel.deletedMessage) {
        nameHidden = YES;
        [self hideCellImage];
        self.alpha = 0.8;
        mainContainer.backgroundColor = [UIColor clearColor];
        cellTimeLabel.hidden = YES;
        statusHidden = YES;
        mainContainer.layer.borderColor = [UIColor clearColor].CGColor;
    
        if (viewModel.owner) {
            self.frame = CGRectMake(70, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
        }
        
        return;
    }
    
    NSString * imageName = @"_sent";
    self.alpha = 1;
    
    if ([viewModel.dialog lastMessageStatus] == MessageStatusSent) {
        self.alpha = 1;
    }
    else if ([viewModel.dialog lastMessageStatus] == MessageStatusDelivered) {
        imageName = @"_delivered";
//        self.alpha = 1;
    }
    else if ([viewModel.dialog lastMessageStatus] == MessageStatusRead) {
        imageName = @"_seen";
//        self.alpha = 1;
    }
    else {
//        self.alpha = 0.5;
    }
    
    cellTimeLabel.text = [[ParamsFacade sharedInstance] formatedStringFromNSDate:viewModel.created];
    if (imageName)
        cellDelivIndicator.image = [[UIImage imageFromSenderFrameworkNamed:imageName]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cellDelivIndicator.tintColor = [[SenderCore sharedCore].stylePalette secondaryTextColor];
}

@end