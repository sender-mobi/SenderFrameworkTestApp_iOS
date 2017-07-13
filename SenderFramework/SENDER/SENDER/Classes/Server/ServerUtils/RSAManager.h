//
//  RSAManager.h
//  SENDER
//
//  Created by Eugene Gilko on 11/26/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

@interface RSAManager : NSObject {
    SecKeyRef publicKey;
    SecKeyRef privateKeyRSA;
    NSString * publicTagString;
    NSString * privateTagString;
    NSData * publicTag;
    NSData * privateTag;
}

- (void)generateRSAKeys;

- (NSString *)encodeMessage:(NSString *)messageText
          andSaveToMessage:(Message *)message
         withUserPublicKey:(NSString *)pubKey;

- (Message *)decodeMessage:(Message *)message;

@end
