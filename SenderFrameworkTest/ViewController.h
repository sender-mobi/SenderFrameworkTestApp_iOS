//
//  ViewController.h
//  SenderFrameworkTest
//
//  Created by Roman Serga on 13/4/17.
//  Copyright © 2017 Roman Serga. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UnreadMessagesCountChangesHandler;
@protocol QRScannerModuleDelegate;

@interface ViewController : UIViewController <UnreadMessagesCountChangesHandler, QRScannerModuleDelegate>

@property (weak, nonatomic) IBOutlet UITextField *chatIDTextField;
@property (weak, nonatomic) IBOutlet UILabel *unreadCountLabel;

@end

