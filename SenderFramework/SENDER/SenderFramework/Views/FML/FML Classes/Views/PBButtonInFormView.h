//
//  PBButtonInFormView.h
//  SENDER
//
//  Created by Eugene on 10/25/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBSubviewFacade.h"

@class PBButtonInFormView;
@protocol GIDSignInUIDelegate;

@protocol PBButtonInFormViewDelegate <PBSubviewDelegate, GIDSignInUIDelegate>

- (void)pushOnButton:(PBButtonInFormView *)controller didFinishEnteringItem:(NSDictionary *)buttonInfo;

@end

@interface PBButtonInFormView : PBSubviewFacade
{
    UIImage * buttonBg;
//    BOOL autoSubmit;
}

@property (nonatomic, strong) UIButton * doneButton;
@property (nonatomic, assign) id<PBButtonInFormViewDelegate> delegate;
@property (nonatomic, weak) MainConteinerModel * viewModel;

@end
