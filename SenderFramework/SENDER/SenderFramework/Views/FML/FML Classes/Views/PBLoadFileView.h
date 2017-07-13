//
//  PBLoadFileView.h
//  SENDER
//
//  Created by Eugene Gilko on 4/11/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "PBSubviewFacade.h"

@interface PBLoadFileView : PBSubviewFacade

@property (nonatomic, weak) MainConteinerModel * viewModel;

@property (nonatomic, strong) UIButton * loadLinkButton;
@property (nonatomic, strong) UILabel * fileName;

@end
