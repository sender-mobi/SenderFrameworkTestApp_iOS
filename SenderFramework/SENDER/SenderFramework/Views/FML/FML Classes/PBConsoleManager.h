//
//  PBConsoleMenager.h
//  
//
//  Created by Eugene Gilko on 7/18/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBConsoleView.h"
#import "Message.h"

@interface PBConsoleManager : NSObject

+ (PBConsoleView *)buildConsoleViewFromDate:(Message *)model forViewController:(UIViewController *)viewController;
//+ (CompanyFormView *)buildCompanyFormWithDate:(Message *)model;

@end
