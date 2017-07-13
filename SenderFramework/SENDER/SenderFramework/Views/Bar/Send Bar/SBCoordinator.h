//
//  SBCoordinator.h
//  SENDER
//
//  Created by Roman Serga on 4/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BarModel.h"
#import "SBItemView.h"
#import "SBTextItemView.h"
#import "RecordAudioView.h"
#import "StickerView.h"

typedef NS_ENUM(NSUInteger, SBCoordinatorView) {
    SBCoordinatorViewStickers,
    SBCoordinatorViewAudio,
    SBCoordinatorViewEmpty
};

@class SBCoordinator;

@protocol EmojiLauncherViewControllerDelegate;
@protocol SBCoordinatorDelegate <NSObject>

@optional

-(void)coordinator:(SBCoordinator *)coordinator didSelectItemWithActions:(NSArray *)actionsArray;
-(void)coordinator:(SBCoordinator *)coordinator didChangeItsHeight:(CGFloat)newHeight;
//unnessesaryParameter was added just for beauty)))
- (BOOL)coordinator:(SBCoordinator *)coordinator isCurrentChatEncripted:(BOOL)unnessesaryParameter;
- (void)coordinator:(SBCoordinator *)coordinator didExpandTextView:(BOOL)unnessesaryParameter;
- (void)coordinator:(SBCoordinator *)coordinator didFinishEditingText:(NSString *)text;
- (void)coordinatorDidType:(SBCoordinator *)coordinator;

@end

@interface SBCoordinator : UIViewController <SBItemViewDelegate, SBTextItemViewDelegate, UITextViewDelegate, UIScrollViewDelegate, RecordAudioViewDelegate, StickerViewDelegate, EmojiLauncherViewControllerDelegate>

//In dumb mode SBCoordinator doesn't refresh. Just transfers actions to delegate
@property (nonatomic) BOOL dumbMode;
@property (nonatomic) BOOL expandTextButtonSize;
@property (nonatomic, readonly) NSString * text;

@property (nonatomic, strong) IBOutlet UIView * zeroLevelView;
@property (nonatomic, strong) IBOutlet UIScrollView * firstLevelView;
@property (nonatomic, strong) IBOutlet UIView * firstLevelBackground;
@property (nonatomic, readonly) BOOL isEnteringText;

@property (nonatomic, weak) id<SBCoordinatorDelegate> delegate;

-(instancetype)initWithBarModel:(BarModel *)barModel;
-(instancetype)initWithFrame:(CGRect)frame andBarModel:(BarModel *)barModel;

- (void)initSendBar;

-(void)handleActions:(NSArray *)actions;

-(void)showActionsView:(SBCoordinatorView)viewType;
-(void)startObservingKeyboardChanges;
-(void)stopObservingKeyboard;

-(void)startEmojiInput;
-(void)runEditText:(NSString *)text;
-(void)setInputText:(NSString *)text;

@end
