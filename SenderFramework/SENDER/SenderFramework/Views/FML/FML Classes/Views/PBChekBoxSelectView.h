//
//  PBChekBoxSelectView.h
//  SENDER
//
//  Created by Eugene on 11/20/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBSubviewFacade.h"
#import "PBCheckBoxView.h"

@interface PBChekBoxSelectView : PBSubviewFacade <PBCheckBoxViewDelegate>
@property (nonatomic, weak) MainConteinerModel * viewModel;

@end
