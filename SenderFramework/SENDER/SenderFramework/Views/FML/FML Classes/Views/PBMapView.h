//
//  PBMapView.h
//  SENDER
//
//  Created by Eugene Gilko on 04.05.15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "PBSubviewFacade.h"
#import "ShowMapViewController.h"

@interface PBMapView : PBSubviewFacade <ShowMapViewControllerDelegate>

@property (nonatomic, strong) UITextField * inputTextField;
@property (nonatomic, weak) MainConteinerModel * viewModel;

@end
