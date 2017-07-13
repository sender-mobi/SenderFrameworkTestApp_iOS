//
// Created by Roman Serga on 27/7/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import <objc/runtime.h>
#import "ChatViewController+UpdatesHandling.h"
#import "PBConsoleConstants.h"
#import "ServerFacade.h"
#import "MessagesGap.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "Owner.h"
#import "GapMessage.h"
#import "ChatHistoryLoader.h"

#define countToLoad 20

#ifndef dispatch_main_sync_safe
#define dispatch_main_sync_safe(block)\
        if ([NSThread isMainThread]) {\
            block();\
        } else {\
            dispatch_sync(dispatch_get_main_queue(), block);\
        }
#endif

@interface ChatViewController ()

@property(nonatomic, strong) NSArray * messagesToReloadAfterInitialLoad;
@property (nonatomic) BOOL isRemoteHistoryMessages;

@end

@implementation ChatViewController (UpdatesHandling)

#pragma mark - Implementing Properties

- (void)setPendingNewMessages:(NSArray *)pendingNewMessages
{
    objc_setAssociatedObject(self, @selector(pendingNewMessages), pendingNewMessages, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)pendingNewMessages
{
    return objc_getAssociatedObject(self, @selector(pendingNewMessages));
}

- (void)setUpdateTimer:(NSTimer *)updateTimer
{
    objc_setAssociatedObject(self, @selector(updateTimer), updateTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimer *)updateTimer
{
    return objc_getAssociatedObject(self, @selector(updateTimer));
}

- (void)setUpdateSemaphore:(dispatch_semaphore_t)updateSemaphore
{
    objc_setAssociatedObject(self, @selector(updateSemaphore), updateSemaphore, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (dispatch_semaphore_t)updateSemaphore
{
    return objc_getAssociatedObject(self, @selector(updateSemaphore));
}

- (void)setTimers:(NSMutableDictionary *)timers
{
    objc_setAssociatedObject(self, @selector(timers), timers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)timers
{
    return objc_getAssociatedObject(self, @selector(timers));
}

- (void)setTypingUsers:(NSMutableSet *)typingUsers
{
    objc_setAssociatedObject(self, @selector(typingUsers), typingUsers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableSet *)typingUsers
{
    return objc_getAssociatedObject(self, @selector(typingUsers));
}

- (void)setMessagesToReloadAfterInitialLoad:(NSArray *)messagesToReloadAfterInitialLoad
{
    objc_setAssociatedObject(self,
                             @selector(messagesToReloadAfterInitialLoad),
                             messagesToReloadAfterInitialLoad,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)messagesToReloadAfterInitialLoad
{
    return objc_getAssociatedObject(self, @selector(messagesToReloadAfterInitialLoad));
}

- (void)setIsRemoteHistoryMessages:(BOOL)isRemoteHistoryMessages
{
    objc_setAssociatedObject(self,
            @selector(isRemoteHistoryMessages),
            @(isRemoteHistoryMessages),
            OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isRemoteHistoryMessages
{
    return [(NSNumber *) objc_getAssociatedObject(self, @selector(isRemoteHistoryMessages)) boolValue];
}


#pragma mark - Loading local chat history

- (void)loadHistoryAfterPullToRefresh:(UIRefreshControl *)sender
{
    [self showMoreMessagesFromHistory];
}

- (void)showMoreMessagesFromHistory
{
    if (self.messages.visibleStartIndex > 0)
    {
        [self loadMessagesFromLocalHistory:countToLoad];
        [refreshControl endRefreshing];
    }
    else
    {
        [self loadMessagesRemoteHistory:countToLoad completionHandler: ^{[refreshControl endRefreshing];}];
    }
}

/*
 * Loads messagesCount messages from local history history above currently visible message.
 */
- (void)loadMessagesFromLocalHistory:(NSUInteger)messagesCount
{
    id<MessageObject> oldTopMessage = [self getTopMessage];
    [self performMessagesUpdates:^{
        NSInteger newVisibleStartIndex = self.messages.visibleStartIndex - messagesCount;
        newVisibleStartIndex = newVisibleStartIndex >= 0 ? newVisibleStartIndex : 0;
        self.messages.visibleStartIndex = (NSUInteger)newVisibleStartIndex;
    } updatesCompletion:^(NSArray<NSIndexPath *> *newIndexPaths, BOOL showNewMessagesButton, void (^updatesCompletionCompletion)()) {
        [self addNewRowsForIndexPaths:newIndexPaths
                             animated:NO
                    andScrollToBottom:NO
                        oldTopMessage:oldTopMessage
                    completionHandler:updatesCompletionCompletion];
    }];
}

/*
 * Note: Methods currently doesn't support updates which resulting in removing rows.
 * Takes updates block in which you should perform updates with .messages property of controller.
 * After sending reads, adding separators and building messages, completion block will be called.
 * Index paths for new messages and whether or not you should draw "You have new messages button" are parameters for
 * completion block.
 * Note: it's possible that new index paths, doesn't correspond to messages you added. It happens
 * when added messages are located above .messages.visibleStartIndex.
 */
-(void)performMessagesUpdates:(void (^_Nullable)())updates
            updatesCompletion:(void (^_Nonnull)(NSArray<NSIndexPath *> *newIndexPaths, BOOL showNewMessagesButton, void (^updatesCompletionCompletion)()))completion
{
    NSArray *currentlyVisibleMessages = [self.messages.visibleMessages copy];

    if (updates) updates();

    NSMutableArray *newVisibleMessages = [NSMutableArray arrayWithArray:self.messages.visibleMessages];
    [newVisibleMessages removeFirstOccurrenceOfObjectsInArray:currentlyVisibleMessages];

    NSArray *addedVisibleMessages = [newVisibleMessages copy];

    NSSet *messagesToInsertSeparatorsBefore = [NSSet set];

    /*
     * First we iterate through addedVisibleMessages to add separators if it's necessary.
     */

    for (NSUInteger index = 0; index < [addedVisibleMessages count]; index++) {
        id <MessageObject> message = addedVisibleMessages[index];
        NSIndexPath *messageIndexPath = [self indexPathForMessage:message];
        if (messageIndexPath) {
            if (messageIndexPath.row == 0 && [self.messages.allMessages indexOfObject:message] == 0)
            {
                messagesToInsertSeparatorsBefore = [messagesToInsertSeparatorsBefore setByAddingObject:message];
            }
            else if (messageIndexPath.row > 0)
            {
                id <MessageObject> previousMessage = self.messages.visibleMessages[messageIndexPath.row - 1];
                if (isSeparatorNeededBetweenMessages(previousMessage, message))
                    messagesToInsertSeparatorsBefore = [messagesToInsertSeparatorsBefore setByAddingObject:message];
            }

            if (messageIndexPath.row < [self.messages.visibleMessages count] - 1) {
                id <MessageObject> nextMessage = self.messages.visibleMessages[messageIndexPath.row + 1];
                if (isSeparatorNeededBetweenMessages(message, nextMessage))
                    messagesToInsertSeparatorsBefore = [messagesToInsertSeparatorsBefore setByAddingObject:nextMessage];
            }
        }
    }

    if ([messagesToInsertSeparatorsBefore count]) {
        NSArray *separators = @[];
        for (Message *msg in messagesToInsertSeparatorsBefore)
            separators = [separators arrayByAddingObject:[self createSeparatorModelBeforeMessage:msg]];
        [self.messages addMessages:separators];
    }

    /*
     * Then we again find addedVisibleMessages. And iterate through them to do all operation we need to do.
     */

    newVisibleMessages = [NSMutableArray arrayWithArray:self.messages.visibleMessages];
    [newVisibleMessages removeFirstOccurrenceOfObjectsInArray:currentlyVisibleMessages];

    addedVisibleMessages = [newVisibleMessages copy];

    __block BOOL showNewMessageButton = NO;
    __block NSArray *newIndexPaths = @[];
    __block Message *lastUnreadMessage;

    for (NSUInteger index = 0; index < [addedVisibleMessages count]; index++) {
        id <MessageObject> message = addedVisibleMessages[index];

        if (isValidForSendingRead(message) && [message.packetID integerValue] > [lastUnreadMessage.packetID integerValue])
            lastUnreadMessage = message;
        [self changeMessageLocalStatusToReadIfNeeded:message];

        [self buildMessage:message];
        NSIndexPath *messageIndexPath = [self indexPathForMessage:message];
        if (messageIndexPath)
            newIndexPaths = [newIndexPaths arrayByAddingObject:messageIndexPath];
    }

    if (lastUnreadMessage)
        [self sendReadForMessage:lastUnreadMessage];

    completion(newIndexPaths, showNewMessageButton, ^{
    });
}

/*
 * Loads messagesCount messages from remote history above currently visible message.
 */
- (void)loadMessagesRemoteHistory:(NSUInteger)messagesCount completionHandler:(void (^_Nullable)())completionHandler
{
    Message * topMessage = [self getTopMessage];
    [[ServerFacade sharedInstance] loadHistoryOfChat:self.historyDialog
                                startingWithPacketID:topMessage ? [topMessage.packetID integerValue] : 0
                                       messagesCount:messagesCount
                                       parseMessages:NO
                                   completionHandler:^(NSDictionary * response, NSError * error) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           self.isRemoteHistoryMessages = YES;
                                           [[MWCometParser shared] parseHistoryResponse:response isFromHistory:YES];
                                           if (completionHandler)
                                               completionHandler();
                                       });
                                   }];
}

- (void)initialMessagesLoadWithCompletionHandler:(void (^_Nullable)())completionHandler
{
    self.hasCompletedInitialLoad = NO;
    NSComparator comparator = ^NSComparisonResult(Message * msg1, Message * msg2){return [msg1.created compare:msg2.created];};

    NSArray * sortedMessages = [[self.historyDialog.messages array]sortedArrayUsingComparator:comparator];

    GapMessage * lastGapMessage;

    for (MessagesGap * gap in [self.historyDialog.gaps allObjects])
    {
        GapMessage * gapMessage = [[GapMessage alloc] initWithGap:gap];
        self.gapMessages = [self.gapMessages arrayByAddingObject:gapMessage];

        if (!lastGapMessage)
            lastGapMessage = gapMessage;
        else if (lastGapMessage.startPacketID < gapMessage.startPacketID)
            lastGapMessage = gapMessage;
    }

    sortedMessages = [sortedMessages arrayByAddingObjectsFromArray: self.gapMessages];

    MessageStorage * storage = [[MessageStorage alloc] initWithOrderComparator:comparator
                                                                      messages:sortedMessages];

    [self performMessagesUpdates:^{
        self.messages = storage;
        NSUInteger count = [self.messages.allMessages count];
        self.messages.visibleStartIndex = (count > countToLoad) ? count - countToLoad : 0;
    } updatesCompletion:^(NSArray<NSIndexPath *> *newIndexPaths, BOOL showNewMessagesButton, void (^updatesCompletionCompletion)()) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.hasCompletedInitialLoad = YES;
            if ([self.messagesToReloadAfterInitialLoad count])
            {
                [self handleMessagesChange:self.messagesToReloadAfterInitialLoad];
                self.messagesToReloadAfterInitialLoad = nil;
            }

            for (Message * message in self.messages.allMessages)
                [self changeMessageLocalStatusToReadIfNeeded:message];

            [SENDER_SHARED_CORE.interfaceUpdater chatsWereChanged:@[self.historyDialog]];

            if ([self.messages.visibleMessages containsObject: lastGapMessage])
            {
                __weak Dialog * weakHistoryDialog = self.historyDialog;

                [self.historyLoader loadHistoryForMessagesGap:lastGapMessage.gap completionHandler:^(BOOL success) {
                    if (success)
                    {
                        [weakHistoryDialog removeGapsObject:[lastGapMessage gap]];
                        [[SenderCore sharedCore].interfaceUpdater chatsWereChanged:@[weakHistoryDialog]];
                    }
                }];
            }

            [UIView performWithoutAnimation:^{
                [self.tableView reloadData];
                [self tableViewScrollToBottomAnimated:NO];
            }];
            if (completionHandler) completionHandler();
            updatesCompletionCompletion();
        });
    }];
}

-(dispatch_queue_t)chatUpdateQueue
{
    return dispatch_queue_create("com.MiddleWare.SENDER.ChatUpdate", DISPATCH_QUEUE_SERIAL);
}

#pragma mark MessagesChangesHandler

-(void)handleMessagesChange:(NSArray<Message *> *)messages
{
    if (!self.hasCompletedInitialLoad)
    {
        @synchronized (self) {
            self.messagesToReloadAfterInitialLoad = self.messagesToReloadAfterInitialLoad ?: @[];
            self.messagesToReloadAfterInitialLoad = [self.messagesToReloadAfterInitialLoad arrayByAddingObjectsFromArray:messages];
        }
    }
    else
    {
        if ([self.updateTimer isValid])
        {
            LLog(@"Added messages to update: %@", messages);
            self.pendingNewMessages = [self.pendingNewMessages arrayByAddingObjectsFromArray:messages];
        }
        else
        {
            self.pendingNewMessages = messages;
            NSBlockOperation * updateBLock = [NSBlockOperation blockOperationWithBlock:^{
                LLog(@"Starting updating messages: %@", self.pendingNewMessages);
                [self startUpdatingTableWithMessages:[self.pendingNewMessages copy]];
            }];
            self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                target:updateBLock
                                                              selector:@selector(main)
                                                              userInfo:nil
                                                               repeats:NO];
        };
    }
}

-(void)startUpdatingTableWithMessages:(NSArray<id<MessageObject>>*)messages
{
    NSArray *updatedMessages = @[];
    NSArray *newMessages = @[];

    for (NSUInteger index = 0; index < [messages count]; index++)
    {
        id<MessageObject> message = messages[index];

        if ([message.dialog.chatID isEqualToString:self.historyDialog.chatID])
        {
            if ([self.messages.allMessages containsObject:message] ||
                    [[self.messages.allMessages valueForKey:@"moId"] containsObject:message.moId] ||
                    [[newMessages valueForKey:@"moId"]containsObject:message.moId] ||
                    [newMessages containsObject:message])
                updatedMessages = [updatedMessages arrayByAddingObject:message];
            else
                newMessages = [newMessages arrayByAddingObject:message];
        }
    }

    void (^updateRowsBlock)() = ^void() {
        [self performMessagesUpdates:nil
                   updatesCompletion:^(NSArray<NSIndexPath *> *newIndexPaths, BOOL showNewMessagesButton, void (^updatesCompletionCompletion)()) {
                       dispatch_async(dispatch_get_main_queue(), ^{
                           if ([updatedMessages count]) [self updateViewForMessages:updatedMessages];
                           updatesCompletionCompletion();
                       });
                   }];
    };

    if ([newMessages count])
        [self addMessages:newMessages completionHandler:updateRowsBlock];
    else
        updateRowsBlock();
}

/*
 * Must be called on main thread only!
 */
-(void)updateViewForMessages:(NSArray<Message *> *)messages
{
    NSArray * updatedIndexPaths = @[];
    for (Message * message in messages)
    {
        [self buildMessage:message];
        NSIndexPath * messageIndexPath = [self indexPathForMessage:message];
        if (messageIndexPath && ![updatedIndexPaths containsObject:messageIndexPath])
            updatedIndexPaths = [updatedIndexPaths arrayByAddingObject:messageIndexPath];
    }

    if ([updatedIndexPaths count])
    {
        @try {
            [UIView animateWithDuration:0.1 animations:^{
                LLog(@"Now rows: %lu", (unsigned long) [self.tableView numberOfRowsInSection:0]);
                LLog(@"Messages in array: %lu", (unsigned long) [self.messages.visibleMessages count]);
                LLog(@"Updating rows at paths: %@", updatedIndexPaths);
                [self.tableView reloadRowsAtIndexPaths:updatedIndexPaths
                                      withRowAnimation:UITableViewRowAnimationNone];
            }];
        } @catch (NSException *exception) {
            NSLog(@"%@", exception);
            /*
             * If exception is "missing cell for newly visible row...", it's unknown(yet?) iOS 10 beta bug.
             * https://forums.developer.apple.com/thread/49676
             */
        }
    }
}

/*
 * This method adds messages to .messages (e.g. viewModel).
 */
-(void)addMessages:(NSArray<Message *> *)messages completionHandler:(void (^_Nullable)())completionHandler
{
    id<MessageObject> oldTopMessage = [self getTopMessage];
    BOOL shouldScrollToBottom = [self isLastCellVisible];

    if (self.writtenOwnerMessage && [messages containsObject:self.writtenOwnerMessage])
        shouldScrollToBottom = YES;

    NSIndexPath * pathOfOldMessageWithStatus;
    Message * oldLastMessage = [self.messages.visibleMessages lastObject];
    NSIndexPath * oldLastMessagePath = [self indexPathForMessage:oldLastMessage];
    if ([self isStatusVisibleForMessage:oldLastMessage atIndexPath:oldLastMessagePath])
        pathOfOldMessageWithStatus = oldLastMessagePath;

    [self performMessagesUpdates:^{
        [self.messages addMessages:messages];
    } updatesCompletion:^(NSArray<NSIndexPath *> *newIndexPaths, BOOL showNewMessagesButton, void (^updatesCompletionCompletion)()) {
        [self addNewRowsForIndexPaths:newIndexPaths
                             animated:!self.isRemoteHistoryMessages
                    andScrollToBottom:shouldScrollToBottom
                        oldTopMessage:oldTopMessage
                    completionHandler:^{
                        self.isRemoteHistoryMessages = NO;
                        if (shouldScrollToBottom)
                        {
                            [self tableViewScrollToBottomAnimated:YES];
                            [self fixScrollToBottomButton];
                        }

                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (pathOfOldMessageWithStatus)
                                [self updateViewForMessages:@[self.messages.visibleMessages[pathOfOldMessageWithStatus.row]]];

                            if (completionHandler)
                                completionHandler();

                            updatesCompletionCompletion();
                        });
                    }];
    }];
}

- (void)addNewRowsForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
                       animated:(BOOL)animated
              andScrollToBottom:(BOOL)flag
                  oldTopMessage:(id<MessageObject>)oldTopMessage
              completionHandler:(void (^_Nullable)())completionHandler
{
    if ([indexPaths count])
    {
        [CATransaction begin];
        [CATransaction setCompletionBlock:completionHandler];

        [UIView animateWithDuration:0.1 animations:^{
            [self.tableView performUpdates:^{
                CGPoint oldContentOffset = self.tableView.contentOffset;

                LLog(@"Now rows: %lu", (unsigned long) [self.tableView numberOfRowsInSection:0]);
                LLog(@"Messages in array: %lu", (unsigned long) [self.messages.visibleMessages count]);
                LLog(@"Adding rows: %@", indexPaths);
                [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];

                NSIndexPath *oldTopMessagePath = [self indexPathForMessage:oldTopMessage];
                CGPoint newContentOffset = oldContentOffset;
                if (!flag)
                {
                    CGFloat contentHeightChange = 0.0f;
                    for (NSIndexPath *indexPath in indexPaths) {
                        BOOL countRow = indexPath.row < oldTopMessagePath.row;
                        if (indexPath.section == oldTopMessagePath.section && countRow)
                            contentHeightChange += [self tableView:self.tableView heightForRowAtIndexPath:indexPath];
                    }
                    newContentOffset.y += contentHeightChange;
                    if (!CGPointEqualToPoint(oldContentOffset, newContentOffset))
                        [self.tableView setContentOffset:newContentOffset];
                }
            }];
            [self fixScrollToBottomButton];
        }];

        [CATransaction commit];
    }
    else
    {
        if (completionHandler)
            completionHandler();
    }
}

#pragma mark - ChatChangesHandler

-(void)handleChatsChange:(NSArray<Dialog *> *)chats
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (Dialog * chat in chats)
        {
            if ([chat.chatID isEqualToString:self.historyDialog.chatID])
            {
                [self updateNavigationBar];
                BOOL needUpdateBackground = [self needsUpdateChatBackgroundWithNewImageURL:chat.imageURL];
                if (needUpdateBackground)
                    [self updateChatBackground];

                [self updateActiveStateOfChat];

                BOOL shouldReloadKeys = [self needsReloadEncryptedMessagesWithNewGroupChatKey:chat.encryptionKey
                                                                                     keysData:chat.oldGroupKeysData];
                if (shouldReloadKeys)
                {
                    self.historyDialog.oldGroupKeysData = chat.oldGroupKeysData;
                    self.historyDialog.encryptionKey = chat.encryptionKey;
                    [self cacheMainGroupChatKey:chat.encryptionKey keysData:chat.oldGroupKeysData];

                    NSPredicate * encryptedMessagePredicate = [NSPredicate predicateWithBlock:^BOOL(id<MessageObject> msgObject, NSDictionary * d) {
                        return [msgObject isKindOfClass:[Message class]] && [[(Message *)msgObject encrypted] boolValue];
                    }];
                    NSArray * encryptedMessages = [self.messages.visibleMessages filteredArrayUsingPredicate:encryptedMessagePredicate];
                    [self handleMessagesChange:encryptedMessages];
                }

                NSArray * currentGaps = [self.gapMessages valueForKey:@"gap"];
                NSArray * newGaps = [[self.historyDialog gaps] allObjects];

                NSMutableArray * currentGapsMutable = [currentGaps mutableCopy];
                [currentGapsMutable removeObjectsInArray:newGaps];
                NSArray * deletedGaps = [currentGapsMutable copy];

                NSMutableArray * newGapsMutable = [newGaps mutableCopy];
                [newGapsMutable removeObjectsInArray:currentGaps];
                NSArray * addedGaps = [newGapsMutable copy];

                NSArray * deletedGapsMessages = [self.gapMessages filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(GapMessage * gapMessage, NSDictionary*bindings) {
                    return [deletedGaps containsObject:gapMessage.gap];
                }]];

                for (GapMessage * gapMessage in deletedGapsMessages)
                    gapMessage.isActive = NO;

                NSArray * addedGapsMessages = @[];
                for (MessagesGap * gap in addedGaps)
                {
                    GapMessage * gapMessage = [[GapMessage alloc] initWithGap:gap];
                    addedGapsMessages = [addedGapsMessages arrayByAddingObject:gapMessage];
                }
                self.gapMessages = [self.gapMessages arrayByAddingObjectsFromArray:addedGapsMessages];

                [self handleMessagesChange:[addedGapsMessages arrayByAddingObjectsFromArray:deletedGapsMessages]];

                if ([self needsReloadSendBarWithChat:chat])
                    [self addSendBarToView];
            }
        }
    });
}

#pragma mark TypingChangesHandler

-(void)handleTypingStartForContacts:(NSArray<Contact *> *)contacts inChat:(NSString * _Nonnull)chatID
{
    if ([chatID isEqualToString:self.historyDialog.chatID])
    {
        for (Contact * contact in contacts) {
            if ([[self.historyDialog membersContacts] containsObject:contact])
                [self setUserTypingStatusForContact:contact];
        }
    }
}

- (void)setUserTypingStatusForContact:(Contact *)user
{
    if (!self.typingUsers)
        self.typingUsers = [NSMutableSet set];
    [self.typingUsers addObject:user];

    if (!self.typingIndicatorModel)
        self.typingIndicatorModel = [self createTypingModelForUser:user];

    if (!self.timers)
        self.timers = [NSMutableDictionary dictionary];
    else
        [(NSTimer *)self.timers[user.name] invalidate];

    NSInvocation * removeTypingInvocation = [NSInvocation invocationWithMethodSignature:[[self class]
            instanceMethodSignatureForSelector:@selector(removeTypingUser:)]];
    [removeTypingInvocation setTarget:self];
    [removeTypingInvocation setSelector:@selector(removeTypingUser:)];
    [removeTypingInvocation setArgument:&user atIndex:2];
    self.timers[user.name] = [NSTimer scheduledTimerWithTimeInterval:2.0f invocation:removeTypingInvocation repeats:NO];

    [self reloadTypingSectionWithUpdatesCompletion:^{
        if ([self isLastCellVisible]) [self tableViewScrollToBottomAnimated:YES];
    }];
}

- (void)removeTypingUser:(Contact *)user
{
    [self.typingUsers removeObject:user];
    [self removeUserTypingStatus:user];
}

- (void)removeUserTypingStatus:(Contact *)user
{
    if (![[[CoreDataFacade sharedInstance] getOwner].uid isEqualToString:user.userID])
    {
        if (![self.typingUsers count])
        {
            self.typingIndicatorModel = nil;
            [self reloadTypingSectionWithUpdatesCompletion:^{ self.timers = nil; }];
        }
        else
        {
            [self updateTypingModelTitle:self.typingIndicatorModel withTypingUsers:[self.typingUsers copy]];
        }
    }
}

- (void)reloadTypingSectionWithUpdatesCompletion:(void (^_Nullable)())completion
{
    [self performMessagesUpdates:^{
    } updatesCompletion:^(NSArray<NSIndexPath *> *newIndexPaths, BOOL showNewMessagesButton, void (^updatesCompletionCompletion)()) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
        if (completion)
            completion();

        updatesCompletionCompletion();
    }];
}

#pragma mark - Other

-(void)changeMessageLocalStatusToReadIfNeeded:(Message *)message
{
    if (isValidForSendingRead(message))
        message.deliver = @"read";
}

- (BOOL)isLastCellVisible
{
    NSPredicate * visibleMessagesPredicate = [NSPredicate predicateWithBlock:^BOOL(id<MessageObject> message, NSDictionary *bindings) {
        return ![message isKindOfClass:[GapMessage class]] || [(GapMessage *)message isActive];
    }];

    id<MessageObject> lastMessage = [[self.messages.visibleMessages filteredArrayUsingPredicate:visibleMessagesPredicate] lastObject];
    NSIndexPath * lastMessageIndexPath = [self indexPathForMessage:lastMessage];
    NSIndexPath * typingIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    NSArray * visibleIndexPaths = [self.tableView indexPathsForVisibleRows];

    return [visibleIndexPaths containsObject:lastMessageIndexPath] || [visibleIndexPaths containsObject:typingIndexPath];
}

@end
