//
//  RightPanelCell.m
//  Sender
//
//  Created by Eugene Gilko on 9/16/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "RightPanelCell.h"
#import "PBConsoleConstants.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "DefaultContactImageGenerator.h"
#import "ImagesManipulator.h"
#import "ChatMember+CoreDataClass.h"

static UIImage * onLine,  * offLine;

@interface RightPanelCell ()
{
    NSTimeInterval time;    
    
    UILongPressGestureRecognizer * longTapRecognizer;
    
    IBOutlet NSLayoutConstraint * leftOffset;
    IBOutlet NSLayoutConstraint * rightOffset;
    IBOutlet UIButton * deleteButton;

}
@end

@implementation RightPanelCell

- (void)awakeFromNib
{
    // Initialization code
    
    longTapRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongTap:)];
    [deleteButton setImage:[UIImage imageFromSenderFrameworkNamed:@"_delete"] forState:UIControlStateNormal];
    self.isDeleting = NO;
    deleteButton.backgroundColor = [[SenderCore sharedCore].stylePalette alertColor];
    deleteButton.hidden = YES;
    [self addGestureRecognizer:longTapRecognizer];
    if(!onLine)
    {
        onLine = [UIImage imageFromSenderFrameworkNamed:@"on_line"];
        offLine = [UIImage imageFromSenderFrameworkNamed:@"off_line"];
    }
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

-(void)dealloc
{
    [longTapRecognizer removeTarget:self action:@selector(handleLongTap:)];
    longTapRecognizer = nil;
}

-(void)handleLongTap:(UILongPressGestureRecognizer *)recognizer
{
    if (self.isDeletingEnabled)
        [self startDeleting];
}

-(void)startDeleting
{
    if (!self.isDeleting)
        [self toggleDeletingAnimated:YES];
}

-(void)stopDeleting
{
    if (self.isDeleting)
        [self toggleDeletingAnimated:YES];
}

-(void)prepareForReuse
{
    if (self.isDeleting)
        [self toggleDeletingAnimated:NO];
}

-(void)toggleDeletingAnimated:(BOOL)animated
{
    self.isDeleting = !self.isDeleting;
    if (self.isDeleting)
    {
        deleteButton.hidden = NO;
        rightOffset.constant = deleteButton.frame.size.width;
        leftOffset.constant -= deleteButton.frame.size.width;
    }
    else
    {
        CGFloat deltaX = leftOffset.constant + deleteButton.frame.size.width;
        leftOffset.constant += deleteButton.frame.size.width;
        rightOffset.constant = deltaX;
    }
    if (animated)
    {
        [UIView animateWithDuration:0.3f animations:^{
            [self layoutIfNeeded];
        }completion:^(BOOL finished) {
            deleteButton.hidden = !self.isDeleting;
        }];
    }
    else
    {
        [self layoutIfNeeded];
        deleteButton.hidden = !self.isDeleting;
    }

}

-(IBAction)deleteButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(deleteRightPanelCell:)])
        [self.delegate deleteRightPanelCell:self];
}

- (void)customizeUserImageView
{
    [self.userImage setContentMode:UIViewContentModeScaleAspectFit];
    self.userImage.layer.cornerRadius = self.userImage.frame.size.width/2;
    self.userImage.layer.borderWidth = 1.0f;
    self.userImage.clipsToBounds = YES;
}

- (void)setChatMember:(ChatMember *)chatMember
{
    _chatMember = chatMember;
    self.userNameLabel.text = _chatMember.contact.name;

    [ImagesManipulator setImageForImageView:self.userImage
                                withContact:_chatMember.contact
                         imageChangeHandler:nil];
    self.userNameLabel.textColor = [SenderCore sharedCore].stylePalette.mainTextColor;
    [self customizeUserImageView];
}

@end
