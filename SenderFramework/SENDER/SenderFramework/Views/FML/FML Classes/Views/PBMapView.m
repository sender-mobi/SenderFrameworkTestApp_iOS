//
//  PBMapView.m
//  SENDER
//
//  Created by Eugene Gilko on 04.05.15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "PBMapView.h"
#import "ConsoleCaclulator.h"
#import "MainConteinerModel.h"

@implementation PBMapView
@dynamic viewModel;

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainConteinerModel *)submodel
{
    [super settingViewWithRect:mainRect andModel:submodel];

    self.viewModel = submodel;
    float startX = 0;
    if (mainRect.origin.x > 0)
        startX = mainRect.origin.x;
    
    self.frame = CGRectMake(startX, mainRect.origin.y, mainRect.size.width, 50.0);
    self.backgroundColor = [UIColor clearColor];
    
    _inputTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, mainRect.size.width, 40.0)];// - leftIndent - rightIndent
    
    [_inputTextField setFont:[PBConsoleConstants inputTextFieldFontStyle:self.viewModel.fontStyle
                                                                 andSize:self.viewModel.fontSize]];
    [_inputTextField setPlaceholder:self.viewModel.hint];
    
    if (self.viewModel.color) {
        [_inputTextField setTextColor:[PBConsoleConstants colorWithHexString:self.viewModel.color]];
    }
    
    _inputTextField.userInteractionEnabled = NO;
    [PBConsoleConstants makeTextFieldUnselected:_inputTextField];
    
    if (self.viewModel.b_size) {
        _inputTextField.layer.borderWidth = [self.viewModel.b_size floatValue];
    }
    if (self.viewModel.b_color) {
        _inputTextField.layer.borderColor = [PBConsoleConstants colorWithHexString:self.viewModel.b_color].CGColor;
    }
    
    if (self.viewModel.b_radius) {
        _inputTextField.layer.cornerRadius = [self.viewModel.b_radius floatValue];
        _inputTextField.layer.masksToBounds=YES;
    }
    else {
        _inputTextField.layer.cornerRadius = 0;
        _inputTextField.layer.masksToBounds = YES;
    }
    _inputTextField.text = self.viewModel.title;
    [self addSubview:_inputTextField];
    
    UIButton * actionButton = [[UIButton alloc] initWithFrame:_inputTextField.frame];
    [actionButton addTarget:self action:@selector(cellAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:actionButton];
}

- (void)cellAction
{
    ShowMapViewController * smV = [[ShowMapViewController alloc] init];
    smV.delegate = self;
    smV.secondDelegateRun = YES;
    if (self.viewModel.vars_type && [self.viewModel.vars_type isEqualToString:@"MPOINT"])
        smV.poiArray = self.viewModel.vars;

    UIViewController * rootViewController = [self.delegate presentingViewController];
    [rootViewController presentViewController:smV animated:YES completion:NULL];
}

- (void)   locationSelect:(ShowMapViewController *)controller
didFinishEnteringLocation:(CLLocation *)location
        withDesc:(NSString *)description
{
    self.viewModel.title = description;
    _inputTextField.text = description;

    [controller dismissViewControllerAnimated:YES completion:nil];

    NSNumber * latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
    NSNumber * longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
    
    self.viewModel.val = [NSString stringWithFormat:@"%@,%@",latitude,longitude];
}

- (void)   pushOnLocation:(ShowMapViewController *)controller
didFinishEnteringLocation:(CLLocation *)location
                  andImge:(UIImage *)image
                 withDesc:(NSString *)description {}


@end
