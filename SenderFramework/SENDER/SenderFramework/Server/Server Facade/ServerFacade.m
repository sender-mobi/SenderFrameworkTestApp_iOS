
//
//  ServerFacade.m
//  SENDER
//
//  Created by Eugene Gilko on 10/2/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ServerFacade.h"
#import "SenderRequestBuilder.h"
#import "SenderNotifications.h"
#import "AddressBook.h"
#import "AudioRecorder.h"
#import "FileManager.h"
#import "ParamsFacade.h"
#import "ChatViewController.h"
#import "Contact.h"
#import "SecGenerator.h"
#import "CometController.h"
#import "ECCWorker.h"
#import "DialogSetting.h"
#import "FileOperator.h"
#import <SenderFramework/SenderConstants.h>
#import <SenderFramework/SecGenerator.h>
#import "UDServer.h"
#import "Settings.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "MessagesGap.h"
#import "Owner.h"
#import "Dialog.h"
#import "ChatMember+CoreDataProperties.h"

static ServerFacade * serverRequest;

@interface ServerFacade()
{
    BOOL auth;
    UDServer * server;
}

@end

@implementation ServerFacade

+ (ServerFacade *)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        serverRequest = [[ServerFacade alloc] init];
    });
    
    return serverRequest;
}

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        auth = YES;
        server = [[UDServer alloc] init];
    }
    return self;
}

- (BOOL)isWwan
{
    return [[CometController sharedInstance] isWWAN];
}

- (void)registrationRequestWithUDID:(NSString *)udid
                        developerID:(NSString *)developerID
               additionalParameters:(NSDictionary *)adParams
                         completion:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];

    postData[@"udid"] = udid;
    postData[@"developerId"] = developerID;
    postData[@"pushToken"] = [SenderCore sharedCore].pushToken ?: @"";
    postData[@"devType"] = @"phone";
    postData[@"devModel"] = [SENDER_SHARED_CORE machineName];
    postData[@"devOS"] = @"ios";
    postData[@"versionOS"] = [[UIDevice currentDevice] systemVersion];
    postData[@"clientType"] = @"ios";
    postData[@"clientVersion"] = SENDER_SHARED_CORE.clientVersion;
    postData[@"language"] = [[NSLocale preferredLanguages] objectAtIndex:0];

    for (NSString * key in [adParams allKeys]) {
        if (postData[key] == nil)
            postData[key] = adParams[key];
        else
            NSAssert(postData[key] == nil, ([NSString stringWithFormat:@"You cannot use value with key '%@' in additional registration params.", key]));
    }

    if (completionHandler)
        completionHandler = [completionHandler copy];

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kRegPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                            if (completionHandler)
                                                completionHandler(response, error);
                                    }];
}

- (void)unlinkRequestWithUDID:(NSString *)udid
                  developerID:(NSString *)developerID
         additionalParameters:(NSDictionary *)adParams
                   completion:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];

    postData[@"udid"] = udid;
    postData[@"developerId"] = developerID;
    postData[@"pushToken"] = @"";
    postData[@"voipToken"] = @"";
    postData[@"devType"] = @"phone";
    postData[@"devModel"] = [SENDER_SHARED_CORE machineName];
    postData[@"devOS"] = @"ios";
    postData[@"versionOS"] = [[UIDevice currentDevice] systemVersion];
    postData[@"clientType"] = @"ios";
    postData[@"clientVersion"] = SENDER_SHARED_CORE.clientVersion;
    postData[@"language"] = [[NSLocale preferredLanguages] objectAtIndex:0];

    for (NSString * key in [adParams allKeys]) {
        if (postData[key] == nil)
            postData[key] = adParams[key];
        else
            NSAssert(NO, ([NSString stringWithFormat:@"You cannot use value with key '%@' in additional registration params.", key]));
    }

    if (completionHandler)
        completionHandler = [completionHandler copy];

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kRegPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                            if (completionHandler)
                                                completionHandler(response, error);
                                    }];
}

- (void)setVersionToServer
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];

    postData[@"devType"] = @"phone";
    postData[@"devModel"] = [SENDER_SHARED_CORE machineName];
    postData[@"devOS"] = @"ios";
    postData[@"versionOS"] = [[UIDevice currentDevice] systemVersion];
    postData[@"clientType"] = @"ios";
    postData[@"clientVersion"] = SENDER_SHARED_CORE.clientVersion;
    postData[@"language"] = [[NSLocale preferredLanguages] objectAtIndex:0];
    postData[@"companyId"] = @"";

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:@"version_set"
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                    }];
}
- (void)getCompanyOperatorsList:(NSString *)companyId completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"companyId"] = companyId;
    
    if (completionHandler) {
        completionHandler = [completionHandler copy];
    }

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kGetCompanyOperatorsPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                        {
                                            if (completionHandler)
                                            {
                                                completionHandler(response, error);
                                            }
                                        }
                                    }];
}

#pragma mark Update CONTACT API

- (void)updateContact:(NSDictionary *)fields
       requestHandler:(SenderRequestCompletionHandler)completionHandler
{
    [[CometController sharedInstance] addMessageToQueue:@{@"cts": @[fields]}
                                             withUrlPath:kSetContactPath
                                    withCompletionHolder:completionHandler];
}

- (void)addContactWithName:(NSString *)name phone:(NSString *)phone requestHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = [[CoreDataFacade sharedInstance] getOwner].senderChatId;
    postData[@"formId"] = [NSString string];
    postData[@"robotId"] = @"contactSet";
    postData[@"companyId"] = @"sender";
    
    NSMutableDictionary * contactRecord = [NSMutableDictionary dictionary];
    if (name)
        contactRecord[@"name"] = name;
    
    if (phone)
        contactRecord[@"contactItemList"] = @[[NSDictionary dictionaryWithObjectsAndKeys:phone, @"valueRaw", @"phone", @"type", nil]];
    
    postData[@"model"] = [NSDictionary dictionaryWithObject:contactRecord forKey:@"contactRecord"];

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (error)
                                        {
                                            // repeat
                                        }
                                        if (completionHandler)
                                            completionHandler(response, error);
                                    }];
}

// END OF Upadate CONTACT API ================================================================================

- (void)sendForm:(NSDictionary *)formData
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    [postData addEntriesFromDictionary:formData];

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                        {
                                        }
                                    }];
}

- (void)sendLogToServer:(NSDictionary *)data requestHandler:(SenderRequestCompletionHandler)completionHandler
{
//    return;
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * model = [[NSMutableDictionary alloc] init];

    model[@"connection"] = [NSString stringWithFormat:@"%i", [[CometController sharedInstance] serverAvailable]];
    model[@"activeChat"] = [SenderCore sharedCore].activeChatsCoordinator.activeChatID ?: @"";
    model[@"lastBatchID"] = [[CometController sharedInstance] lastBatchID];
    NSString * connectionType = ([self isWwan]) ? @"mob" : @"wifi";
    model[@"con"] = connectionType;
    model[@"eventTime"] = [NSString stringWithFormat:@"%@", [NSDate date]];
    model[@"eventData"] = data;
    
    postData[@"chatId"] = [[CoreDataFacade sharedInstance] getOwner].senderChatId;
    postData[@"model"] = model;
    postData[@"class"] = @".ioslog.sender";


    [[CometController sharedInstance] createDirectRequestWithPath:@"ioslog" postData:[postData copy] withCompletionHolder:nil];
}

- (void)sendCrashLog:(NSDictionary *)crashLog
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * model = [[NSMutableDictionary alloc] init];
    
    NSString * connectionType = ([self isWwan]) ? @"mob":@"wifi";
    NSString * postString = [NSString stringWithFormat:@"%@",crashLog[@"post"]];
    [model setObject:connectionType forKey:@"con"];
    [model setObject:crashLog[@"get"] forKey:@"get"];
    [model setObject:postString forKey:@"post"];
    [model setObject:crashLog[@"data"] forKey:@"data"];
    
    postData[@"chatId"] = [[CoreDataFacade sharedInstance] getOwner].senderChatId;
    postData[@"model"] = model;
    postData[@"class"] = @".crash.sender";

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:nil
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                        {

                                        }
                                    }];
}

- (void)sendMessage:(Message *)message
         withDialog:(Dialog *)messageDialog
  completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    if (message)
    {
        NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
        postData[@"chatId"] = message.chat;
        postData[@"class"] = @"text";
        if (message.linkID.length) {
            postData[@"linkId"] = message.linkID;
        }
        
        NSString * encryptedString = nil;
        
        NSMutableDictionary * modelData = [[NSMutableDictionary alloc] init];
        
        if ([message.encrypted boolValue] && [[SenderCore sharedCore] isBitcoinEnabled])
        {
            if ([messageDialog chatType] == ChatTypeP2P) {
                modelData[@"pkey"] = [[[[CoreDataFacade sharedInstance] getOwner] getMainWallet:nil] base58PublicKey];
                encryptedString = [[ECCWorker sharedWorker] eciesEncriptMEssage:message.textMessage
                                                                 withPubKeyData:messageDialog.p2pBTCKeyData
                                                                      shortkEkm:YES
                                                                      usePubKey:NO];
            }
            else if ([messageDialog chatType] == ChatTypeGroup) {
                if (messageDialog.encryptionKey)
                    encryptedString = [[SecGenerator sharedInstance] encryptMessage:message.textMessage
                                                                      withDialogKey:messageDialog.encryptionKey];
            }
        }
        
        if (encryptedString) {
            modelData[@"encrypted"] = @YES;
            modelData[@"text"] = encryptedString;
            
            message.data = [[ParamsFacade sharedInstance] NSDataFromNSDictionary:@{@"text":encryptedString,@"pkey":@""}];
        }
        else {
            modelData[@"encrypted"] = @NO;
            modelData[@"text"] = message.textMessage;
        }
        
        postData[@"model"] = modelData;
        
        NSString * tempId = message.moId;

        [[CometController sharedInstance] addMessageToQueue:postData
                                                 withUrlPath:kSendPath
                                        withCompletionHolder:^(NSDictionary *response, NSError *error)
                                        {
                                            NSString *crCode;
                                            id cr = response[@"cr"];
                                            if ([cr isKindOfClass:[NSArray class]] && [[response[@"cr"] firstObject] isKindOfClass:[NSDictionary class]])
                                                crCode = [response[@"cr"] firstObject][@"code"];
                                            if (!error && ![crCode isEqual:@13])
                                            {
                                                messageDialog.lastMessageStatus = MessageStatusSent;
                                                [self reSetMessageStatusAndMoId:message fromResponse:response[@"cr"][0] tempId:tempId];
                                            }
                                            completionHandler(response, error);
                                        }];
        [SENDER_SHARED_CORE.interfaceUpdater messagesWereChanged:@[message]];
    }
}

- (void)sendStickerMessage:(Message *)message
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = message.chat;
    postData[@"formId"] = @"";
    postData[@"robotId"] = @"sticker";
    postData[@"companyId"] = @"sender";
    
    NSDictionary * msgText = [[ParamsFacade sharedInstance] dictionaryFromNSData:message.data];
    postData[@"model"] = [NSDictionary dictionaryWithObject:msgText[@"id"] forKey:@"id"];
    NSString * tempId = message.moId;

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                        {
                                            [self reSetMessageStatusAndMoId:message fromResponse:response[@"cr"][0] tempId:tempId];
                                        }
                                    }];
    [SENDER_SHARED_CORE.interfaceUpdater messagesWereChanged:@[message]];
}

- (void)sendVibroMessage:(Message *)message
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = message.chat;
    postData[@"formId"] = @"";
    postData[@"robotId"] = @"vibro";
    postData[@"companyId"] = @"sender";
    
    NSDictionary * msgText = [[ParamsFacade sharedInstance] dictionaryFromNSData:message.data];
    postData[@"model"] = [NSDictionary dictionaryWithObject:msgText[@"oper"] forKey:@"oper"];
    NSString * tempId = message.moId;

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                        {
                                            [self reSetMessageStatusAndMoId:message fromResponse:response[@"cr"][0] tempId:tempId];
                                        }
                                    }];
    [SENDER_SHARED_CORE.interfaceUpdater messagesWereChanged:@[message]];
}

- (void)reSetMessageStatusAndMoId:(Message *)message fromResponse:(NSDictionary *)response tempId:(NSString *)tempId
{
    if (!response) {
        return;
    }
    message.deliver = @"sent";
    
    if ([message.linkID isEqualToString:@""])
        message.linkID = [response[@"packetId"] description];

    NSString * packetID = [response[@"packetId"] description];
    NSString * messageMoID = [NSString stringWithFormat:@"%@<<%@", message.chat, message.linkID];
    
    NSDate * creation = nil;
    
    if ([response[@"time"] doubleValue] > 0) {
        NSTimeInterval timeInterval = (NSTimeInterval)[response[@"time"] doubleValue] / 1000;
        creation = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    }

    [[CoreDataFacade sharedInstance] setNewPacketID:packetID
                                               moID:messageMoID
                                    andCreationTime:creation
                                         forMessage:message];
    [SENDER_SHARED_CORE.interfaceUpdater messagesWereChanged:@[message]];
}

- (void)sayReadStatus:(Message *)message
{
    @try {
        NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
        
        postData[@"class"] = @".read.sender";
        postData[@"chatId"] = message.chat;
        if (![[DBSettings sendRead] boolValue])
            postData[@"hide"] = @YES;
        if (message.packetID && [message.packetID integerValue] >0 && message.fromId) {
            NSMutableDictionary * model = [[NSMutableDictionary alloc] init];
            model[@"packetId"] = message.packetID;
            model[@"from"] = message.fromId;
            if (![[DBSettings sendRead] boolValue])
                model[@"hide"] = @YES;
            postData[@"model"] = [model copy];
        }
        else {
            return;
        }

        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive || [[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive) {
            [[CometController sharedInstance] addMessageToQueue:postData
                                                     withUrlPath:kSendPath
                                            withCompletionHolder:nil
            ];
        }
        else if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
            [[CometController sharedInstance] collectSendRequest:postData withUrlPath:kSendPath withCompletionHolder:nil];
        }
    }
    @catch (NSException *exception) {
      
    }
    @finally {
      
    }
}

- (void)loadCompanyCardForP2PChat:(Dialog *)p2pChat completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSString * companyID = userIDFromChatID(p2pChat.chatID);
    if (!companyID)
    {
        NSError * error = [[NSError alloc] initWithDomain:@"Wrong chat ID" code:666 userInfo:nil];
        if (completionHandler) completionHandler(nil, error);
    }

    NSDictionary * formDialog = @{@"formId":@"", @"robotId":@"contact",@"companyId":companyID};

    [[ServerFacade sharedInstance] callRobotWithParameters:formDialog
                                                    chatID:p2pChat.chatID
                                                 withModel:@{@"stub": @"true"}
                                            requestHandler:completionHandler];
}

- (void)callRobotWithParameters:(NSDictionary *)parameters
                         chatID:(NSString *)chatID
                      withModel:(NSDictionary *)model
                 requestHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] initWithDictionary:parameters];
    postData[@"chatId"] = chatID;
    postData[@"model"] = model ?: @{@"stub": @"true"};
   
    if (completionHandler) completionHandler = [completionHandler copy];

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error) {
                                        if (completionHandler && response)
                                            completionHandler(response, error);
                                    }];
}

- (void)checkOnlineStatusForUserIDs:(NSArray<NSString *> *)userId
{
    if (!userId) return;
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = [[CoreDataFacade sharedInstance] getOwner].senderChatId;
    postData[@"model"] = [NSDictionary dictionaryWithObject:userId forKey:@"userId"];
    postData[@"formId"] = @"";
    postData[@"robotId"] = @"checkUserStatus";
    postData[@"companyId"] = @"sender";

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (error)
                                        {
                                            // repeat
                                        }
                                    }];
}

- (void)setSelfInfo:(NSDictionary *)info withRequestHandler:(SenderRequestCompletionHandler)completionHandler
{
    if (completionHandler) {
        completionHandler = [completionHandler copy];
    }

    [[CometController sharedInstance] addMessageToQueue:info
                                             withUrlPath:kSetSelfInfoPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (completionHandler)
                                            completionHandler(response, error);
                                    }];
}

- (void)crashLogSend:(NSDictionary *)log
{
//    NSMutableDictionary * postData = [NSMutableDictionary dictionaryWithDictionary:log];
//    postData[@"sid"] = [ServerFacade sharedInstance].sid ? [ServerFacade sharedInstance].sid:@"";
//
//    [[CometController sharedInstance] addMesageToQueue:postData
//                                            withUrlPath:@"reg"
//                                   withCompletionHolder:
    
//    [server performConnectionWithPath:@"crash_log" postData:postData completionHandler:^(NSDictionary *response, NSError *error) {
//        if (!error) {
//            // repeat
//        }
//    }];
}

- (void)loadHistoryOfChat:(Dialog *)chat
     startingWithPacketID:(NSInteger)packetID
            messagesCount:(NSUInteger)messagesCount
            parseMessages:(BOOL)parseMessages
        completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    if (!chat.chatID)
    {
        NSError * error = [NSError errorWithDomain:@"Chat has no moId" code:666 userInfo:nil];
        completionHandler(nil, error);
    }
    else
    {
        [self loadHistoryOfChatWithID:chat.chatID
                 startingWithPacketID:packetID
                        messagesCount:messagesCount
                         asGapRemover:!parseMessages
                    completionHandler:completionHandler];
    }
}

- (void)loadHistoryOfChatWithID:(NSString *)chatID
           startingWithPacketID:(NSInteger)packetID
                  messagesCount:(NSUInteger)messagesCount
                   asGapRemover:(BOOL)isRemoveGap
              completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = chatID;
    postData[@"size"] = @(messagesCount);
    if (packetID >= 0)
        postData[@"startId"] = @(packetID);

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kGetHistoryPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {

                                        if (!isRemoveGap)
                                        {
                                            [[MWCometParser shared] parseHistoryResponse:response isFromHistory:YES];
                                        }

                                        if (completionHandler)
                                            completionHandler(response, error);
                                    }
    ];
}

- (void)loadHistoryOfChatWithID:(NSString *)chatID
           startingWithPacketID:(NSInteger)startPacketID
                    endPacketID:(NSInteger)endPacketID
                   asGapRemover:(BOOL)isRemoveGap
              completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = chatID;
    if (startPacketID >= 0)
        postData[@"startId"] = @(startPacketID);
    if (endPacketID >= 0)
        postData[@"endId"] = @(endPacketID);

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kGetHistoryPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {

//                                       if (!isRemoveGap) {
                                        [[MWCometParser shared] parseHistoryResponse:response isFromHistory:YES];


                                        if (completionHandler)
                                            completionHandler(response, error);
                                    }
    ];
}

- (void)getChatHistory:(NSString *)chatID withRequestHandler:(SenderRequestCompletionHandler)completionHandler
{
    [self loadHistoryOfChatWithID:chatID
             startingWithPacketID:nil
                    messagesCount:25
                     asGapRemover:NO
                completionHandler:^(NSDictionary *response, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        Dialog * chat = (Dialog *)[[CoreDataFacade sharedInstance] findFirstObjectWithName:@"Dialog" byProperty:@"chatID" withValue:chatID];
                        chat.needSync = @NO;
                        chat.unreadCount = @0;
                    });
                }
    ];
}

- (void)getVersionInfoWithRequestHandler:(SenderRequestCompletionHandler)completionHandler
{
    [[CometController sharedInstance] addMessageToQueue:[NSDictionary dictionary]
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (completionHandler)
                                        {
                                            completionHandler(response, error);
                                        }
                                    }];
}

- (void)updateSelfInfo:(SenderRequestCompletionHandler)completionHandler
{
    [[CometController sharedInstance] addMessageToQueue:nil
                                             withUrlPath:@"selfinfo_get"
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                        {
                                            [[CoreDataFacade sharedInstance] setOwnerInfo:response[@"selfInfo"]];
                                            if (completionHandler)
                                                completionHandler(response, error);
                                        }
                                    }];
}

- (void)getSelfInfoWithCompletion:(SenderRequestCompletionHandler)completionHandler
{
    [[CometController sharedInstance] addMessageToQueue:nil
                                             withUrlPath:@"selfinfo_get"
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (completionHandler)
                                            completionHandler(response, error);
                                    }];
}

- (void)sendMyToken:(NSString *)token andViopToken:(NSString *)voipToken
{
    if (![ServerFacade sharedInstance].sid)
        return;

    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"token"] = token ?: @"";
    postData[@"voipToken"] = voipToken ?: @"";
    postData[@"apns"] = [SenderCore sharedCore].configuration.apnsString;

    LLog(@"Sending pushToken: %@ voipToken: %@", token, voipToken);
    
    postData[@"alertsound"] = @"sl.caf";
    if ([DBSettings.notificationsSound boolValue]) {
        postData[@"alertsound"] = @"StarWars.waw";
    }

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kTokenPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (error)
                                        {
                                            // repeat
                                        }
                                    }];
}

- (void)sendTypingToChatWithID:(NSString * _Nonnull)chatID
                requestHandler:(SenderRequestCompletionHandler)completionHandler
{
    if ([[CometController sharedInstance] isWWAN] || !chatID)
        return;
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = chatID;

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kTypingPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (error)
                                        {
                                            // repeat
                                        }
                                    }];
}

- (void)addMembers:(NSArray *)members
            toChat:(NSString * _Nonnull)chatID
    requestHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableArray * users = [NSMutableArray arrayWithCapacity:members.count];
    for (NSString * userId in members) {
        NSDictionary * memberInfo = @{@"userId":userId, @"cmd":@"add"};
        [users addObject:memberInfo];
    }

    if (completionHandler) {
        completionHandler = [completionHandler copy];
    }

    [[CometController sharedInstance] addMessageToQueue:@{@"chatId": chatID, @"members": users}
                                             withUrlPath:kChatSetPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (completionHandler)
                                            completionHandler(response, error);
                                    }];
}

- (void)changeChat:(NSString *)chatID
          withName:(NSString*)newName
       description:(NSString *)newDescription
          photoUrl:(NSString *)photoURL
    requestHandler:(SenderRequestCompletionHandler)completionHandler
{
    if (completionHandler)
        completionHandler = [completionHandler copy];

    NSMutableDictionary * model = [[NSMutableDictionary alloc] init];
    model[@"chatId"] = chatID;

    if (newName) model[@"chatName"] = newName;
    if (newDescription) model[@"chatDesc"] = newDescription;
    if (photoURL) model[@"chatPhoto"] = photoURL;
    
    NSDictionary * postData = @{@"formId" : @"",
                                @"robotId" : @"chatSetInfo",
                                @"companyId" : @"sender",
                                @"chatId" : [[CoreDataFacade sharedInstance] getOwner].senderChatId,
                                @"model" : model};

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (completionHandler)
                                            completionHandler(response, error);
                                    }];
}

- (void)leaveChat:(NSString *)chatId completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    if (!chatId) {
        return;
    }
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];

    postData[@"formId"] = @"";
    postData[@"robotId"] = @"leaveChat";
    postData[@"companyId"] = @"sender";
    postData[@"chatId"] = chatId;
    postData[@"model"] = @{};

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (completionHandler)
                                        {
                                            completionHandler(response, error);
                                        }
                                    }];
}

- (void)deleteMembersWithUserIDs:(NSArray<NSString *> *)userIDs
                  fromChatWithID:(NSString *)chatID
                  requestHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableArray * users = [NSMutableArray arrayWithCapacity:userIDs.count];
    for (NSString * userId in userIDs) {
        NSDictionary * memberinfo = @{@"userId":userId, @"cmd":@"del"};
        [users addObject:memberinfo];
    }
    
    if (completionHandler) {
        completionHandler = [completionHandler copy];
    }

    [[CometController sharedInstance] addMessageToQueue:@{@"chatId": chatID, @"members": users}
                                             withUrlPath:kChatSetPath
                                    withCompletionHolder:completionHandler];
}

- (NSDictionary *)getContactInfoByPhone:(NSString *)phone
{
    NSDictionary * result = [[CometController sharedInstance] createSimpleRequest:@{@"phone":phone} withUrlPath:@"get_ct_by_phone"];
    
    if (result.count) {
        return result;
    }
    else {
        return nil;
    }
}

- (void)getChatWithID:(NSString *)chatID requestHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = chatID;

    [[CometController sharedInstance] createDirectRequestWithPath:kGetChatPath
                                                          postData:postData
                                              withCompletionHolder:completionHandler];
}

- (void)globalSearchWithText:(NSString *)text requestHandler:(SenderRequestCompletionHandler)completionHandler
{
    if (!text.length) {
        return;
    }
    
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"t"] = text;
    
    if (completionHandler) {
        completionHandler = [completionHandler copy];
    }

    [[CometController sharedInstance] createDirectRequestWithPath:@"search" postData:postData withCompletionHolder:^(NSDictionary *response, NSError *error)
    {

        if (!error)
        {
            if (completionHandler)
                completionHandler(response, error);
        }
    }];
}


- (void)uploadFileToServer:(NSData *)file
            previewImage:(NSData *)prewFile
            byMessage:(NSDictionary *)message
            requestHandler:(SenderRequestCompletionHandler)completionHandler
{
    if (completionHandler) {
        completionHandler = [completionHandler copy];
    }

    if (!file) {
        NSError * error = [NSError errorWithDomain:@"File data is empty" code:666 userInfo:nil];
        if (completionHandler)
            completionHandler(@{@"status" : @"error"}, error);
    }
    else
    {
        NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
        
        NSString * extension = [message[@"type"] isEqualToString:@"AUDIO"] ? @"mp3" : @"jpg";
        params[@"filetype"] = extension;
        if (message[@"target"])
            params[@"target"] = message[@"target"];

        [server uploadFileWithParams:params postData:file completionHandler:^(NSDictionary *response, NSError *error) {
            if (completionHandler) {
                completionHandler(response, error);
            }
        }];
    }
}

- (void)uploadFileToServer:(NSData *)file previewImage:(NSData *)prewFile byMessage:(NSDictionary *)message
{
    if (!file) {
        return;
    }
    
    NSString * extension = [message[@"type"] isEqualToString:@"AUDIO"] ? @"mp3" : @"jpg";
    NSString * messageId = message[@"moId"];
    
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    params[@"filetype"] = extension;
    if (message[@"target"])
        params[@"target"] = message[@"target"];
    
    [server uploadFileWithParams:params postData:file completionHandler:^(NSDictionary *response, NSError *error) {
        
        if (!error && response[@"url"]) {
            NSString * baseDataURL = response[@"url"];
            if (![messageId isEqualToString:@"0"]) {
                if ([extension isEqualToString:@"mp3"])
                {
                    [self sendFile:baseDataURL prewUrl:nil byMessage:message];
                    [[[AudioRecorder alloc] init] deleteFile];
                    [[CoreDataFacade sharedInstance] setUploadUrl:response[@"url"] toMessage:messageId];
                    [[FileManager sharedFileManager] saveData:file byServerUrl:response[@"url"]];
                }
                else
                {
                    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
                    params[@"filetype"] = @"jpg";
                    [server uploadFileWithParams:params postData:prewFile completionHandler:^(NSDictionary *response, NSError *error) {
                         [self sendFile:baseDataURL prewUrl:response[@"url"] byMessage:message];
                    }];
                }
            }
        }
    }];
}

- (void)sendFile:(NSString *)url prewUrl:(NSString *)prevUrl byMessage:(NSDictionary *)messageDict
{
    NSString * messageId = messageDict[@"moId"];
    
    Message * message = [[CoreDataFacade sharedInstance] messageById:messageId];
    
    if (!message || !message.chat)
        return;
    
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = message.chat;
    
    NSMutableDictionary * model = [[NSMutableDictionary alloc] init];
    if (prevUrl) {
        [model setObject:prevUrl forKey:@"preview"];
    }
    [model setObject:message.file.type forKey:@"type"];
    [model setObject:url forKey:@"url"];
    
    if ([message.file.type isEqualToString:@"mp3"]) {
        [model setObject:[FileManager sharedFileManager].lastRecorderAudioDuration forKey:@"length"];
    }
    else if ([message.file.type isEqualToString:@"jpg"]) {
        [model setObject:messageDict[@"imageWidthS"] forKey:@"w"];
        [model setObject:messageDict[@"imageHeightS"] forKey:@"h"];
    }
    
    postData[@"model"] = model;
    postData[@"formId"] = message.formId;
    postData[@"companyId"] = message.companyId;
    postData[@"robotId"] = message.robotId;

    NSString  * tempID = message.moId;

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                        {
                                            [self reSetMessageStatusAndMoId:message fromResponse:response[@"cr"][0] tempId:tempID];
                                        }
                                    }];
    [SENDER_SHARED_CORE.interfaceUpdater messagesWereChanged:@[message]];
}

- (void)downloadFileWithBlock:(void(^)(NSData * data))block forUrl:(NSString *)urlString
{
    [server downloadFileWithUrl:urlString completionHandler:^(NSDictionary *response, NSError *error) {
        if (response) {
            NSData * fileData = response[@"fileData"];
            if (block) {
                block(fileData);
            }
        }
    }];
}

- (void)showLocalNotification:(Message *)message name:(NSString *)name
{
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    
    localNotification.alertAction = [message.type isEqualToString:@"form"] ? @"Form" : @"text";
    localNotification.alertBody = [NSString stringWithFormat:@"From: %@ : %@",name, message.lasttext];
    
    localNotification.userInfo = [NSDictionary dictionaryWithObject:message.chat forKey:@"chat"];
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

- (void)sendMyLocation:(NSDictionary *)locationDict completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    if (DBSettings.location) {
    
        NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
        postData[@"chatId"] = [[CoreDataFacade sharedInstance] getOwner].senderChatId;
        postData[@"formId"] = @"";
        postData[@"robotId"] = @"setDeviceLocation";
        postData[@"companyId"] = @"sender";
        postData[@"model"] = locationDict;
        if (completionHandler) {
            completionHandler = [completionHandler copy];
        }
        [[CometController sharedInstance] addMessageToQueue:postData
                                                 withUrlPath:kSendPath
                                        withCompletionHolder:^(NSDictionary *response, NSError *error)
                                        {
                                            if (completionHandler)
                                            {
                                                completionHandler(response, error);
                                            }
                                        }];
    }
}

- (void)sendPhoneForAuthRequest:(NSString *)phoneString
              completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"phone"] = phoneString;
    
    if (completionHandler) {
        completionHandler = [completionHandler copy];
    }

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kAuthPhonePath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (completionHandler)
                                        {
                                            completionHandler(response, error);
                                        }
                                    }];
}

- (void)cancelWaitRequest:(SenderRequestCompletionHandler)completionHandler
{
    [[CometController sharedInstance] addMessageToQueue:@{}
                                             withUrlPath:kAuthBreakPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {

                                        if (completionHandler)
                                        {
                                            completionHandler(response, error);
                                        }
                                    }];
}

- (void)getCompanyCards:(SenderRequestCompletionHandler)completionHandler
{
    [[CometController sharedInstance] addMessageToQueue:@{}
                                             withUrlPath:kGetCompanyContactPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (completionHandler)
                                        {
                                            completionHandler(response, error);
                                        }
                                    }];
}

- (void)askFroIVRForAuthRequest:(SenderRequestCompletionHandler)completionHandler
{
    [[CometController sharedInstance] addMessageToQueue:@{}
                                             withUrlPath:kAuthIVRPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {

                                        if (completionHandler)
                                        {
                                            completionHandler(response, error);
                                        }
                                    }];
}

- (void)sendOtpForAuthRequest:(NSString *)otpString
            completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    if (otpString) {
        
         postData[@"otp"] = otpString;
    }
        
    if (completionHandler) {
        completionHandler = [completionHandler copy];
    }

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kAuthOTPPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (completionHandler)
                                        {
                                            completionHandler(response, error);
                                        }
                                    }];
}

- (void)shareMyLocation:(NSDictionary *)locationDict
              imageData:(NSData *)file
                 inChat:(Dialog *)chat
      completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    params[@"filetype"] = @"jpg";
    
//    [server uploadFileWithParams:params postData:file completionHandler:^(NSDictionary *response, NSError *error) {
//        
//        if (!error && response[@"url"]) {
    NSMutableDictionary * model = [[NSMutableDictionary alloc] initWithDictionary:locationDict];
    
//            [model setObject:response[@""] forKey:@"preview"];
    [model setObject:@"" forKey:@"preview"];
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = chat.chatID;
    postData[@"class"] = @".shareMyLocation.sender";
//    postData[@"formId"] =
//    postData[@"robotId"] = @"shareMyLocation";
//    postData[@"companyId"] = @"sender";
    postData[@"model"] = model;
    Message * newLocationMessage = [[CoreDataFacade sharedInstance] writeLocationMessage:postData];
    [[FileManager sharedFileManager] savePreviewImage:file toMessage:newLocationMessage.moId];
    NSString  * tempID = newLocationMessage.moId;

    [SENDER_SHARED_CORE.interfaceUpdater messagesWereChanged:@[newLocationMessage]];
    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                        {
                                            [self reSetMessageStatusAndMoId:newLocationMessage
                                                               fromResponse:response[@"cr"][0] tempId:tempID];
                                        }
                                        if (completionHandler)
                                        {
                                            completionHandler(response, error);
                                        }
                                    }];
}

- (void)uploadFileFormFormAsset:(NSData *)fileData  completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    params[@"filetype"] = @"jpg";
    
    [server uploadFileWithParams:params postData:fileData completionHandler:^(NSDictionary *response, NSError *error) {
        if (completionHandler) {
            completionHandler(response, error);
        }
    }];
}

- (void)sendVideoMessage:(NSData *)videoFile fromLocalURL:(NSURL *)videoOutURL imageData:(NSData *)prewFile videoDuration:(float)duration chatId:(NSString *)chatId completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    params[@"filetype"] = @"jpg";
    
    //[server uploadFileWithParams:params fileUrl:videoOutURL completionHandler:nil];
    
    [server uploadFileWithParams:params postData:prewFile completionHandler:^(NSDictionary *response, NSError *error) {
        
        if (!error && response[@"url"]) {
            NSMutableDictionary * model = [[NSMutableDictionary alloc] init];
            [model setObject:response[@"url"] forKey:@"preview"];
            
            Message * newVideoMessage = [[CoreDataFacade sharedInstance]
                                         writeVideoMessageWithLocalUrl:videoOutURL.absoluteString
                                         externalUrl:response[@"url"]
                                         withPreviewImagePath:model[@"preview"]
                                         videoDuration:duration
                                         inChat:chatId];

            [SENDER_SHARED_CORE.interfaceUpdater messagesWereChanged:@[newVideoMessage]];
            NSMutableDictionary * params1 = [[NSMutableDictionary alloc] init];
            params1[@"filetype"] = @"mp4";
            
            // [server uploadFileWithParams:params1 postData:videoFile completionHandler:^(NSDictionary *response, NSError *error) {
            [server uploadFileWithParams:params1 fileUrl:videoOutURL completionHandler:^(NSDictionary *response, NSError *error) { /////добавить
                if (!error && response[@"url"]) {
                    
                    newVideoMessage.file.url = response[@"url"];
                    [[FileManager sharedFileManager] savePreviewImage:prewFile toMessage:newVideoMessage.moId];
     
                    NSString * name = [NSString stringWithFormat:@"Video from %@",[CoreDataFacade sharedInstance].getOwner.name];
                    
                    [model setObject:name forKey:@"name"];
                    [model setObject:name forKey:@"desc"];
                    [model setObject:@"mp4" forKey:@"type"];
                    [model setObject:[NSString stringWithFormat:@"%f", duration] forKey:@"length"];
                    [model setObject:response[@"url"] forKey:@"url"];
                    
                    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
                    postData[@"chatId"] = chatId;
                    postData[@"formId"] = @"";
                    postData[@"robotId"] = @"videoMsg";
                    postData[@"companyId"] = @"sender";
                    postData[@"model"] = model;

                    [[CometController sharedInstance] addMessageToQueue:postData
                                                             withUrlPath:kSendPath
                                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                                    {
                                                        if (!error)
                                                        {
                                                            [[CoreDataFacade sharedInstance] setStatus:@"sent" forMessage:newVideoMessage.moId];

                                                            if (response[@"cr"])
                                                            {
                                                                NSDictionary *res = response[@"cr"][0];

                                                                NSTimeInterval timeInterval = (NSTimeInterval) [res[@"time"] doubleValue] / 1000;
                                                                NSDate *creation = [[NSDate alloc] initWithTimeIntervalSince1970:timeInterval];
                                                                [[CoreDataFacade sharedInstance] setNewPacketID:res[@"packetId"]
                                                                                                           moID:res[@"packetId"]
                                                                                                andCreationTime:creation
                                                                                                     forMessage:newVideoMessage];
                                                            }
                                                            [SENDER_SHARED_CORE.interfaceUpdater messagesWereChanged:@[newVideoMessage]];
                                                        }
                                                        if (completionHandler)
                                                        {
                                                            completionHandler(response, error);
                                                        }
                                                    }];
            
                }
                
            }];
        }
    }];
}

- (void)      sendQR:(NSString*)qr
              chatID:(NSString * _Nullable)chatID
additionalParameters:(NSDictionary * _Nullable)additionalParameters
      requestHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = chatID ?:[[CoreDataFacade sharedInstance] getOwner].senderChatId;
    postData[@"formId"] = [NSString string];
    postData[@"robotId"] = @"qr";
    postData[@"companyId"] = @"sender";

    NSMutableDictionary * model = [NSMutableDictionary dictionary];
    model[@"qrCode"] = qr;

    for (NSString * key in [additionalParameters allKeys]) {
        if (model[key] == nil)
            model[key] = additionalParameters[key];
        else
            NSAssert(NO, ([NSString stringWithFormat:@"You cannot use value with key '%@' in additional params.", key]));
    }

    postData[@"model"] = [model copy];

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (completionHandler)
                                        {
                                            completionHandler(response, error);
                                        }
                                    }];
}

- (void)sendLocalizationWithCompletion:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = [[CoreDataFacade sharedInstance] getOwner].senderChatId;
    postData[@"formId"] = [NSString string];
    postData[@"robotId"] = @"setDeviceLocale";
    postData[@"companyId"] = @"sender";
    postData[@"model"] = @{@"locale": DBSettings.language};

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (completionHandler)
                                            completionHandler(response, error);
                                    }];
}

- (void)sendComplaintAboutUserWithID:(NSString *)userId withReason:(NSString *)reason
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = [[CoreDataFacade sharedInstance] getOwner].senderChatId;
    postData[@"formId"] = [NSString string];
    postData[@"robotId"] = @"investigation";
    postData[@"companyId"] = @"sender";
    postData[@"model"] = @{@"userId":userId, @"description":reason};

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {

                                    }];
}

- (void)uploadImage:(UIImage *)imageInc withLocalURL:(NSString *)localURLString chatID:(NSString *)chatID
{
    if (!imageInc)
        return;

    int scaleImg = [[CometController sharedInstance] isWWAN] ? 4:2;

    CGSize imageSize = CGSizeMake(imageInc.size.width/scaleImg, imageInc.size.height/scaleImg);
    UIImage * image = [self squareImageWithImage:imageInc scaledToSize:imageSize];
    NSData * imageData = UIImageJPEGRepresentation(image, [[CometController sharedInstance] isWWAN] ? 0.4f : 0.6f);
    NSData * previewImageData = [[FileManager sharedFileManager] createPreviewImage:imageData];
    Message * newImageMessage = [[CoreDataFacade sharedInstance] writeImageMessageWithLocalUrl:localURLString
                                                                                        inChat:chatID];
    
    if (!localURLString)
        [[FileManager sharedFileManager] saveImageData:imageData toPhotosAlbum:newImageMessage.moId isLocal:YES];
    else
        [[FileManager sharedFileManager] savePreviewImage:previewImageData toMessage:newImageMessage.moId];

    NSNumber * imageWidthS = @(image.size.width);
    NSNumber * imageHeightS = @(image.size.height);
    
    NSDictionary * messageDict = @{@"type":newImageMessage.type,
                                   @"chat":newImageMessage.chat,
                                   @"moId":newImageMessage.moId,
                                   @"target":@"upload",
                                   @"imageWidthS":imageWidthS,
                                   @"imageHeightS":imageHeightS};
    
    [[ServerFacade sharedInstance] uploadFileToServer:imageData previewImage:previewImageData byMessage:messageDict];
}

- (UIImage *)squareImageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    double ratio;
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.height);
    
    if (image.size.width > image.size.height) {
        ratio = newSize.width / image.size.width;
        
    } else {
        ratio = newSize.height / image.size.height;
    }
    
    CGRect clipRect = CGRectMake(0, 0,
                                 (ratio * image.size.width),
                                 (ratio * image.size.height));
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [image drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

//SIP

- (NSDictionary *)getUserDeviceInfo:(NSString *)userID
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    if (!userID) {
        postData[@"userId"] = @"";
    } else {
        postData[@"userId"] = userID;
    }
    
    NSDictionary * result = [[CometController sharedInstance] createSimpleRequest:postData withUrlPath:kGetUserDeviceInfoPath];
    
    if (result.count) {
        return result;
    }
    else {
        return nil;
    }
}

- (void)startCallToUserID:(NSString *)userID
        completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    if (completionHandler)
        completionHandler = [completionHandler copy];

    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = [[CoreDataFacade sharedInstance] getOwner].senderChatId;
    postData[@"formId"] = @"";
    postData[@"robotId"] = @"callRing";
    postData[@"companyId"] = @"sender";
    postData[@"class"] = @".callRing.sender";
    postData[@"model"] = @{@"userId":userID};

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                            if (completionHandler)
                                                completionHandler(response, error);
                                    }];
}

- (void)setOperatorStatus:(BOOL)mode
                 inDialog:(NSString *)dialogID
        completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    if (completionHandler)
        completionHandler = [completionHandler copy];
    
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = [[CoreDataFacade sharedInstance] getOwner].senderChatId;
    postData[@"class"] = @"oStatusSet";
    
    NSString * status = mode ? @"online":@"offline";
    
    postData[@"model"] = @{@"companyId":dialogID,@"status":status};

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                            if (completionHandler)
                                                completionHandler(response, error);
                                    }];
}

- (void)runCallWithInfo:(NSDictionary *)callInfo
  withcompletionHandler:(SenderRequestCompletionHandler)completionHandler
{
    if (completionHandler)
        completionHandler = [completionHandler copy];
    
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = [[CoreDataFacade sharedInstance] getOwner].senderChatId;
    postData[@"formId"] = @"";
    postData[@"robotId"] = @"callRun";
    postData[@"companyId"] = @"sender";
    
    postData[@"class"] = @".callRun.sender";
    postData[@"model"] = @{@"userId":callInfo[@"userId"],@"devId":callInfo[@"devId"]};

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                            if (completionHandler)
                                                completionHandler(response, error);
                                    }];
}

- (void)cancelCallWithInfo:(NSDictionary *)callInfo
     withcompletionHandler:(SenderRequestCompletionHandler)completionHandler
{
    if (completionHandler)
        completionHandler = [completionHandler copy];
    
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = [[CoreDataFacade sharedInstance] getOwner].senderChatId;
    postData[@"formId"] = @"";
    postData[@"robotId"] = @"callClose";
    postData[@"companyId"] = @"sender";
    
    postData[@"class"] = @".callClose.sender";
    postData[@"model"] = @{@"userId":callInfo[@"userId"],@"devId":callInfo[@"devId"],@"code":@""};

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                            if (completionHandler)
                                                completionHandler(response, error);
                                    }];
}

-(void)getUnspentTransactionsForWallet:(BitcoinWallet *)wallet completionHandler:(void (^)(NSArray * unspentTransactions, NSError * error))completionHandler;
{
    if (!wallet.rootCompressedPublicKeyAddress) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        BTCBlockchainInfo * info = [[BTCBlockchainInfo alloc] init];
        NSError * error;
        BTCKeychain * keychain = [[wallet.mnemonic keychain]derivedKeychainWithPath:@"m/0'"];
        NSArray * response = [info unspentOutputsWithExtendedPublicKeys:@[keychain.extendedPublicKey] error:&error];
        if (completionHandler) {
            completionHandler(response, error);
        }
    });
}

-(void)sendTransaction:(BTCTransaction *)transaction withCompletionHandler:(SenderRequestCompletionHandler)completionHandler
{
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        BTCBlockchainInfo * info = [[BTCBlockchainInfo alloc]init];
        NSError * error;
        NSDictionary * response;
        
        NSURLRequest * transactionRequest = [info requestForTransactionBroadcastWithData:transaction.data];

        NSData * responseData = [NSURLConnection sendSynchronousRequest:transactionRequest returningResponse:nil error:&error];
        if (!error)
        {
            NSString * responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            response = @{@"result" : responseString};
            
        }
        if (completionHandler) {
            completionHandler(response, error);
        }
    });
}

- (void)sendTransactionResult:(NSString *)result
                 toChatWithID:(NSString *)chatID
                   withAmount:(NSString *)amount
                    toAddress:(NSString *)address
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = chatID;
    postData[@"formId"] = @"5645b416f6c37670c3d7a994";
    postData[@"robotId"] = @"78599";
    postData[@"companyId"] = @"i69991017392";
    postData[@"model"] = @{@"result" : result,
                           @"addr" : address,
                           @"summ" : amount,
                           @"button_8" : @"ok"};

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (error)
                                        {
                                        }
                                    }];
}

- (void)sendCurrentWalletToServer
{
    if ([[[CoreDataFacade sharedInstance] getOwner] getMainWallet:nil])
    {
        NSString * bitcoinAddress =  [[[CoreDataFacade sharedInstance] getOwner] getMainWallet:nil].paymentKey.compressedPublicKeyAddress.string;
        if (bitcoinAddress)
        {
            NSDictionary *selfInfo = @{@"btcAddr": bitcoinAddress,
                                       @"msgKey": [[[[CoreDataFacade sharedInstance] getOwner] getMainWallet:nil] base58PublicKey]};
            [[ServerFacade sharedInstance] setSelfInfo:selfInfo withRequestHandler:nil];
            [[ServerFacade sharedInstance] setStorageWithNewValue:[[[CoreDataFacade sharedInstance] getOwner] mnemonic]
                                                completionHandler:nil];
        }
    }
}

- (void)getBitcoinMarketPriceWithCompletionHandler:(SenderRequestCompletionHandler)completionHandler
{
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        BTCBlockchainInfo * info = [[BTCBlockchainInfo alloc] init];
        NSError * error;
        NSDictionary * response = [info marketPrice:&error];
        if (completionHandler) {
            completionHandler(response, error);
        }
    });
}

- (void)sendProxyRequest:(NSDictionary *)model
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = [[CoreDataFacade sharedInstance] getOwner].senderChatId;
    postData[@"model"] = model;
    postData[@"class"] = @".proxySend.sender";
    postData[@"toId"] = @"";

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSendPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                    }];
}

//storage

- (void)checkStorageWallet
{
    if (![[SenderCore sharedCore] isBitcoinEnabled])
        return;

    [self getStorageValueWithCompletionHandler:^(NSDictionary *response, NSError *error) {
        NSString *ownerMnemonic = [[[CoreDataFacade sharedInstance] getOwner] mnemonic] ?: @"";
        NSString *remoteMnemonic = response[@"storage"];

        if (![remoteMnemonic isEqualToString:ownerMnemonic])
        {
            if ([[[CoreDataFacade sharedInstance] getOwner] isDefaultBitcoinPasswordUsed])
            {
                if ([[[[CoreDataFacade sharedInstance] getOwner] clearMnemonic] isEqualToString:remoteMnemonic])
                {
                    [[CoreDataFacade sharedInstance] getOwner].mnemonic = remoteMnemonic;
                    return;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[CoreDataFacade sharedInstance] getOwner].walletState = BitcoinWalletStateNeedSync;
                UIViewController * rootViewController = [SenderCore sharedCore].authorizationNavigationController;

                if (!rootViewController)
                {
                    NSException * exception = [NSException exceptionWithName:@"Cannot resolve bitcoin conflict"
                                                                      reason:@"authorizationNavigationController is nil"
                                                                    userInfo:nil];
                    [exception raise];
                    return;
                }

                [[BitcoinConflictResolver shared] startConflictResolvingInRootViewController:rootViewController
                                                                                    delegate:nil];
            });
        }
    }];
}

- (void)setStorageWithNewValue:(NSString *)newValue
             completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    [self operateWithStorage:newValue operateType:@"set" completionHandler:completionHandler];
}

- (void)getStorageValueWithCompletionHandler:(SenderRequestCompletionHandler)completionHandler
{
    [self operateWithStorage:nil operateType:@"get" completionHandler:completionHandler];
}

- (void)operateWithStorage:(NSString *)value operateType:(NSString *)type completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"value"] = value;
    postData[@"type"] = type;

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kStoragePath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error)
                                        {
                                            if (completionHandler)
                                                completionHandler(response, error);
                                        }
                                    }];
}

- (void)changeEncryptionStateOfChatWithID:(NSString * _Nonnull)chatID
                          encryptionState:(BOOL)encryptionState
                                     keys:(NSDictionary<NSString*, NSString*>*)keys
                                senderKey:(NSString *)senderKey
                        completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    postData[@"chatId"] = chatID;
    postData[@"enabled"] = @(encryptionState);
    if (senderKey) postData[@"senderKey"] = senderKey;
    if (keys) postData[@"keys"] = keys;

    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kSetChatKeyPath
                                    withCompletionHolder:completionHandler];
}

- (void)getCountryListWithCompletionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSString * curLocalization = @"RU";
    
    if ([[DBSettings.language lowercaseString] hasPrefix:@"en"]) {
        curLocalization = @"EN";
    } else if ([[DBSettings.language lowercaseString] hasPrefix:@"uk"]) {
        curLocalization = @"UK";
    }

    [[CometController sharedInstance] addMessageToQueue:@{@"language": curLocalization}
                                             withUrlPath:kGetCountryListPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (!error && response && completionHandler)
                                        {
                                            completionHandler(response, error);
                                        }
                                    }];
}

- (void)getCurrentPhonePrefixWithCompletionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSString * curLocalization = @"RU";
    
    if ([[DBSettings.language lowercaseString] hasPrefix:@"en"]) {
        curLocalization = @"EN";
    } else if ([[DBSettings.language lowercaseString] hasPrefix:@"uk"]) {
        curLocalization = @"UK";
    }

    [[CometController sharedInstance] addMessageToQueue:@{@"language": curLocalization}
                                             withUrlPath:kRegLightPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (completionHandler)
                                            completionHandler(response, error);
                                    }];
}

- (void)changeSettingsOfChatWithID:(NSString *)chatID
                settingsDictionary:(NSDictionary *)settingsDictionary
             withCompletionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postParameters = [settingsDictionary mutableCopy];
    postParameters[@"id"] = chatID;
    [[CometController sharedInstance] addMessageToQueue:[postParameters copy]
                                             withUrlPath:kSetChatOptionsPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (completionHandler)
                                        {
                                            if (!error)
                                            {
                                                completionHandler(response, error);
                                            }
                                            else
                                            {
                                                completionHandler(nil, error);
                                            }
                                        }
                                    }];
}

//- (void)downloadImageWithBlock:(void(^)(UIImage * image))block forUrl:(NSString *)urlString
//{
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        @autoreleasepool {
//            NSError * error;
//            NSData * imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]
//                                                       options:NSDataReadingUncached error:&error];
//            
//            if (!imageData) {
//                return ;
//            }
//            
//            UIImage * newImage = [UIImage imageWithData:imageData];
//            block(newImage);
//        }
//    });
//}


// add a cache
- (void)downloadImageWithBlock:(void(^)(UIImage * image))block forUrl:(NSString *)urlString
{
    NSURL * imgURL = [[NSURL alloc] initWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    static NSCache *simpleImageCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        simpleImageCache = [[NSCache alloc] init];
        simpleImageCache.countLimit = 50;
    });
    
    if (!block) {
        return;
    }
    
    UIImage *image = [simpleImageCache objectForKey:urlString];
    if (image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(image);
        });
    } else {
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
        NSURLSessionDataTask *task = [session dataTaskWithURL:imgURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (data) {
                UIImage *image = [UIImage imageWithData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(image);
                });
            }
        }];
        [task resume];
    }
}

- (void)getHistoryForChat:(Dialog *)chat
          withMessagesGap:(MessagesGap *)gap
        completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    if (!chat.chatID)
    {
        NSAssert(NO, @"Chat ID must not be nil");
        return;
    }

    [self loadHistoryOfChatWithID:chat.chatID
             startingWithPacketID:[gap.startPacketID integerValue]
                      endPacketID:[gap.endPacketID integerValue]
                     asGapRemover:NO
                completionHandler:completionHandler];
}

// API sync v10
- (void)syncApplicationWithContacts:(NSArray<NSDictionary *> *)contacts
                      isFullVersion:(BOOL)isFullVersion
                  completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
        postData[@"fullVersion"] = @(isFullVersion);
        postData[@"contacts"] = contacts ?: @[];
        [[CometController sharedInstance] addMessageToQueue:postData
                                                 withUrlPath:kSyncApplicationPath
                                        withCompletionHolder:^(NSDictionary *response, NSError *error)
                                        {

                                            if (!error)
                                            {
                                                if (completionHandler)
                                                {
                                                    dispatch_main_async_safe(^
                                                    {
                                                        completionHandler(response, error);
                                                    });
                                                }
                                            }
                                        }];
    });
}

- (void)sendGoogleTokenToServer:(NSString *)accessToken completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    if (!accessToken) return;
    [[CometController sharedInstance] addMessageToQueue:@{@"token": accessToken}
                                             withUrlPath:@"set_google_token"
                                    withCompletionHolder:completionHandler];
}

- (void)changeFullVersionState:(BOOL)state completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSString * versionState = state ? @"true" : @"false";
    NSDictionary * postData = @{@"activate" : versionState};
    [[CometController sharedInstance] createDirectRequestWithPath:@"full_version"
                                                         postData:postData
                                             withCompletionHolder:^(NSDictionary *response, NSError *error)
    {
        if (completionHandler)
        {
            completionHandler(response, error);
        }
    }];
}

- (void)changeP2PChatWithUserID:(NSString *)userID
                       withName:(NSString *)name
                          phone:(NSString *)phone
              completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * changes = [[NSMutableDictionary alloc] init];
    changes[@"userId"] = userID;
    if (name) changes[@"name"] = name;
    if (phone) changes[@"phone"] = phone;

    [self updateContact:[changes copy] requestHandler:completionHandler];
}

- (void)deleteP2PChatWithUserID:(NSString *)userID
              completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * changes = [[NSMutableDictionary alloc] init];
    changes[@"userId"] = userID;
    changes[@"state"] = stringFromChatState(ChatStateRemoved);
    [self updateContact:[changes copy] requestHandler:completionHandler];
}

- (void)saveP2PChatWithUserID:(NSString *)userID
            completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * changes = [[NSMutableDictionary alloc] init];
    changes[@"userId"] = userID;
    changes[@"state"] = stringFromChatState(ChatStateSaved);
    [self updateContact:[changes copy] requestHandler:completionHandler];
}

- (void)syncPhoneBookWithLimit:(NSInteger)limit
                          skip:(NSInteger)skip
             completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSDictionary * postData = @{@"limit": @(limit), @"skip": @(skip)};
    [[CometController sharedInstance] addMessageToQueue:postData
                                             withUrlPath:kPhoneBookPath
                                    withCompletionHolder:^(NSDictionary *response, NSError *error)
                                    {
                                        if (completionHandler)
                                        {
                                            completionHandler(response, error);
                                        }
                                    }];
}

@end
