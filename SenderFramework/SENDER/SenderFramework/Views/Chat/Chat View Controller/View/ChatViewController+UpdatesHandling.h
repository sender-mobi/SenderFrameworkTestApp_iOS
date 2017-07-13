//
// Created by Roman Serga on 27/7/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatViewController.h"

@interface ChatViewController (UpdatesHandling)

@property (nonatomic, strong) NSTimer * updateTimer;
@property (nonatomic, strong) NSArray * pendingNewMessages;
@property (nonatomic) dispatch_semaphore_t updateSemaphore;
@property (nonatomic, strong) NSMutableDictionary * timers;
@property (nonatomic, strong) NSMutableSet * typingUsers;

@end