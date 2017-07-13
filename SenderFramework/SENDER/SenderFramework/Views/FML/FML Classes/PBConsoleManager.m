//
//  PBConsoleMenager.m
//  ZiZZ
//
//  Created by Eugene Gilko on 7/18/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBConsoleManager.h"
#import "ParamsFacade.h"
#import "MainConteinerModel.h"
#import <SenderFramework/SenderFramework-Swift.h>

@implementation PBConsoleManager

+ (PBConsoleView *)buildConsoleViewFromDate:(Message *)model forViewController:(UIViewController *)viewController
{
//    [self buildTestModelAndView:model];
    
    __strong MainConteinerModel * cellModel = [[MainConteinerModel alloc] initWithMessageData:model];
    return [[PBConsoleView alloc] initWithCellModel:cellModel
                                            message:model
                                            forRect:[self screenBounds]
                                 rootViewController:viewController];
}

+ (CGRect)screenBounds
{
    return [[UIScreen mainScreen] bounds];
}

+ (MainConteinerModel *)getMainConteinerfromModel:(Message *)model
{
    return [[MainConteinerModel alloc] initWithMessageData:model];
}

+ (void)buildTestModelAndView:(Message *)model
{
    MWFormBuilder * fModel = [[MWFormBuilder alloc] init];
    
}

@end
