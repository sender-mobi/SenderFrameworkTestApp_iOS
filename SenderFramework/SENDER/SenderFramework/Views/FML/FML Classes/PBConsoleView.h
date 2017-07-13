//
//  PBConsoleView.h
//  ZiZZ
//
//  Created by Eugene Gilko on 7/18/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainConteinerModel.h"
#import "PBButtonInFormView.h"
#import "PBSubviewFacade.h"

@interface PBConsoleView : UIView <PBButtonInFormViewDelegate, PBSubviewDelegate>

- (PBConsoleView *)initWithCellModel:(MainConteinerModel *)cellModel
                             message:(Message *)message
                             forRect:(CGRect)rect
                  rootViewController:(UIViewController *)rootViewController;

@property (nonatomic, weak) UIViewController * rootViewController;
@property (nonatomic, strong) MainConteinerModel * cellModel;
@property (nonatomic, weak) Message * message;
- (void)submitDataWithInfo:(NSDictionary *)info;

@end

@interface BoxContainer : PBSubviewFacade

@property (nonatomic, strong) UIView * contentHolder;

- (instancetype)initWith:(MainConteinerModel *)boxModel andFrame:(CGRect)extRect;
- (void)updateFrame;
- (void)doAction;
@end
