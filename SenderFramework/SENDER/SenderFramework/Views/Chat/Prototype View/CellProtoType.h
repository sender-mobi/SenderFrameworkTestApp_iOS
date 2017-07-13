//
//  CellProtoType.h
//  SENDER
//
//  Created by Eugene on 2/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"

typedef enum {
    EDIT = 0, DELETE, RESEND
} CellAction;

@class CellProtoType;

@protocol ChatCellDelegate <NSObject>

- (void)cellCallForModel:(Message *)model doAction:(CellAction)action;

@end

@protocol FileViewDelegate;

@interface CellProtoType : UIView <UIGestureRecognizerDelegate>
{
    IBOutlet UIImageView * cellUserImage;
    IBOutlet UIView * mainContainer;
    IBOutlet UILabel * cellUserNameLabel;
    IBOutlet UILabel * cellTimeLabel;
    IBOutlet UIImageView * cellDelivIndicator;
    Message * viewModel;
}

@property (nonatomic, assign) id<ChatCellDelegate> delegate;
@property (nonatomic, weak) id<FileViewDelegate> fileViewDelegate;

- (instancetype)initWithModel:(Message *)model andWidth:(CGFloat)width;
- (void)configureCell:(Message *)model showUserImage:(BOOL)showImage;
- (void)hideCellImage;
- (void)showCellImage;
- (void)hideStatus;
- (void)showStatus;
- (BOOL)isStatusHidden;
- (void)checkDelivery;
- (void)clearContentView;

@end
