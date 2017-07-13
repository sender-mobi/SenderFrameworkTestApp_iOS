//
//  PBSelectedView.h
//  ZiZZ
//
//  Created by Eugene Gilko on 7/24/14.
//  Copyright (c) 2014 Dima Yarmolchuk. All rights reserved.
//

#import "PBSubviewFacade.h"
#import "PBPopUpSelector.h"

@interface PBSelectedView : PBSubviewFacade <PBPopUpSelectorDelegate>

@property (nonatomic, strong) UITextField * inputTextField;
@property (nonatomic, weak) MainConteinerModel * viewModel;

@end
