//
//  ServerFacade.h
//  SENDER
//
//  Created by Eugene Gilko on 10/2/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SenderFramework/CoreDataFacade.h>
#import <SenderFramework/BTCBlockchainInfo.h>
#import <SenderFramework/RequestHolder.h>
#import "Dialog.h"

#define kSendPath @"send"
#define kRegPath @"reg"
#define kRegLightPath @"reg_light"
#define kGetCompanyOperatorsPath @"get_company_operators"
#define kSyncContactsPath @"sync_ct"
#define kSyncApplicationPath @"sync"
#define kPhoneBookPath @"get_phone_book"
#define kSyncDialogsPath @"sync_dlg"
#define kSetContactPath @"set_ct"
#define kSetSelfInfoPath @"selfinfo_set"
#define kGetHistoryPath @"history"
#define kTokenPath @"token"
#define kTypingPath @"typing"
#define kChatSetPath @"chat_set"
#define kAuthPhonePath @"auth_phone"
#define kAuthBreakPath @"auth_break"
#define kAuthIVRPath @"auth_ivr"
#define kAuthOTPPath @"auth_otp"
#define kGetCompanyContactPath @"get_companies_cf"
#define kStoragePath @"storage"
#define kSetChatKeyPath @"chat_key_set"
#define kGetCountryListPath @"country_list"
#define kSetChatOptionsPath @"chat_options_set"
#define kGetUserDeviceInfoPath @"get_user_dev_info"
#define kGetChatPath @"get_chat"

@class MessagesGap;
@class Dialog;
@class BitcoinWallet;
@class BTCTransaction;

@interface ServerFacade : NSObject

typedef void(^RequestDictionaryCompletionHandler)(NSDictionary *);

+ (ServerFacade *)sharedInstance;

@property (nonatomic, strong) NSString * sid;

- (BOOL)isWwan;

//Calling robot

- (void)callRobotWithParameters:(NSDictionary *)parameters
                         chatID:(NSString *)chatID
                      withModel:(NSDictionary *)model
                 requestHandler:(SenderRequestCompletionHandler)completionHandler;

//Sending messages

- (void)sendForm:(NSDictionary *)formData;

- (void)sendMessage:(Message *)message
         withDialog:(Dialog *)messageDialog
  completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)sendStickerMessage:(Message *)message;

- (void)sendVibroMessage:(Message *)message;

- (void)shareMyLocation:(NSDictionary *)locationDict
              imageData:(NSData *)file
                 inChat:(Dialog *)chat
      completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)sendVideoMessage:(NSData *)videoFile
            fromLocalURL:(NSURL *)videoOutURL
               imageData:(NSData *)prewFile
           videoDuration:(float)duration
                  chatId:(NSString *)chatId
       completionHandler:(SenderRequestCompletionHandler)completionHandler;

//Chat

- (void)getChatWithID:(NSString *)chatID requestHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)leaveChat:(NSString *)chatId completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)deleteMembersWithUserIDs:(NSArray<NSString *> *)userIDs
                  fromChatWithID:(NSString *)chatID
                  requestHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)addMembers:(NSArray *)members
            toChat:(NSString * _Nonnull)chatID
    requestHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)changeChat:(NSString *)chatID
          withName:(NSString*)newName
       description:(NSString *)newDescription
          photoUrl:(NSString *)photoURL
    requestHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)changeEncryptionStateOfChatWithID:(NSString * _Nonnull)chatID
                          encryptionState:(BOOL)encryptionState
                                     keys:(NSDictionary<NSString*, NSString*>*)keys
                                senderKey:(NSString *)senderKey
                        completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)changeP2PChatWithUserID:(NSString *)userID
                       withName:(NSString *)name
                          phone:(NSString *)phone
              completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)deleteP2PChatWithUserID:(NSString *)userID
              completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)saveP2PChatWithUserID:(NSString *)userID
            completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)changeSettingsOfChatWithID:(NSString *)chatID
                settingsDictionary:(NSDictionary *)settingsDictionary
             withCompletionHandler:(SenderRequestCompletionHandler)completionHandler;

//Contacts
- (NSDictionary *)getContactInfoByPhone:(NSString *)phone;

//TODO Works with old api. Needs to be changed to new.
- (void)addContactWithName:(NSString*)name
                     phone:(NSString *)phone
            requestHandler:(SenderRequestCompletionHandler)completionHandler;

//Self info

- (void)setSelfInfo:(NSDictionary *)info withRequestHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)updateSelfInfo:(SenderRequestCompletionHandler)completionHandler;

- (void)getSelfInfoWithCompletion:(SenderRequestCompletionHandler)completionHandler;

//Company card

- (void)loadCompanyCardForP2PChat:(Dialog *)p2pChat completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)getCompanyCards:(SenderRequestCompletionHandler)completionHandler;

//Typing

- (void)sendTypingToChatWithID:(NSString * _Nonnull)chatID
                requestHandler:(SenderRequestCompletionHandler)completionHandler;

//Read

- (void)sayReadStatus:(Message *)message;

//Global Search

- (void)globalSearchWithText:(NSString *)text requestHandler:(SenderRequestCompletionHandler)completionHandler;

//Online status

- (void)checkOnlineStatusForUserIDs:(NSArray<NSString *> *)userId;

//Sending system info

- (void)sendMyLocation:(NSDictionary *)locationDict completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)setVersionToServer;

- (void)getVersionInfoWithRequestHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)sendMyToken:(NSString *)token andViopToken:(NSString *)voipToken;

- (void)sendLocalizationWithCompletion:(SenderRequestCompletionHandler)completionHandler;

//Complaint

- (void)sendComplaintAboutUserWithID:(NSString *)userId withReason:(NSString *)reason;

//Logs

- (void)sendLogToServer:(NSDictionary *)data
         requestHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)crashLogSend:(NSDictionary *)log;

- (void)sendCrashLog:(NSDictionary *)crashLog;

// Operator chats

- (void)setOperatorStatus:(BOOL)mode
                 inDialog:(NSString *)dialogID
        completionHandler:(SenderRequestCompletionHandler)completionHandler;
- (void)getCompanyOperatorsList:(NSString *)companyId
              completionHandler:(SenderRequestCompletionHandler)completionHandler;

//QR

- (void)      sendQR:(NSString*)qr
              chatID:(NSString * _Nullable)chatID
additionalParameters:(NSDictionary * _Nullable)additionalParameters
      requestHandler:(SenderRequestCompletionHandler)completionHandler;

//SIP CALLS

- (NSDictionary *)getUserDeviceInfo:(NSString *)userID;
- (void)startCallToUserID:(NSString *)userID
        completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)runCallWithInfo:(NSDictionary *)callInfo
  withcompletionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)cancelCallWithInfo:(NSDictionary *)callInfo
     withcompletionHandler:(SenderRequestCompletionHandler)completionHandler;

//Registration

- (void)registrationRequestWithUDID:(nonnull NSString *)udid
                        developerID:(nonnull NSString *)developerID
               additionalParameters:(nullable NSDictionary *)adParams
                         completion:(nullable SenderRequestCompletionHandler)completionHandler;

- (void)unlinkRequestWithUDID:(NSString *)udid
                  developerID:(NSString *)developerID
         additionalParameters:(NSDictionary *)adParams
                   completion:(SenderRequestCompletionHandler)completionHandler;

- (void)sendPhoneForAuthRequest:(NSString *)phoneString
              completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)sendOtpForAuthRequest:(NSString *)otpString completionHandler:(SenderRequestCompletionHandler)completionHandle;

- (void)askFroIVRForAuthRequest:(SenderRequestCompletionHandler)completionHandler;

- (void)cancelWaitRequest:(SenderRequestCompletionHandler)completionHandler;

//Files

- (void)uploadFileToServer:(NSData *)file
              previewImage:(NSData *)prewFile
                 byMessage:(NSDictionary *)message
            requestHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)uploadFileToServer:(NSData *)file previewImage:(NSData *)prewFile byMessage:(NSDictionary *)message;

- (void)uploadFileFormFormAsset:(NSData *)fileData  completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)downloadImageWithBlock:(void(^)(UIImage * image))block forUrl:(NSString *)urlString;

- (void)downloadFileWithBlock:(void(^)(NSData * data))block forUrl:(NSString *)urlString;

- (void)sendFile:(NSString *)url prewUrl:(NSString *)prevUrl byMessage:(NSDictionary *)messageId;

- (void)uploadImage:(UIImage *)imageInc withLocalURL:(NSString *)localURLString chatID:(NSString *)chatID;

//Bitcoin

-(void)getUnspentTransactionsForWallet:(BitcoinWallet *)wallet
                     completionHandler:(void (^)(NSArray * unspentTransactions, NSError * error))completionHandler;
-(void)sendTransaction:(BTCTransaction *)transaction
 withCompletionHandler:(SenderRequestCompletionHandler)completionHandler;
-(void)getBitcoinMarketPriceWithCompletionHandler:(SenderRequestCompletionHandler)completionHandler;
-(void)sendCurrentWalletToServer;

//Proxy

- (void)sendProxyRequest:(NSDictionary *)model;

//Storage

- (void)checkStorageWallet;
- (void)setStorageWithNewValue:(NSString *)newValue
             completionHandler:(SenderRequestCompletionHandler)completionHandler;
- (void)getStorageValueWithCompletionHandler:(SenderRequestCompletionHandler)completionHandler;

//Country list

- (void)getCountryListWithCompletionHandler:(SenderRequestCompletionHandler)completionHandler;
- (void)getCurrentPhonePrefixWithCompletionHandler:(SenderRequestCompletionHandler)completionHandler;

//Loading History

- (void)loadHistoryOfChat:(Dialog *)chat
     startingWithPacketID:(NSInteger)packetID
            messagesCount:(NSUInteger)messagesCount
            parseMessages:(BOOL)parseMessages
        completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)getChatHistory:(NSString *)chatID withRequestHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)getHistoryForChat:(Dialog *)chat
          withMessagesGap:(MessagesGap *)gap
        completionHandler:(SenderRequestCompletionHandler)completionHandler;

// API sync v10
- (void)syncApplicationWithContacts:(NSArray<NSDictionary *> *)contacts
                      isFullVersion:(BOOL)isFullVersion
                  completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)syncPhoneBookWithLimit:(NSInteger)limit
                          skip:(NSInteger)skip
             completionHandler:(SenderRequestCompletionHandler)completionHandler;

// set google token to server
- (void)sendGoogleTokenToServer:(NSString *)accessToken
              completionHandler:(SenderRequestCompletionHandler)completionHandler;

//Turning on/off full version of sender
- (void)changeFullVersionState:(BOOL)state completionHandler:(SenderRequestCompletionHandler)completionHandler;

@end
