//
//  MessagesGap+CoreDataProperties.h
//  SENDER
//
//  Created by Roman Serga on 8/7/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "MessagesGap.h"

NS_ASSUME_NONNULL_BEGIN

@interface MessagesGap (CoreDataProperties)

/*
 * We load chat history starting from bigger packetID. So, startPacketID must be bigger or equal to endPacketID.
 */
@property (nullable, nonatomic, retain) NSNumber *startPacketID;
@property (nullable, nonatomic, retain) NSNumber *endPacketID;
@property (nullable, nonatomic, retain) Dialog * dialog;
@property (nullable, nonatomic, retain) NSDate * created;

@end

NS_ASSUME_NONNULL_END
