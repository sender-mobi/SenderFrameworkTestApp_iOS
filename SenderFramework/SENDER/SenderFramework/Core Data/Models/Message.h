//
//  Message.h
//  SENDER
//
//  Created by Eugene on 4/8/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "File.h"

@class Dialog, File;

@protocol MessageObject <NSObject>

@required

@property (nonatomic, retain) NSString * chat;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSString * deliver;
@property (nonatomic, retain) NSString * fromId;
@property (nonatomic, retain) NSString * fromname;
@property (nonatomic, strong) NSString * packetID;
@property (nonatomic, retain) NSString * linkID;
@property (nonatomic, retain) NSString * lasttext;
@property (nonatomic, retain) NSString * moId;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Dialog * dialog;
@property (nonatomic, weak) NSIndexPath * indexPath;
@property (nonatomic) BOOL owner;
@property (nonatomic, strong) UIView * viewForCell;
@property (nonatomic, retain) NSString * classRef;

- (CGFloat)heightConsoleForm;
- (BOOL)owner;

@end

@interface Message : NSManagedObject <MessageObject>

@property (nonatomic, retain) NSString * chat;
@property (nonatomic, retain) NSString * companyId;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSString * deliver;
@property (nonatomic, retain) NSString * formId;
@property (nonatomic, retain) NSString * fromId;
@property (nonatomic, retain) NSString * fromname;
@property (nonatomic, retain) NSString * lasttext;
@property (nonatomic, retain) NSString * linkID;
@property (nonatomic, retain) NSData * modelData;
@property (nonatomic, retain) NSString * moId;
@property (nonatomic, retain) NSString * robotId;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Dialog *dialog;
@property (nonatomic, retain) File *file;
@property (nonatomic, retain) NSNumber * encrypted;
@property (nonatomic, strong) NSString * procId;
@property (nonatomic, strong) NSString * packetID;
@property (nonatomic, strong) NSString * editID;

//not in DB property

@property (nonatomic, weak) NSIndexPath * indexPath;
@property (nonatomic) BOOL owner;
@property (nonatomic, strong) UIView * viewForCell;
@property (nonatomic, strong) NSString * textMessage;
@property (nonatomic) BOOL deletedMessage;
@property (nonatomic) BOOL editedMessage;

- (void)setDataFromDictionary:(NSDictionary *)data inDialog:(Dialog *)chat;
- (BOOL)owner;
- (void)concatTextMessage:(NSString *)newText;
- (void)updateWithText:(NSString *)text encryptionEnabled:(BOOL)encryptionEnabled;

- (CGFloat)heightConsoleForm;
- (Dialog *)fmlDialog;

@end
