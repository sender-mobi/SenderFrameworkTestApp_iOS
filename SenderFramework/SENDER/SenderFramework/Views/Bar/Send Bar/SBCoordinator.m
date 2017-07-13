//
//  SBCoordinator.m
//  SENDER
//
//  Created by Roman Serga on 4/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "SBCoordinator.h"
#import "ParamsFacade.h"
#import "SBItemView.h"
#import "UIView+subviews.h"
#import "PBConsoleConstants.h"
#import <SenderFramework/SenderFramework-Swift.h>

#define defaultHeight 53.0f

#define firstLevelViewsPerRow (IS_IPAD || IS_IPHONE_6P ? 4 : 3)

@interface SBCoordinator ()
{
    CGFloat inputViewHeigh;
    CGFloat heightBeforeAction;
    
    BOOL textInputExpanded;
    BOOL emojiExpanded;

    CGFloat keyboardHeight;
    
    NSString * inputFieldText;
    
    NSArray * reloadInputAction;
    BOOL isObservingKeyboard;
    BOOL editMessageMode;
}

@property (nonatomic, strong) BarModel * barModel;
@property (nonatomic, strong) SBTextItemView * textItemView;

@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;
@property (nonatomic, weak) IBOutlet UIButton *backButton;

@property (nonatomic, strong) RecordAudioView * audioView;
@property (nonatomic, strong) UIView * emojiView;
@property (nonatomic, strong) StickerView * stickerView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *zeroLevelViewHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *firstLevelBackgroundViewHeight;

@property (nonatomic, readwrite) NSString * text;

@end

@implementation SBCoordinator

-(instancetype)initWithBarModel:(BarModel *)barModel
{
    CGRect frame = CGRectMake(0.0f, 0.0f, SCREEN_WIDTH, defaultHeight);
    return [self initWithFrame:frame andBarModel:barModel];
}

-(instancetype)initWithFrame:(CGRect)frame andBarModel:(BarModel *)barModel
{
    self = [super init];
    if (self)
    {
        NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
        [NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"SBCoordinator" owner:self options:nil];
        
        self.view.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
        self.view.clipsToBounds = YES;
        self.view.translatesAutoresizingMaskIntoConstraints = NO;
        self.zeroLevelView.translatesAutoresizingMaskIntoConstraints = NO;
        self.firstLevelBackground.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.barModel = barModel;
        
        self.firstLevelBackgroundViewHeight.constant = self.view.frame.size.height - defaultHeight;
        self.firstLevelView.scrollsToTop = NO;
        self.firstLevelView.backgroundColor = [UIColor clearColor];
        self.backButton.hidden = YES;
        [self.backButton setTintColor:[[SenderCore sharedCore].stylePalette mainAccentColor]];
        [self.pageControl setCurrentPageIndicatorTintColor:[[SenderCore sharedCore].stylePalette mainAccentColor]];
        [self.pageControl setPageIndicatorTintColor:[UIColor lightGrayColor]];
        
        [self startObservingKeyboardChanges];
        
        editMessageMode = NO;
    }
    return self;
}

- (UIView *)emojiView
{
    //    if (!_emojiView)
    //    {
    EmojiLauncherViewController * emojiLauncher = [EmojiLauncherViewController controller];
    emojiLauncher.delegate = self;
    _emojiView = emojiLauncher.view;
    _emojiView.frame = CGRectMake(0.0f, 0.0f, 414.0f, 216.0f);
    [self addChildViewController:emojiLauncher];
    //
    //        EmojiLauncherView * emojiSelector = [[EmojiLauncherView alloc] init];
    //        emojiSelector.backgroundColor = [UIColor whiteColor];
    //        emojiSelector.delegate = self;
    //
    //        _emojiView = [[UIScrollView alloc]initWithFrame:emojiSelector.bounds];
    //        [_emojiView addSubview:emojiSelector];
    //        _emojiView.contentSize = emojiSelector.frame.size;
    //    }
    return _emojiView;
}

- (RecordAudioView *)audioView
{
    if (!_audioView)
    {
        _audioView = [[RecordAudioView alloc] init];
        _audioView.backgroundColor = [UIColor whiteColor];
        [_audioView setUpView];
        _audioView.delegate = self;
    }
    return _audioView;
}

-(StickerView *)stickerView
{
    if (!_stickerView)
    {
        _stickerView = [[StickerView alloc] init];
        _stickerView.backgroundColor = [UIColor whiteColor];
        _stickerView.delegate = self;
        _stickerView.backgroundColor = [UIColor whiteColor];
    }
    return _stickerView;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startObservingKeyboardChanges];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self initSendBar];
    [self stopObservingKeyboard];
}

-(void)setDumbMode:(BOOL)dumbMode
{
    if (dumbMode != _dumbMode)
    {
        if (dumbMode)
        {
            [self stopObservingKeyboard];;
        }
        else
        {
            [self startObservingKeyboardChanges];
        }
        _dumbMode = dumbMode;
    }
}

-(BOOL)isEnteringText
{
    return [self.textItemView.inputField isFirstResponder];
}

- (void)startObservingKeyboardChanges
{
    if (!isObservingKeyboard)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidShow:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidHide:)
                                                     name:UIKeyboardDidHideNotification
                                                   object:nil];
        isObservingKeyboard = YES;
    }
}

-(void)stopObservingKeyboard
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    isObservingKeyboard = NO;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)initSendBar
{
    textInputExpanded = NO;
    emojiExpanded = NO;
    if (self.barModel.initializeData)
    {
        NSDictionary * initData = [[ParamsFacade sharedInstance]dictionaryFromNSData:self.barModel.initializeData];
        [self setZeroLevelItems:initData[@"_0"]];
        [self setFirstLevelItems:initData[@"_1"]];
    }
}

-(void)setZeroLevelItems:(NSArray *)items
{
    self.textItemView = nil;
    
    for (UIView * subview in self.zeroLevelView.subviews)
        [subview removeFromSuperview];
    
    CGFloat currentX = 0.0f;
    CGFloat itemViewHeight = defaultHeight;
    
    NSMutableArray * itemsTemp = [NSMutableArray array];
    
    BOOL hasTextItem = NO;
    
    for (NSNumber * itemID in items)
    {
        for (BarItem * itemModel in self.barModel.barItems)
        {
            if ([itemModel hasTextAction])
            {
                reloadInputAction = itemModel.actionsParsed;
                hasTextItem = YES;
                if ([itemModel hasExpandedTextAction])
                    textInputExpanded = YES;
            }
            if ([@([itemModel.itemID integerValue]) isEqualToNumber:itemID])
            {
                if (!([itemModel hasFileAction]))
                {
                    [itemsTemp addObject:itemModel];
                }
                break;
            }
        }
    }
    
    NSArray * itemModels = [itemsTemp copy];
    NSInteger itemsCount = [itemModels count];
    
    //45.0f is default button Width
    CGFloat itemViewWidth = (hasTextItem && textInputExpanded) ? 45.0f : self.view.frame.size.width / itemsCount;
    CGFloat currentWidth;
    CGFloat zeroLevelHeight = itemViewHeight;
    
    for (BarItem * itemModel in itemModels)
    {
        SBItemView * itemView;
        if ([itemModel hasTextAction])
        {
            currentWidth = textInputExpanded ? self.firstLevelView.frame.size.width - (itemsCount - 1) * itemViewWidth : itemViewWidth;
            itemView = [[SBTextItemView alloc]initWithFrame:CGRectMake(currentX, 0.0f, currentWidth, itemViewHeight)
                                               andItemModel:itemModel
                                               shouldExpand:textInputExpanded
                                                  bigButton:self.expandTextButtonSize];
            self.textItemView = (SBTextItemView *)itemView;
            self.textItemView.enterEmoji = emojiExpanded;
            self.textItemView.emojiInputView = self.emojiView;
        }
        else
        {
            currentWidth = itemViewWidth;
            itemView = [[SBItemView alloc]initWithFrame:CGRectMake(currentX, 0.0f, itemViewWidth, itemViewHeight)
                                           andItemModel:itemModel];
            if ([itemModel hasCryptoAction] && [self.delegate respondsToSelector:@selector(coordinator:isCurrentChatEncripted:)])
                itemView.selected = [self.delegate coordinator:self isCurrentChatEncripted:YES];
        }
        
        [self.zeroLevelView addSubview:itemView];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                              attribute:NSLayoutAttributeLeft
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.zeroLevelView
                                                              attribute:NSLayoutAttributeLeft
                                                             multiplier:1.0f
                                                               constant:currentX]];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                              attribute:NSLayoutAttributeWidth
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:1.0f
                                                               constant:currentWidth]];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.zeroLevelView
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0f
                                                               constant:0.0f]];
        
        if ([itemView isKindOfClass:[SBTextItemView class]])
        {
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.zeroLevelView
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1.0f
                                                                   constant:0.0f]];
        }
        else
        {
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:1.0f
                                                                   constant:itemViewHeight]];
        }
        
        itemView.hidesTitle = YES;
        itemView.delegate = self;
        if (self.barModel.mainTextColor)
            itemView.titleTextColor = [[SenderCore sharedCore].stylePalette colorWithHexString:self.barModel.mainTextColor];
        
        currentX += currentWidth;
    }
    
    self.zeroLevelViewHeight.constant = zeroLevelHeight;
    
    if (hasTextItem && textInputExpanded)
    {
        [self.textItemView.inputField becomeFirstResponder];
        [self.delegate coordinator:self didExpandTextView:YES];
    }
    
    if (textInputExpanded)
        [self.textItemView setText:inputFieldText];

    [self.view layoutSubviews];
}

- (void)setFirstLevelItems:(NSArray *)items
{
    self.backButton.hidden = YES;

    CGFloat itemViewHeight = 108.0f;
    
    NSUInteger rowsCount = [items count] == 0 ? 0 : ([items count] > firstLevelViewsPerRow ? 2 : 1);
    
    [self.firstLevelView removeAllSubviews];
    
    NSInteger itemNumber;
    NSInteger itemsPerRow = 0;
    CGFloat currentX = 0.0f;
    CGFloat itemViewWidth = 0.0f;
    CGFloat contentWidth = 0.0f;
    
    NSMutableArray * itemsTemp = [NSMutableArray array];
    
    for (NSNumber * itemID in items)
    {
        for (BarItem * itemModel in self.barModel.barItems)
        {
            if ([@([itemModel.itemID integerValue]) isEqualToNumber:itemID])
            {
                if (![itemModel hasFileAction] && ![itemModel hasCryptoAction])
                    [itemsTemp addObject:itemModel];
                
                break;
            }
        }
    }
    
    NSArray * itemModels = [itemsTemp copy];
    NSInteger itemsCount = [itemModels count];
    
    for (BarItem * itemModel in itemModels)
    {
        itemNumber = [itemModels indexOfObject:itemModel];
        
        if (itemNumber % firstLevelViewsPerRow == 0)
        {
            itemsPerRow = (itemsCount - itemNumber >= firstLevelViewsPerRow) ? firstLevelViewsPerRow : itemsCount - itemNumber;
            itemViewWidth = self.firstLevelView.frame.size.width / itemsPerRow;
        }
        
        currentX = itemViewWidth * (itemNumber % firstLevelViewsPerRow) + (self.firstLevelView.frame.size.width * (NSInteger)(itemNumber / (rowsCount * firstLevelViewsPerRow)));
        
        
        SBItemView * itemView = [[SBItemView alloc]initWithFrame:CGRectMake(currentX, (itemNumber / firstLevelViewsPerRow) % 2 * itemViewHeight, itemViewWidth, itemViewHeight) andItemModel:itemModel];
    
        itemView.translatesAutoresizingMaskIntoConstraints = NO;
        itemView.delegate = self;
        
        if (self.barModel.mainTextColor)
            itemView.titleTextColor = [[SenderCore sharedCore].stylePalette colorWithHexString:self.barModel.mainTextColor];
        
//        if ([itemModel hasCryptoAction] && [self.delegate respondsToSelector:@selector(coordinator:isCurrentChatEncripted:)])
//            itemView.selected = [self.delegate coordinator:self isCurrentChatEncripted:YES];
        
            [self.firstLevelView addSubview:itemView];
        
        
        [self.firstLevelBackground addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                                              attribute:NSLayoutAttributeLeft
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self.firstLevelView
                                                                              attribute:NSLayoutAttributeLeft
                                                                             multiplier:1.0f
                                                                               constant:currentX]];
        
        [self.firstLevelBackground addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                                              attribute:NSLayoutAttributeTop
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self.firstLevelView
                                                                              attribute:NSLayoutAttributeTop
                                                                             multiplier:1.0f
                                                                               constant:(itemNumber / firstLevelViewsPerRow) % 2 * itemViewHeight]];
        
        [self.firstLevelBackground addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                                              attribute:NSLayoutAttributeWidth
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:nil
                                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                                             multiplier:1.0f
                                                                               constant:itemViewWidth]];
        
        [self.firstLevelBackground addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                                              attribute:NSLayoutAttributeHeight
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:nil
                                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                                             multiplier:1.0f constant:itemViewHeight]];
        
        [self.firstLevelBackground layoutIfNeeded];
        
        contentWidth = CGRectGetMaxX(itemView.frame) > contentWidth ? CGRectGetMaxX(itemView.frame) : contentWidth;
    }
    
    if (rowsCount == 0 && keyboardHeight >= 0.0f)
    {
        [self showActionsView:SBCoordinatorViewEmpty];
    }
    else
    {
        self.firstLevelBackground.backgroundColor = [UIColor whiteColor];
        [self setFirstLevelHeight:itemViewHeight * rowsCount];
        [self setFirstLevelContentSize:CGSizeMake(contentWidth, itemViewHeight * rowsCount)];
    }
}

-(void)handleActions:(NSArray *)actions
{
    if (!self.textItemView.inputField.isFirstResponder)
    {
        id firsResponder = [UIView findFirstResponder];
        [firsResponder endEditing:YES];
    }
    
    if (!self.dumbMode)
    {
        for (NSDictionary * action in actions)
        {
            if ([action[@"oper"] isEqualToString:@"sendMsg"])
            {
                textInputExpanded = YES;
                break;
            }
        }
        
        for (NSDictionary * action in actions)
        {
            if ([action[@"oper"] isEqualToString:@"reload"])
            {
                if (action[@"_0"])
                    [self setZeroLevelItems:action[@"_0"]];
                
                [self setFirstLevelItems:action[@"_1"]];
            }
        }
    }
    
    if (actions && [self.delegate respondsToSelector:@selector(coordinator:didSelectItemWithActions:)])
        [self.delegate coordinator:self didSelectItemWithActions:actions];
}

- (void)setZeroLevelHeight:(CGFloat)height
{
    self.zeroLevelViewHeight.constant = height;
    CGFloat newHeight = self.zeroLevelViewHeight.constant + self.firstLevelView.frame.size.height;
    if ([self.delegate respondsToSelector:@selector(coordinator:didChangeItsHeight:)])
        [self.delegate coordinator:self didChangeItsHeight:newHeight];
}

-(void)setFirstLevelHeight:(CGFloat)height
{
    self.view.frame = CGRectMake(self.view.frame.origin.x,
                                 self.view.frame.origin.y,
                                 self.view.frame.size.width,
                                 self.zeroLevelView.frame.size.height + height);
    self.firstLevelBackgroundViewHeight.constant = height;
    if ([self.delegate respondsToSelector:@selector(coordinator:didChangeItsHeight:)])
        [self.delegate coordinator:self didChangeItsHeight:self.zeroLevelViewHeight.constant + height];

}

-(void)setFirstLevelContentSize:(CGSize)contentSize
{
    self.firstLevelView.contentSize = contentSize;
    self.pageControl.numberOfPages = contentSize.width / self.firstLevelView.frame.size.width;
    self.firstLevelView.scrollEnabled = self.pageControl.numberOfPages > 1;
    self.firstLevelView.pagingEnabled = self.pageControl.numberOfPages > 1;
    self.pageControl.hidden = self.pageControl.numberOfPages < 2;
}

#pragma mark - SBItemView Delegate Methods

-(void)itemView:(SBItemView *)itemView didChooseActionsWithData:(NSArray *)actionsData
{
    if (self.textItemView && textInputExpanded)
        inputFieldText = self.textItemView.inputField.text;
    
    [self handleActions:actionsData];
    
    if ([itemView.itemModel hasCryptoAction] && [self.delegate respondsToSelector:@selector(coordinator:isCurrentChatEncripted:)])
        itemView.selected = [self.delegate coordinator:self isCurrentChatEncripted:YES];
}

#pragma mark - SBTextItemView Delegate Methods

-(void)textItemView:(SBTextItemView *)textItem didChangeHeight:(CGFloat)height
{
    [self setZeroLevelHeight:height];
}

-(void)textItemView:(SBTextItemView *)textItem didPressSendWithText:(NSString *)text
{
    if (editMessageMode)
    {
        editMessageMode = NO;
        if ([self.delegate respondsToSelector:@selector(coordinator:didFinishEditingText:)])
            [self.delegate coordinator:self didFinishEditingText:text];
    }
    else
    {
        NSArray * action = @[@{@"oper" : @"__internal__sendText", @"text" : [text copy]}];
        if ([self.delegate respondsToSelector:@selector(coordinator:didSelectItemWithActions:)])
            [self.delegate coordinator:self didSelectItemWithActions:action];
    }
    inputFieldText = nil;
    [self.textItemView setText:@""];
}

-(void)textItemViewDidBeginEditing:(SBTextItemView *)textItem {}

-(void)textItemViewDidEndEditing:(SBTextItemView *)textItem
{
    inputFieldText = textItem.inputField.text;
    [self initSendBar];
    if (self.firstLevelBackground.frame.size.height != keyboardHeight)
        [self showActionsView:SBCoordinatorViewEmpty];
}

- (void)textItemViewDidType:(SBTextItemView *)textItem
{
    if ([self.delegate respondsToSelector:@selector(coordinatorDidType:)])
        [self.delegate coordinatorDidType:self];
}

#pragma mark - Keyboard Handling Methods

- (void)keyboardWillShow:(NSNotification *)notification
{
    keyboardHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    if (!self.isEnteringText)
    {
        [self initSendBar];
        [self setZeroLevelItems:@[]];
        [self setZeroLevelHeight:0.0f];
    }
    else if (self.firstLevelBackground.frame.size.height != keyboardHeight)
    {
        [self showActionsView:SBCoordinatorViewEmpty];
    }
}

- (void)keyboardDidShow:(NSNotification *)notification{}

- (void)keyboardWillHide:(NSNotification *)notification
{
    keyboardHeight = 0.0f;
    [self initSendBar];
}

- (void)keyboardDidHide:(NSNotification *)notification{}

- (void)startEmojiInput
{
    [self.textItemView.inputField resignFirstResponder];
    emojiExpanded = YES;
    if (!textInputExpanded)
        [self handleActions:reloadInputAction];
}

#pragma mark - Adding Actions View

-(void)showActionsView:(SBCoordinatorView)viewType
{
    [self.firstLevelView removeAllSubviews];
    
    switch (viewType) {
        case SBCoordinatorViewAudio:
        {
            if (self.audioView.isSetUp)
                [self.audioView setUpView];
            [self addNativeViewToFirstLevel:self.audioView];
            self.firstLevelBackground.backgroundColor = [UIColor whiteColor];
        }
            break;
        case SBCoordinatorViewStickers:
        {
            [self addNativeViewToFirstLevel:self.stickerView];
            [self goToStickerChoose];
            self.firstLevelBackground.backgroundColor = [UIColor whiteColor];
        }
            break;
        case SBCoordinatorViewEmpty:
        {
            UIView * emptyView = [[UIView alloc]initWithFrame:CGRectMake(0.0f, 0.0f, SCREEN_WIDTH, keyboardHeight)];
            [self addNativeViewToFirstLevel:emptyView];
        }
            break;
            
        default:
            break;
    }
}

-(void)addNativeViewToFirstLevel:(UIView *)view
{
    if (view)
    {
        if (view == self.audioView)
        {
            [self.textItemView.inputField resignFirstResponder];
        }
        if (keyboardHeight)
            view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, keyboardHeight);
        
        [self.firstLevelView addSubview:view];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self fixViewConstraints:view];
    }

    [self setFirstLevelHeight:view.frame.size.height];
    [self setFirstLevelContentSize:view.frame.size];
}

-(void)fixViewConstraints:(UIView *)view
{
    [self.firstLevelView removeConstraints:self.firstLevelView.constraints];
    
    [self.firstLevelView addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.firstLevelView attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f]];
    [self.firstLevelView addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.firstLevelView attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];
    [self.firstLevelView addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:view.frame.size.width]];
    [self.firstLevelView addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:view.frame.size.height]];
}

#pragma StickerView Delegate

- (void)stickerViewDidSelectedSticker:(NSString *)stickerID
{
    NSArray * action = @[@{@"oper" : @"__internal__sendSticker", @"stickerID" : stickerID}];
    if ([self.delegate respondsToSelector:@selector(coordinator:didSelectItemWithActions:)])
        [self.delegate coordinator:self didSelectItemWithActions:action];
}

- (void)goToStickerChoose
{
    [self fixViewConstraints:self.stickerView];
    [self.stickerView goBack];
    self.backButton.hidden = YES;
    [self.backButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self setFirstLevelContentSize:self.stickerView.frame.size];
}

-(void)stickerViewDidOpenedStickerPack
{
    [self fixViewConstraints:self.stickerView];
    [self setFirstLevelContentSize:self.stickerView.frame.size];
    self.backButton.hidden = NO;
    [self.backButton addTarget:self action:@selector(goToStickerChoose) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat pageWidth = self.firstLevelView.frame.size.width;
    int page = floor((self.firstLevelView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
}

#pragma mark - RecordAudioView Delegate

- (void)recordAudioViewDidRecordedTrack:(NSData *)data
{
    NSArray * action = @[@{@"oper" : @"__internal__sendAudio", @"trackData" : data}];
    if ([self.delegate respondsToSelector:@selector(coordinator:didSelectItemWithActions:)])
        [self.delegate coordinator:self didSelectItemWithActions:action];
}

#pragma mark - EmojiLauncher Delegate

-(void)emojiLauncherDidSelectedEmoji:(NSString *)emoji
{
    UIView * responderView = self.textItemView.inputField;
    
    id<UITextInput> textInput = [self findViewsSubviewWithTextInput:responderView];
    if (textInput == nil) return;
    
    if ([responderView isKindOfClass:[UITextField class]])
    {
        UITextField *inputField = (UITextField*)responderView;
        UITextRange *selRange = [textInput selectedTextRange];
        id<UITextFieldDelegate> delegate = [inputField delegate];
        NSRange range = [self makeSimpleRangeFromTextRange:selRange forTextInput:textInput];
        if ([delegate textField:inputField shouldChangeCharactersInRange:range replacementString:emoji])
        {
            [textInput replaceRange:selRange withText:emoji];
        }
    }
    else
    {
        UITextRange *selectedRange = [textInput selectedTextRange];
        [textInput replaceRange:selectedRange withText:emoji];
    }
}

-(void)emojiLauncherDidSelectedBackspace
{
    UIView * responderView = self.textItemView.inputField;
    
    id<UITextInput> textInput = [self findViewsSubviewWithTextInput:responderView];
    if (textInput == nil) return;
    
    if ([responderView isKindOfClass:[UITextField class]])
    {
        UITextField *inputField = (UITextField*)responderView;
        UITextRange *selectedRange = [textInput selectedTextRange];
        id<UITextFieldDelegate> delegate = [inputField delegate];
        
        if (selectedRange.isEmpty)
        {
            UITextPosition *end = selectedRange.start;
            UITextPosition *start;
            
            if ([inputField.text length] >= 2 &&  [[ParamsFacade sharedInstance]stringContainsEmoji:[inputField textInRange:[inputField textRangeFromPosition:[inputField positionFromPosition:end offset:-2] toPosition:end]]])
                start = [inputField positionFromPosition:end offset:-2];
            else
                start = [inputField positionFromPosition:end offset:-1];
            
            selectedRange = [inputField textRangeFromPosition:start toPosition:end];
        }
        
        NSRange range = [self makeSimpleRangeFromTextRange:selectedRange forTextInput:textInput];
        
        if ([delegate textField:inputField shouldChangeCharactersInRange:range replacementString:@""])
            [textInput replaceRange:selectedRange withText:@""];
    }
    else if ([responderView isKindOfClass:[UITextView class]])
    {
        UITextView *inputField = (UITextView*)responderView;
        UITextRange *selectedRange = [textInput selectedTextRange];
        id<UITextViewDelegate> delegate = [inputField delegate];
        
        if (selectedRange.isEmpty)
        {
            UITextPosition *end = selectedRange.start;
            UITextPosition *start;
            
            
            if ([inputField.text length] >= 2 &&  [[ParamsFacade sharedInstance]stringContainsEmoji:[inputField textInRange:[inputField textRangeFromPosition:[inputField positionFromPosition:end offset:-2] toPosition:end]]])
                start = [inputField positionFromPosition:end offset:-2];
            else
                start = [inputField positionFromPosition:end offset:-1];
            
            selectedRange = [inputField textRangeFromPosition:start toPosition:end];
        }
        
        NSRange range = [self makeSimpleRangeFromTextRange:selectedRange forTextInput:textInput];

        if ([delegate textView:inputField shouldChangeTextInRange:range replacementText:@""])
            [inputField replaceRange:selectedRange withText:@""];
    }
}

- (id) findViewsSubviewWithTextInput:(UIView*)item
{
    if ([item conformsToProtocol:@protocol(UITextInput)]) return item;
    
    for (UIView * v in [item subviews]) {
        id res = [self findViewsSubviewWithTextInput:v];
        if (res) return res;
    }
    return nil;
}

- (NSRange) makeSimpleRangeFromTextRange:(UITextRange*)textRange forTextInput:(id<UITextInput>)input
{
    NSUInteger length = [input offsetFromPosition:textRange.start toPosition:textRange.end];
    NSUInteger location = [input offsetFromPosition:input.beginningOfDocument toPosition:textRange.start];
    return NSMakeRange(location, length);
}

- (void)runEditText:(NSString *)text
{
    editMessageMode = YES;
    inputFieldText = text;
    self.textItemView.text = text;
    if (!textInputExpanded)
        [self handleActions:reloadInputAction];
    [self.textItemView.inputField becomeFirstResponder];
}

- (void)setInputText:(NSString *)text
{
    inputFieldText = text;
    self.textItemView.text = text;
}

- (NSString *)text
{
    return [self isEnteringText] ? self.textItemView.text : inputFieldText;
}

@end
