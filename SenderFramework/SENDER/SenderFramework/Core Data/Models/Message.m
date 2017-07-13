//
//  Message.m
//  SENDER
//
//  Created by Eugene on 4/8/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "Message.h"
#import "Dialog.h"
#import "CoreDataFacade.h"
#import "FileManager.h"
#import "ParamsFacade.h"
#import "ECCWorker.h"
#import "SecGenerator.h"
#import "NSString+WebService.h"

@implementation Message

@dynamic chat;
@dynamic classRef;
@dynamic companyId;
@dynamic created;
@dynamic data;
@dynamic deliver;
@dynamic formId;
@dynamic fromId;
@dynamic fromname;
@dynamic lasttext;
@dynamic linkID;
@dynamic modelData;
@dynamic moId;
@dynamic robotId;
@dynamic type;
@dynamic dialog;
@dynamic file;
@dynamic encrypted;
@dynamic procId;
@dynamic packetID;
@dynamic editID;

@synthesize indexPath,
owner,
viewForCell,
textMessage, deletedMessage, editedMessage;

- (void)setDataFromDictionary:(NSDictionary *)data inDialog:(Dialog *)chat
{
    self.deliver = data[@"status"] ? data[@"status"]: @"sent";
    
    if(data[@"linkId"] && ![[data[@"linkId"] description] isEqualToString:@""])
        self.linkID = [data[@"linkId"] description];
    else
        self.linkID = [data[@"packetId"] description];

    self.packetID = [data[@"packetId"] description];
    
    if (![self.linkID isEqualToString:self.packetID]) {
        self.deliver = @"read";
    }
    
    self.moId = [NSString stringWithFormat:@"%@<<%@", data[@"chatId"],data[@"packetId"]];
    
//    if ([data[@"from"] isEqualToString:[CoreDataFacade sharedInstance].ownerUDIDString])
//        self.fromId = [CoreDataFacade sharedInstance].ownerUDIDString;
//    else
    self.fromId = data[@"from"];
    
    NSMutableDictionary * modelData = [[NSMutableDictionary alloc] initWithDictionary:data[@"model"]];

    self.classRef = data[@"class"];
    
    self.procId = [NSString stringWithFormat:@"%@",[data[@"procId"] description]];
//    self.classRef = [NSString stringWithFormat:@"%@.%@.%@", data[@"formId"],data[@"robotId"],data[@"companyId"]];
    self.formId = data[@"formId"];
    self.companyId = data[@"companyId"];
    self.robotId = data[@"robotId"];
    self.chat = [NSString stringWithFormat:@"%@",data[@"chatId"]];
    NSError * error;
    
    if ([data[@"created"] doubleValue])
    {
        NSTimeInterval timeInterval = (NSTimeInterval)[data[@"created"] doubleValue]/1000;
        self.created = [[NSDate alloc] initWithTimeIntervalSince1970:timeInterval];
    }
    else
    {
        NSString * messageMoid = [NSString stringWithFormat:@"%@<<%@", data[@"chatId"],data[@"linkId"]];
        Message * temp = (Message *)[[CoreDataFacade sharedInstance] findFirstObjectWithName:@"Message" byProperty:@"moId" withValue:messageMoid];
        
        if (temp) {
            self.created = temp.created;
        }
        else {
            self.created = [NSDate date];
        }
    }
    
    if ([data[@"from"] isEqualToString:[CoreDataFacade sharedInstance].ownerUDIDString])
        self.fromId = [CoreDataFacade sharedInstance].ownerUDIDString;
    else
        self.fromId = data[@"from"];
    
    self.fromname = data[@"fromName"];
    
//    if ([modelData[@"encrypted"] boolValue] && modelData[@"ecryptData"] && [chat chatType] == ChatTypeP2P) {
//        
//        self.encrypted = @1;
//        
//        NSString * encryptedString = modelData[@"ecryptData"];
//        NSData * keyData = nil;
//        NSString * posPkey = modelData[@"pkey"];
//        
//        if (posPkey) {
//            
//            if (![self.fromId isEqualToString:[CoreDataFacade sharedInstance].ownerUDID])
//                keyData = BTCDataFromBase58(posPkey);
//        }
//        
//        if (keyData.length < 32)
//            keyData = self.dialog.p2pBTCKeyData;
//        
//        NSString * decriptedString = [[ECCWorker sharedWorker] eciesDecriptMEssage:encryptedString
//                                                                    withPubKeyData:keyData
//                                                                         shortkEkm:YES
//                                                                         shortkEkm:YES
//                                                                         usePubKey:NO];
//        
//        if (decriptedString.length > 0) {
//            NSDictionary * ds = [decriptedString JSON];
//            [modelData removeAllObjects];
//            modelData = [NSMutableDictionary dictionaryWithDictionary:ds];
//            modelData[@"pkey"] = posPkey;
//            modelData[@"encrypted"] = @"1";
//            modelData[@"ecryptData"] = @"true";
//        }
//    }
    
    if ([data[@"type"] isEqualToString:@"msg"] && [self.formId isEqualToString:@"text"]) {

        self.type = @"TEXT";

        NSString * possiblePkey = modelData[@"pkey"] ? modelData[@"pkey"]:@"";
        
        self.data = [[ParamsFacade sharedInstance] NSDataFromNSDictionary:@{@"text":[modelData[@"text"] description],@"pkey":possiblePkey}];

        if ([modelData[@"encrypted"] boolValue]) {

            self.encrypted = @1;
            self.textMessage = @"";
       }
        else {
            self.encrypted = @0;
            NSString * text = modelData[@"text"];
            if ([text length])
            {
                self.textMessage = [text description];
            }
            else
            {
                self.textMessage = SenderFrameworkLocalizedString(@"Message deleted",nil);
                self.deletedMessage = YES;
            }
        }
        
        if ([modelData[@"encrypted"] boolValue]) {
            self.lasttext = SenderFrameworkLocalizedString(@"lst_msg_text_for_lc_encrypted_text_ios",nil);
        }
        else {
            self.lasttext = self.textMessage;
        }
        
        self.type = @"TEXT";
        
    }
    else if ([data[@"type"] isEqualToString:@"msg"] && [self.robotId isEqualToString:@"videoMsg"]) {
        self.type = @"VIDEO";
        //        self.lasttext = modelData[@"name"];
        self.lasttext = @"lst_msg_text_for_lc_video_ios";
        NSDictionary * fileData = modelData;
        File * new = (File *)[[CoreDataFacade sharedInstance] getNewObjectWithName:@"File"];
        [new setDataFromDictionary:fileData];
        self.file = new;
        [[FileManager sharedFileManager] downloadVideoPreviewForMessage:self];
    }
    else if ([data[@"type"] isEqualToString:@"msg"] && [self.formId isEqualToString:@"file"]) {
        
        NSDictionary * fileData = modelData;
        File * new = (File *)[[CoreDataFacade sharedInstance] getNewObjectWithName:@"File"];
        [new setDataFromDictionary:fileData];
        self.type = @"FILE";
        self.lasttext = @"lst_msg_text_for_lc_file_ios";
        self.file = new;
    }
    else if ([data[@"type"] isEqualToString:@"msg"] && [self.formId isEqualToString:@"audio"]) {
        self.type = @"AUDIO";
        self.lasttext = @"lst_msg_text_for_lc_voice_message_ios";
        NSDictionary * fileData = modelData;
        File * new = (File *)[[CoreDataFacade sharedInstance] getNewObjectWithName:@"File"];
        [new setDataFromDictionary:fileData];
        self.file = new;
        [[FileManager sharedFileManager] downloadDataForMessage:self];
    }
    else if ([data[@"type"] isEqualToString:@"msg"] && [self.formId isEqualToString:@"image"]) {
        self.type = @"IMAGE";
        self.lasttext = @"lst_msg_text_for_lc_image_msg_ph_ios";
        NSDictionary * fileData = modelData;
        File * new = (File *)[[CoreDataFacade sharedInstance] getNewObjectWithName:@"File"];
        [new setDataFromDictionary:fileData];
        self.file = new;
        [[FileManager sharedFileManager] downloadVideoPreviewForMessage:self];
    }
    else if ([data[@"type"] isEqualToString:@"msg"] && [self.robotId isEqualToString:@"shareMyLocation"]) {
        
        self.type = @"SELFLOCATION";
        self.lasttext = @"lst_msg_text_for_lc_location_ios";
        self.modelData = [[ParamsFacade sharedInstance] NSDataFromNSDictionary:modelData];
    }
    else if ([data[@"type"] isEqualToString:@"msg"] && [self.robotId isEqualToString:@"sticker"]) {
        self.type = @"STICKER";
        self.lasttext = @"lst_msg_text_for_lc_sticker_msg_ph_ios";
        
        self.data = [NSJSONSerialization dataWithJSONObject:modelData
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];
    }
    else if ([data[@"type"] isEqualToString:@"msg"] && [self.robotId isEqualToString:@"vibro"]) {
        self.type = @"VIBRO";
        self.lasttext = @"lst_msg_text_for_lc_vibro_msg_ph_ios";
        
        self.data = [NSJSONSerialization dataWithJSONObject:modelData
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];
    }
    
    if ([data[@"type"] isEqualToString:@"fml"] && data[@"view"] && ((NSArray *)data[@"view"]).count) {
        

        if (![data[@"packetId"] isEqualToString:data[@"linkId"]]) {
            self.deliver = @"read";
        }
        
        self.type = @"FORM";
        if (data[@"title"]) {
            self.lasttext = data[@"title"];
        }
        else {
            self.lasttext = @"lst_msg_text_for_lc_form_msg_ph_ios";
        }
        
        if ([data[@"formId"] isEqualToString:@"kickass"])
            self.lasttext = @"Yo!";
        
        if ([data[@"view"] isKindOfClass:[NSString class]]) {
            self.data = [data[@"view"] dataUsingEncoding:NSUTF8StringEncoding];
        }
        else {
            NSError * error;
            self.data = [NSJSONSerialization dataWithJSONObject:data[@"view"]
                                                        options:NSJSONWritingPrettyPrinted
                                                          error:&error];
        }
    }
    
    if (modelData[@"title"]) {
        self.lasttext = modelData[@"title"];
    }
}

- (NSString *)packetID
{
    [self willAccessValueForKey:@"packetID"];
    NSString * packetID = [self primitiveValueForKey:@"packetID"];
    [self didAccessValueForKey:@"packetID"];
    if (!packetID)
    {
        [self setPrimitiveValue:@"-1" forKey:@"packetID"];
        packetID = @"-1";
    }
    return packetID;
}

- (void)setPacketID:(NSString *)packetID
{
    [self willChangeValueForKey:@"packetID"];
    [self setPrimitiveValue:packetID forKey:@"packetID"];
    if (self.dialog)
        [self.dialog fixPositionOfMessage:self];
    [self didChangeValueForKey:@"packetID"];
}

- (void)setCreated:(NSDate *)created
{
    [self willChangeValueForKey:@"created"];
    [self setPrimitiveValue:created forKey:@"created"];
    if (self.dialog)
        [self.dialog updateLastMessage];
    [self didChangeValueForKey:@"created"];
}

- (CGFloat)heightConsoleForm
{
    return self.viewForCell.frame.size.height;
}

- (BOOL)owner
{
    return [self.fromId isEqualToString:[CoreDataFacade sharedInstance].ownerUDID];
}

- (void)concatTextMessage:(NSString *)newText
{
    NSDictionary * data = [[ParamsFacade sharedInstance] dictionaryFromNSData:self.data];
    
    self.textMessage = [newText stringByAppendingString:[NSString stringWithFormat:@"\n\n%@",data[@"text"]]];
}

- (void)updateWithText:(NSString *)text encryptionEnabled:(BOOL)encryptionEnabled
{
    self.encrypted = @(encryptionEnabled);
    self.textMessage = text;

    if (encryptionEnabled) {
        self.lasttext = @"lst_msg_text_for_lc_encrypted_text_ios";
    }
    else {
        self.lasttext = text;
        self.data = [[ParamsFacade sharedInstance] NSDataFromNSDictionary:@{@"text":text,@"pkey":@""}];
    }
}

- (Dialog *)fmlDialog
{
    return self.dialog;
}

@end
