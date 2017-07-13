//
//  ViewController.m
//  SenderFrameworkTest
//
//  Created by Roman Serga on 13/4/17.
//  Copyright © 2017 Roman Serga. All rights reserved.
//

#import "ViewController.h"
#import <SenderFramework/SenderFramework.h>
#import <SenderFramework/SenderFramework-Swift.h>

@interface ViewController ()
    @property (nonatomic, strong) SenderUI * senderUI;
    @property (nonatomic, strong) QRScannerModule * scannerModule;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.senderUI = [[SenderUI alloc] initWithRootViewController:self.navigationController];
    [[SenderCore sharedCore].interfaceUpdater addUpdatesHandler:self];
    NSInteger unreadCount = [SenderCore sharedCore].unreadMessagesCounter.unreadMessagesCount;
    self.unreadCountLabel.text = [NSString stringWithFormat:@"%i", (int) unreadCount];
    self.chatIDTextField.text = @"user+sender";
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)goToChat:(id)sender {
    NSString * chatID = self.chatIDTextField.text;
    if ([chatID length])
    {
        [self.senderUI showChatScreenWithChatID:chatID
                                        actions:nil
                                        options:nil
                                       animated:YES
                                        modally:NO
                                       delegate:nil];
    }
}

- (IBAction)addUnreadMessage:(id)sender
{
    NSString * chatID = self.chatIDTextField.text;
    if ([chatID length])
    {
        MWChatBuildManager * chatBuildManager = [MWChatBuildManager buildDefaultChatBuildManager];
        Dialog * chat = [chatBuildManager chatWithChatID:chatID isNewChat:NULL];
        [[CoreDataFacade sharedInstance] checkForDialogSetting:chat];
        Message * fakeIncomingMessage = [[CoreDataFacade sharedInstance] writeMessageWithText:@"Fake Message Text"
                                                                                       inChat:chatID
                                                                                    encripted:NO];
        fakeIncomingMessage.fromId = @"FakeUserID";
        chat.unreadCount = @([chat.unreadCount integerValue] + 1);
        [[CoreDataFacade sharedInstance] saveContext];
        [[SenderCore sharedCore].interfaceUpdater chatsWereChanged:@[chat]];
    }
}

- (IBAction)showChatList:(id)sender {
    [self.senderUI showChatListWithAnimated:YES modally:NO forDelegate:nil];
}

- (IBAction)scanQR:(id)sender
{
    self.scannerModule = [self.senderUI showQRScannerWithDelegate:self animated:YES modally:NO];
}

- (void)handleUnreadMessagesCountChange:(NSInteger)newUnreadMessagesCount
{
    self.unreadCountLabel.text = [NSString stringWithFormat:@"%i", (int) newUnreadMessagesCount];
}

- (void)qrScannerModuleDidCancel
{
    [self.scannerModule dismissWithCompletion:nil];
    self.scannerModule = nil;
}

- (void)qrScannerModuleDidFinishWithString:(NSString *_Nonnull)string
{
    NSLog(@"Scanned string: %@", string);
    [self.scannerModule dismissWithCompletion:nil];
    self.scannerModule = nil;
}


@end
