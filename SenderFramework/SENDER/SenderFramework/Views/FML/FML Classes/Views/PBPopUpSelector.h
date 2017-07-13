//
//  PBPopUpSelector.h
//
//  Created by Eugene Gilko on 7/24/14.
//  Copyright (c) 2014 Eugene Gilko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainConteinerModel.h"

@class PBPopUpSelector;

@protocol PBPopUpSelectorDelegate <NSObject>

- (void)didSelectRow:(PBPopUpSelector *)controller row:(int)row;
- (void)selectCanceled:(PBPopUpSelector *)controller;

@end

@interface PBPopUpSelector : UIView <UITableViewDataSource, UITableViewDelegate>

- (id)initWithFrame:(CGRect)frame andModel:(MainConteinerModel *)model;
- (void)setupTableView;

@property (nonatomic, weak) MainConteinerModel * viewModel;
@property (nonatomic, assign)  id<PBPopUpSelectorDelegate> delegate;

@end
