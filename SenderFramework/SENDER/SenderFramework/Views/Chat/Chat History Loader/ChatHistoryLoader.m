//
// Created by Roman Serga on 5/12/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import "ChatHistoryLoader.h"
#import "MessagesGap.h"
#import "ServerFacade.h"

@implementation ChatHistoryLoader
{
    MessagesGap * activeGap;
}

- (BOOL)loadHistoryForMessagesGap:(MessagesGap *)gap completionHandler:(void(^_Nullable)(BOOL))completionHandler
{
    if (activeGap)
        return NO;

    if (!gap.dialog)
        return NO;

    [[ServerFacade sharedInstance] getHistoryForChat:gap.dialog
                                     withMessagesGap:gap completionHandler:^(NSDictionary *response, NSError *error)
            {
                if (completionHandler)
                    completionHandler(error == nil);
            }];

    return YES;
}

@end
