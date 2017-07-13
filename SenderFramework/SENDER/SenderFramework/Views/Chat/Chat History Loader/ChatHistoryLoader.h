//
// Created by Roman Serga on 5/12/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MessagesGap;

@interface ChatHistoryLoader : NSObject

- (BOOL)loadHistoryForMessagesGap:(MessagesGap *)gap completionHandler:(void(^_Nullable)(BOOL))completionHandler;

@end