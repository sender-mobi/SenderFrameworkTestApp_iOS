//
//  OwnerCoordinateMessage.h
//  SENDER
//
//  Created by Eugene on 11/25/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"

@interface OwnerCoordinateMessage : UIView
{
    UILabel * delivLabel;
    UIImageView * booble;
}

- (void)initViewWithModel:(Message *)msgModel;
- (void)showHideDelivered:(BOOL)mode;
- (void)changeBgBooble;
- (void)hideImg;
- (void)checkDeliv;
- (void)hideName;
@property (nonatomic, strong) Message * viewModel;
@end
