//
//  PBSubViewFacade.m
//  ZiZZ
//
//  Created by Eugene Gilko on 7/22/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBSubviewFacade.h"
#import "ServerFacade.h"
#import "CoreDataFacade.h"
#import "PBConsoleConstants.h"
#import "ConsoleCaclulator.h"
#import "BitcoinUtils.h"
#import "BitcoinManager.h"
#import "SenderNotifications.h"
#import "PBImageView.h"
#import "ChatViewController.h"
#import "ECCWorker.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "Owner.h"
#import "ChatPickerManager.h"
#import "ContactViewModel.h"
#import "ChatPickerViewController.h"
#import "TermsConditionsViewController.h"

@protocol EntityPickerModuleDelegate;

NSString * const HideKeyboard = @"HideKeyboard";
NSString * const SNotificationQRScanShow = @"SNotificationQRScanShow";
NSString * const SNotificationShowProgress = @"SNotificationShowProgress";
NSString * const SNotificationHideProgress = @"SNotificationHideProgress";
NSString * const SNotificationShowMessage = @"SNotificationShowMessage";
NSString * const SNotificationShare = @"SNotificationShare";
NSString * const SNotificationCallRobot = @"SNotificationCallRobot";

NSString * const GotoGoolgeAuth = @"GotoGoolgeAuth";

@interface PBSubviewFacade ()

@property (nonatomic, strong) NSDictionary * currentFullVersionAction;
@property (nonatomic, strong) EntityPickerModule * entityPickerModule;

@property (nonatomic, strong) QRScannerModule * qrScannerModule;
@property (nonatomic, strong) QRDisplayModule * qrDisplayModule;

@property (nonatomic, strong) TermsConditionsModule * termsConditionsModule;

@end

@implementation PBSubviewFacade

- (id)initWithRect:(CGRect)mainRect andModel:(MainConteinerModel *)submodel
{
    if (self) {
        self.viewModel = submodel;
    }
    return self;
}


- (void)dealloc
{
    NSLog(@"");
}

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainConteinerModel *)submodel
{
    submodel.view = self;
}

- (Class)viewControllerClass:(NSString *)className
{
    return NSClassFromString(className);
}

- (void)updateView
{
    
}

- (void)parseFMLString:(NSString *)originalString completionHandler:(void(^)(NSString * parsedString))completionHandler
{    
    if (originalString.length > 4 && [[originalString substringToIndex:3] isEqualToString:@"{{!"]) {
        NSString * valName = @"User name hidden";
        NSString * valPhone = @"Phone hidden";
        NSString * valDescription = @"User description hidden";
        NSString * valBtcAddress = @"BTC Address";

        NSString * tmp = [originalString substringFromIndex:8];
        tmp = [tmp substringToIndex:tmp.length - 2];
        NSArray * urls = [tmp componentsSeparatedByString:@"."];

        BOOL isOwnersInfo = NO;
        if ([urls[0] isEqualToString:[CoreDataFacade sharedInstance].ownerUDIDString] || [urls[0] isEqualToString:@"me"])
        {
            isOwnersInfo = YES;
            valName = [CoreDataFacade sharedInstance].getOwner.name;
            valPhone = [CoreDataFacade sharedInstance].getOwner.numberPhone;
            valDescription = [CoreDataFacade sharedInstance].getOwner.desc;
            valBtcAddress = [[CoreDataFacade sharedInstance].getOwner getMainWallet:nil].paymentKey.compressedPublicKeyAddress.string;
        }
        else
        {
            NSString * userID;
            if ([urls[0] isEqualToString:@"!user"])
                userID = userIDFromChatID(self.viewModel.chat.chatID);
            else
                userID = urls[0];
            Contact * contact = [[CoreDataFacade sharedInstance] selectContactById:userID];
            if (contact)
            {
                valName = contact.name;
                valPhone = [contact getPhoneFormatted:NO];
                valDescription = contact.contactDescription;
                valBtcAddress = contact.bitcoinAddress;
            }
        }

        if ([urls[1] isEqualToString:@"name"]) {
            completionHandler(valName);
        }
        else if ([urls[1] isEqualToString:@"desc"]) {
            completionHandler(valDescription);
        }
        else if ([urls[1] isEqualToString:@"phone"]) {
            completionHandler(valPhone);
        }
        else if ([urls[1] isEqualToString:@"btc_addr"]) {
            completionHandler(valBtcAddress);
        }
        else if ([urls[1] isEqualToString:@"btc_balance"]) {
            if (!isOwnersInfo)
            {
                completionHandler(@"");
                return;
            }
            BitcoinWallet * defaultWallet = [[CoreDataFacade sharedInstance].getOwner getMainWallet:nil];
            [[ServerFacade sharedInstance] getUnspentTransactionsForWallet:defaultWallet
                                                         completionHandler:^(NSArray *unspentTransactions, NSError *error) {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 defaultWallet.unspentOutputs = unspentTransactions;
                                                                 completionHandler(defaultWallet.balance);
                                                             });
                                                         }];
        }
    }
    else {
        completionHandler(originalString);
    }
}

- (void)selectContactActionShowAll:(BOOL)showAll;
{
    NSArray * contacts;
    if (showAll)
        contacts = [[CoreDataFacade sharedInstance] getAllContacts];
    else
        contacts = [[CoreDataFacade sharedInstance] getUsers];

    NSMutableArray * chatCellModels = [NSMutableArray array];

    for (Contact * contact in contacts)
    {
        /*
         * We interested in phone numbers when we showing all contacts
         * So we don't include users without phones
         */
        if (!showAll || [[contact getPhoneFormatted:NO] length])
            [chatCellModels addObject:[[ContactViewModel alloc] initWithContact:contact]];
    }

    self.entityPickerModule = [[EntityPickerModule alloc]init];
    UIViewController * rootViewController = [self.delegate presentingViewController];
    ModalInNavigationWireframe * wireframe = [[ModalInNavigationWireframe alloc] initWithRootView:rootViewController];
    [self.entityPickerModule presentWithWireframe:wireframe
                                     entityModels:chatCellModels
                          allowsMultipleSelection:NO
                                      forDelegate:self
                                       completion:nil];
}

- (void)launchQRScanning
{
    self.qrScannerModule = [[QRScannerModule alloc] init];
    UIViewController * rootViewController = [self.delegate presentingViewController];
    ModalInNavigationWireframe * wireframe = [[ModalInNavigationWireframe alloc] initWithRootView:rootViewController];
    [self.qrScannerModule presentWithWireframe:wireframe forDelegate:self completion: nil];
}

- (void)qrScannerModuleDidCancel
{
    [self.qrScannerModule dismissWithCompletion:nil];
}

- (void)qrScannerModuleDidFinishWithString:(NSString *)string
{
    NSDictionary * parsedString = parseBitcoinQRString(string);
    
    if (parsedString[kBitcoinQRPublicAddress]) {
        MainConteinerModel * modelBitCoinPay = [self.viewModel findModelWithName:actionField];
        
        if (modelBitCoinPay) {
            modelBitCoinPay.val = parsedString[kBitcoinQRPublicAddress];
            modelBitCoinPay.bitcoinAddress = modelBitCoinPay.val;
            [modelBitCoinPay updateView];
        }
//        [self.viewModel setValue:parsedString[kBitcoinQRPublicAddress] forField:actionField];
        
        [self.viewModel setValue:parsedString[kBitcoinQRAmount] forField:fieldToSetAmount];
    }
    else {
        MainConteinerModel * modelBitCoinPay = [self.viewModel findModelWithName:actionField];
        
        if (modelBitCoinPay) {
            modelBitCoinPay.val = string;
            modelBitCoinPay.bitcoinAddress = string;
            [modelBitCoinPay updateView];
        }
    }
    
    actionField = @"";
    fieldToSetAmount = @"";
    [self.qrScannerModule dismissWithCompletion:nil];
}

- (void)actionCallPhone:(NSDictionary *)action
{
    NSString * phoneUrl = [@"telprompt://" stringByAppendingString:action[@"phone"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneUrl]];
}

- (void)actionSelectUser:(NSDictionary *)action
{
    [self selectContactActionShowAll:![action[@"reg"] boolValue]];
    actionField = action[@"to"];
    autoSubmit = [action[@"autosubmit"] boolValue];
}

- (void)actionRunRobots:(NSDictionary *)action
{
    NSMutableDictionary * robotInfo = [action mutableCopy];
    NSMutableDictionary * model = [[NSMutableDictionary alloc] initWithDictionary:[self.viewModel.topModel getDataFromModel]];
    [model setValuesForKeysWithDictionary:[self.viewModel getDataFromModel]];
    if (action[@"data"]) {
        for (id key in action[@"data"])
            model[key] = action[@"data"][key];
    }
    robotInfo[@"data"] = [model copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:SNotificationCallRobot
                                                        object:self
                                                      userInfo:[robotInfo copy]];
}

- (void)actionQRScan
{
    [[NSNotificationCenter defaultCenter]  postNotificationName:SNotificationQRScanShow object:nil];
}

- (void)actionQRScanWithReturnedValue:(NSDictionary *)action
{
    actionField = action[@"to"];
    fieldToSetAmount = action[@"to_amt"];
    [self launchQRScanning];
}

- (void)actionGoTo:(NSDictionary *)action
{
//    if (action[@"to"]) {
//        [SENDER_SHARED_CORE.router presentChatViewForChatWithID:action[@"to"]
//                                                       animated:YES
//                                                        actions:nil
//                                                        options:nil
//                                                        modally:NO];
//    }
//    else {
//        [SENDER_SHARED_CORE.router presentMainViewControllerAnimated:YES modally:NO];
//    }
}

- (void)actionViewLink:(NSDictionary *)action
{
    NSString * externUrl = action[@"link"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:externUrl]];
}

- (void)actionSendBitCoin:(NSDictionary *)action
{
    MainConteinerModel * addressModel = [self.viewModel findModelWithName:action[@"addr"]];
    MainConteinerModel * amountModel = [self.viewModel findModelWithName:action[@"summ"]];
    
    if (addressModel && amountModel) {
        NSString * address = addressModel.bitcoinAddress;
        NSString * amount = amountModel.val;
        
        BitcoinManager * btcManager = [[BitcoinManager alloc]init];
        
        [btcManager transferMoneyFromWallet:[[CoreDataFacade sharedInstance].getOwner getMainWallet:nil]
                                  toAddress:address
                                 withAmount:amount
                          completionHandler:^(NSDictionary *response, NSError *error) {
        }];
    }
}

- (void)showStringAsQR:(NSDictionary *)action
{
    [self parseFMLString:action[@"value"] completionHandler:^(NSString *parsedString) {
        if (!parsedString)
            return;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.qrDisplayModule = [[QRDisplayModule alloc] init];
            UIViewController * rootViewController = [self.delegate presentingViewController];
            ModalInNavigationWireframe * wireframe = [[ModalInNavigationWireframe alloc] initWithRootView:rootViewController];
            [self.qrDisplayModule presentWithWireframe:wireframe
                                              qrString:parsedString
                                           forDelegate:self
                                            completion: nil];
        });
    }];
}

- (void)qrDisplayModuleDidCancel
{
    [self.qrDisplayModule dismissWithCompletion:nil];
}

- (void)actionShare:(NSDictionary *)action
{
    [self parseFMLString:action[@"value"] completionHandler:^(NSString *parsedString) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SNotificationShare
                                                            object:self
                                                          userInfo:@{@"parsedString": parsedString}];
    }];
}

- (void)copyToClipboard:(NSDictionary *)action
{
    [self parseFMLString:action[@"value"] completionHandler:^(NSString *parsedString) {
        
        UIPasteboard * pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = parsedString;
    }];
}

- (void)doAction:(NSDictionary *)action
{
    switch ([self.viewModel detectAction:action]) {
        case NONE:
            return;
            break;
        case CallPhone:
            [self actionCallPhone:action];
            break;
        case SelectUser:
            [self actionSelectUser:action];
            break;
        case RunRobots:
            [self actionRunRobots:action];
            break;
        case QrScan:
            [self actionQRScan];
            break;
        case ScanQrTo:
            [self actionQRScanWithReturnedValue:action];
            break;
        case GoToSomeWhere:
            [self actionGoTo:action];
            break;
        case ViewLink:
            [self actionViewLink:action];
            break;
        case SendBtc:
            [self actionSendBitCoin:action];
            break;
        case ShowBtcArhive:
            break;
        case ShowBtcNotas:
            break;
        case Share:
            [self actionShare:action];
            break;
        case ShowAsQr:
            [self showStringAsQR:action];
            break;
        case ChangeFullVersion:
            [self changeFullVersion:action];
            break;
        case Copy:
            [self copyToClipboard:action];
            break;
        case SubmitOnChange:
            [self submitOnchangeAction:action];
            break;
        case LoadFile:
            [self loadLinkedFile:action];
            break;
        case SetGoogleToken:
            [self checkGoogleAuth];
            break;
        case ReCryptKey:
            if (![[SenderCore sharedCore] isBitcoinEnabled])
                [self showEncryptionUnavailableInRestrictedAlert];
            else
                [self reCryptKeyForBitSign:action];
            break;
        case Coords:
            break;
        default:
            return;
    }
}

- (void)showEncryptionUnavailableInRestrictedAlert
{
    NSString * title = SenderFrameworkLocalizedString(@"encryption_restricted_mode_unavailable_alert_title", nil);
    NSString *  message = SenderFrameworkLocalizedString(@"encryption_restricted_mode_unavailable_alert_message", nil);
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:title
                                                                              message:message
                                                                       preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"ok_ios", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:nil];

    [alertController addAction:cancelAction];
    UIViewController * rootController = [self.delegate presentingViewController];

    [alertController mw_safePresentInViewController:rootController animated:YES completion:nil];
}

-(void)changeFullVersion:(NSDictionary *)action
{
    if (self.currentFullVersionAction)
        return;

    self.currentFullVersionAction = action;
    BOOL fullVersion = [action[@"full"] boolValue];
    if (!fullVersion)
        [self changeFullVersionState:fullVersion action:action];
    else
        [self showTermsAndConditions];
}

- (void)showTermsAndConditions
{
    self.termsConditionsModule = [[TermsConditionsModule alloc] init];
    UIViewController * rootViewController = [self.delegate presentingViewController];
    ModalInNavigationWireframe * wireframe = [[ModalInNavigationWireframe alloc] initWithRootView:rootViewController];
    [self.termsConditionsModule presentWithWireframe:wireframe
                                         forDelegate:self
                                          completion:nil];
}

- (void)changeFullVersionState:(BOOL)state action:(NSDictionary *)action
{
    [[NSNotificationCenter defaultCenter]postNotificationName:SNotificationShowProgress object:nil];
    NSString *chatID = action[@"chatId"];
    [[SenderCore sharedCore] changeFullVersionState:state completion:^(NSError *error)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:SNotificationHideProgress object:nil];
        if (error)
        {
            NSString *alertText;
            if (error.code == 1)
                alertText = SenderFrameworkLocalizedString(@"full_version_already_on", nil);
            else if (error.code == 2)
                alertText = SenderFrameworkLocalizedString(@"full_version_already_off", nil);
            else
                alertText = @"";
            [self setActive:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:SNotificationShowMessage
                                                                object:alertText];
        }
        self.currentFullVersionAction = nil;
    }];
}

- (void)checkGoogleAuth
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GotoGoolgeAuth" object:self];
}

- (void)reCryptKeyForBitSign:(NSDictionary *)action
{
    NSString * oldKeyB58 = action[@"keyCrypted"];
    NSData * myKeyData = BTCDataFromBase58([[[[CoreDataFacade sharedInstance] getOwner] getMainWallet:nil] base58PublicKey]);
    NSString * decriptedKey = [[ECCWorker sharedWorker] eciesDecriptMEssage:oldKeyB58
                                                                withPubKeyData:myKeyData
                                                                     shortkEkm:YES
                                                                     usePubKey:NO];
    
    if (decriptedKey.length > 0)
    {

        NSData * keyData = BTCDataFromBase58(action[@"pubKey"]);
        
        if (keyData.length < 32)
            return;
        
        NSString * convertedKey = [[ECCWorker sharedWorker] eciesEncriptMEssage:decriptedKey
                                                                 withPubKeyData:keyData
                                                                      shortkEkm:YES
                                                                      usePubKey:NO];
        
        MainConteinerModel * model = [self.viewModel findModelWithName:action[@"to"]];
        
        if (model) {
            model.val = convertedKey;
            [self.delegate submitOnChange:nil];
        }
    }
}

- (void)loadLinkedFile:(NSDictionary *)action
{
    loadTmpaction = action;
    
    UIViewController * rootController = self.delegate.presentingViewController;
    cameraManager = [[CameraManager alloc] initWithParentController:rootController
                                                               chat:self.viewModel.chat];

    cameraManager.delegate = self;
    [cameraManager showCamera];
}

- (void)cameraManager:(CameraManager *)camera sendImageToServer:(UIImage *)image forURL:(NSString *)urlSting
{
    NSData * imageData = UIImageJPEGRepresentation(image, 0.4);
    
    [[ServerFacade sharedInstance] uploadFileFormFormAsset:imageData
                                         completionHandler:^(NSDictionary *response, NSError *error) {
        
        MainConteinerModel * model = [self.viewModel findModelWithName:loadTmpaction[@"to"]];
        
        if (model) {
            model.val = response[@"url"];
        }
        
        if ([self.viewModel.type isEqualToString:@"img"]) {
            [self setImage:imageData];
        }
        
        camera.delegate = nil;

        [[self.delegate presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    }];
}

//TODO: Implement
-(void)setImage:(NSData *)imageData {

}

- (void)submitOnchangeAction:(NSDictionary *)action
{
    [self.delegate submitOnChange:action];
}

- (void)setActive:(BOOL)active {}

@end

@interface PBSubviewFacade (TermsConditionsModuleDelegate) <TermsConditionsModuleDelegate>
@end

@implementation PBSubviewFacade (TermsConditionsModuleDelegate)

- (void)termsConditionsModuleDidAccept
{
    [self.termsConditionsModule dismissWithCompletion:^{
        [self changeFullVersionState:YES action:self.currentFullVersionAction];
    }];
}

- (void)termsConditionsModuleDidDecline
{
    [self setActive:YES];
    self.currentFullVersionAction = nil;
    [self.termsConditionsModule dismissWithCompletion:nil];
}

@end

@interface PBSubviewFacade (EntityPickerModuleDelegate) <EntityPickerModuleDelegate>
@end

@implementation PBSubviewFacade (EntityPickerModuleDelegate)

- (void)entityPickerModuleDidCancel
{
    [self.entityPickerModule dismissWithCompletion:nil];
    self.entityPickerModule = nil;
}

- (void)entityPickerModuleDidFinishWithEntities:(NSArray *)entities
{
    [self.entityPickerModule dismissWithCompletion:nil];
    for (id <EntityViewModel> chatModel in entities)
    {
        if ([chatModel isKindOfClass:[ContactViewModel class]])
        {
            Contact * contact = [(ContactViewModel *)chatModel contact];

            if (contact)
            {
                [self.viewModel addUser:contact forField:actionField];
                self.viewModel.bitcoinAddress = contact.bitcoinAddress;
            }
            actionField = @"";

            NSMutableDictionary * outData = [[NSMutableDictionary alloc] init];
            if (self.viewModel.name)
                outData[self.viewModel.name] = self.viewModel.val;
            if (autoSubmit)
                [self submitOnchangeAction:[outData copy]];
        }
    }
    self.entityPickerModule = nil;
}

@end
