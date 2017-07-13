//
//  CoreDataFacade.h
//  SENDER
//
//  Created by Nick Gromov on 10/2/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#define DBSettings [[CoreDataFacade sharedInstance] getOwner].settings

#import <Foundation/Foundation.h>
#import "CoreData/CoreData.h"

NSString * userIDFromChatID(NSString * chatID);
NSString * _Nonnull chatIDFromUserID(NSString * _Nonnull userID);

@class Owner;
@class Dialog;
@class Contact;
@class ProgressView;
@class Message;
@class Settings;
@class DialogSetting;
@class BarModel;
@class CompanyCard;

@interface CoreDataFacade : NSObject

@property (nonatomic, strong) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, strong) NSString * ownerUDIDString;
@property (nonatomic, strong) Owner * owner;

- (NSString *)ownerUDID;

+ (CoreDataFacade * _Nonnull)sharedInstance;

- (void)saveContext;
- (void)saveContextSynchronously;

- (void) defaultErrorHandler:(NSError *)error;

- (void)deleteManagedObject:(NSManagedObject *)object;

- (NSManagedObject *)getNewObjectWithName:(NSString *)entityName;

- (NSArray *)executeFetchRequest:(NSFetchRequest *)request;

- (NSFetchRequest *)getRequestForObjectWithName:(NSString *)name;

- (NSManagedObject *)executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request;

- (NSArray *)getSortDescriptorsBy:(NSString *)sortTerm ascending:(BOOL)ascending;

- (NSArray *)findAllWithName:(NSString *)name;

- (NSArray *)findAllWithName:(NSString *)name
                    sortedBy:(NSString *)sortTerm
                   ascending:(BOOL)ascending;

- (NSArray *)findAllWithName:(NSString *)name
                    sortedBy:(NSString *)sortTerm
                   ascending:(BOOL)ascending
               withPredicate:(NSPredicate *)searchTerm;

- (NSArray *)findAllWithName:(NSString *)name
                    sortedBy:(NSString *)sortTerm
                   ascending:(BOOL)ascending
               withPredicate:(NSPredicate *)searchTerm
       includePendingChanges:(BOOL)includePending;

- (NSManagedObject *)findFirstObjectWithName:(NSString *)name byProperty:(NSString *)property withValue:(id)value;

- (NSArray *)findObjectsWithName:(NSString *)name byProperty:(NSString *)property withValueLike:(NSString *)value;

- (NSArray<Dialog *> *) getUnreadChats;

- (Owner *)getOwner;

- (nullable Dialog *)dialogWithChatIDIfExist:(NSString *)chat;

- (Message *)messageById:(NSString *)messageId;

- (Message *)newMessageModel;

- (Contact * _Nullable)selectContactById:(NSString *)userId;
- (Contact *)getNewContactWithUserID:(NSString *)userID;
- (Dialog *)getSenderChat;
- (Contact *)contactWithLocalID:(NSString *)localID;

- (NSArray<Contact *> *)getUsers;
- (NSArray<Contact *> *)getAllContacts;

- (NSArray *)getBlockedChats;

- (NSInteger)getBlockedContactsCount;

- (NSArray *)getChats;
- (NSArray *)getP2PChats;
- (NSArray *)getChatsWithUsers;
- (NSArray<Dialog *> *)getCompanyChats;

- (NSArray *)getDialogs;

- (NSArray *)getMyOperatedList;
- (NSArray *)getOperatedCompaniesChats;

- (void)updateDialogSetting:(Dialog *)dialog withJsonData:(NSDictionary *)jsonData;

- (BOOL)checkForDialogSetting:(Dialog *)dialog;

- (BarModel *)senderBar;

- (void)setOwnerInfo:(NSDictionary *)userInfo;

- (void)setOwnerImageData:(NSData *)data;

- (void)clearAllHistory;

- (void)setStatus:(NSString *)status forMessage:(NSString *)messageId;

- (void)setNewPacketID:(NSString *)packetID
                  moID:(NSString *)moID
       andCreationTime:(NSDate *)creation
            forMessage:(Message *)message;

- (void)setNewPacketID:(NSString *)packetID
            forMessage:(Message *)message;

- (Message *)writeVoiceMessageToChat:(NSString *)chatId;

- (Message *)writeMessageWithText:(NSString *)text inChat:(NSString *)chatID encripted:(BOOL)eMode;

- (Message *)writeImageMessageWithLocalUrl:(NSString *)url inChat:(NSString *)chatID;

- (Message *)writeMessageWithSticker:(NSString *)sticker inChat:(NSString *)chatID;

- (Message *)writeVibroMessageInChat:(NSString *)chatID;

- (void)setUploadUrl:(NSString *)url toMessage:(NSString *)messageId;

- (void)setLocalUrl:(NSString *)url toMessage:(NSString *)messageId;

- (Message *)writeLocationMessage:(NSDictionary *)data;

- (Message *)writeVideoMessageWithLocalUrl:(NSString *)locurl
                               externalUrl:(NSString *)url
                      withPreviewImagePath:(NSString *)imgPath
                             videoDuration:(float)duration
                                    inChat:(NSString *)chatId;

- (BOOL)clearOwnerModel;

- (void)cleanFullVersionData;

- (void)addGapWithStartPacketID:(NSInteger)startPacketID
                    endPacketID:(NSInteger)endPacketID
                   creationTime:(NSTimeInterval)creationTime
                         toChat:(nonnull Dialog *)chat;

- (CompanyCard * _Nonnull)createCompanyCard;

@end
