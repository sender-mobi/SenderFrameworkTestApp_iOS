//
//  EncryptedTextCellView.m
//  SENDER
//
//  Created by Roman Serga on 12/1/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "EncryptedTextCellView.h"
#import "PBConsoleConstants.h"
#import "ECCWorker.h"
#import "ParamsFacade.h"
#import "SecGenerator.h"
#import "BTCBase58.h"
#import "Dialog.h"
#import "CoreDataFacade.h"

@implementation EncryptedTextCellView

-(void)initWithModel:(Message *)submodel width:(CGFloat)maxWidth timeLabelSize:(CGSize)timeLabelSize
{
    [super initWithModel:submodel width:maxWidth timeLabelSize:timeLabelSize];
    
    if (self)
    {
        messageTextView.dataDetectorTypes = UIDataDetectorTypeAll;
        
        NSDictionary * textData = [[ParamsFacade sharedInstance] dictionaryFromNSData:submodel.data];
        
        if (textData[@"ecryptData"] && submodel.dialog.isP2P) {
            self.viewModel.textMessage = [textData[@"text"] description];
        }
        
        if (self.viewModel.textMessage.length > 0 &&
            ![self.viewModel.textMessage isEqual:@"lst_msg_text_for_lc_encrypted_text_ios"])
        {
            [self setText:self.viewModel.textMessage];
        }
        else if (submodel.dialog.isP2P) {
            
            NSData * keyData = nil;
            
            if (textData[@"pkey"]) {
                
                if ([submodel.fromId isEqualToString:[CoreDataFacade sharedInstance].ownerUDID]) {
                    
                    keyData = submodel.dialog.p2pBTCKeyData;
                } else {
                    keyData = BTCDataFromBase58(textData[@"pkey"]);
                }
            }
            
            if (keyData.length < 32)
                keyData = submodel.dialog.p2pBTCKeyData;

            NSString * decriptedString = [[ECCWorker sharedWorker] eciesDecriptMEssage:textData[@"text"]
                                                                        withPubKeyData:keyData
                                                                             shortkEkm:YES
                                                                             usePubKey:NO];
            
            if (decriptedString.length < 1)
                decriptedString = @"lst_msg_text_for_lc_encrypted_text_ios";
            
            self.viewModel.textMessage = decriptedString;

            if ([self.viewModel.textMessage isEqualToString:@"lst_msg_text_for_lc_encrypted_text_ios"])
                [self setText:SenderFrameworkLocalizedString(self.viewModel.textMessage, nil)];
            else
                [self setText:self.viewModel.textMessage];
        }
        else {
            
            NSString * decriptedString = [[SecGenerator sharedInstance] decryptMessage:textData[@"text"] withDialogKey:submodel.dialog.encryptionKey];
            
            if (!decriptedString) {
                
                for (NSData * oldKeyData in submodel.dialog.oldGroupKeys) {
                   decriptedString = [[SecGenerator sharedInstance] decryptMessage:textData[@"text"] withDialogKey:oldKeyData];
                    if (decriptedString &&  decriptedString.length > 0) {
                        break;
                    }
                }
            }
            
            if (decriptedString &&  decriptedString.length > 0) {
                
                self.viewModel.textMessage = decriptedString;
            }
            else {
                LLog(@"ERROOR: Encryption error: Groupe_Key_Fail");
                self.viewModel.textMessage = @"lst_msg_text_for_lc_encrypted_text_ios";
            }

            if ([self.viewModel.textMessage isEqualToString:@"lst_msg_text_for_lc_encrypted_text_ios"])
                [self setText:SenderFrameworkLocalizedString(self.viewModel.textMessage, nil)];
            else
                [self setText:self.viewModel.textMessage];
        }
        
        [self setLeftIconHidden:YES];
    }
}

@end
