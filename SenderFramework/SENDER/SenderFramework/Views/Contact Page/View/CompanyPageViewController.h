//
// Created by Roman Serga on 7/6/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatViewController.h"

@protocol ContactPageViewProtocol;
@protocol ContactPagePresenterProtocol;

@interface CompanyPageViewController : ChatViewController <ContactPageViewProtocol>

@property (nonatomic, strong, nullable) id<ContactPagePresenterProtocol> presenter;

@property (nonatomic, strong) Dialog * companyChat;

@end