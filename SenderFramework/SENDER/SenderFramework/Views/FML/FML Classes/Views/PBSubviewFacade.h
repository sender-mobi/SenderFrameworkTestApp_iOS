//
//  PBSubViewFacade.h
//  ZiZZ
//
//  Created by Eugene Gilko on 7/22/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QRDisplayViewController.h"
#import "CameraManager.h"

@class MainConteinerModel;
@class PBSubviewFacade;
@protocol QRScannerModuleDelegate;
@protocol QRDisplayModuleDelegate;

extern NSString * const SNotificationQRScanShow;
extern NSString * const SNotificationShowProgress;
extern NSString * const SNotificationHideProgress;
extern NSString * const SNotificationShowMessage;
extern NSString * const SNotificationShare;
extern NSString * const SNotificationCallRobot;

extern NSString * const GotoGoolgeAuth;
extern NSString * const HideKeyboard;

@protocol PBSubviewDelegate <NSObject>

- (void)submitOnChange:(NSDictionary *)action;
- (UIViewController *)presentingViewController;

@end

@interface PBSubviewFacade : UIView <CameraManagerDelegate, QRScannerModuleDelegate, QRDisplayModuleDelegate>
{
    NSString * actionField;
    NSString * fieldToSetAmount;
    CameraManager * cameraManager;
    BOOL autoSubmit;
    NSDictionary * loadTmpaction;
}

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainConteinerModel *)submodel;
- (id)initWithRect:(CGRect)mainRect andModel:(MainConteinerModel *)submodel;

- (void)parseFMLString:(NSString *) originalString
     completionHandler:(void(^)(NSString * parsedString))completionHandler;
- (void)updateView;

- (void)selectContactActionShowAll:(BOOL)showAll;
- (void)launchQRScanning;
- (void)doAction:(NSDictionary *)action;
- (void)setImage:(NSData *)imageData;
- (void)submitOnchangeAction:(NSDictionary *)action;

//By default does nothing. Override in subclasses
- (void)setActive:(BOOL)active;

@property (nonatomic, weak) MainConteinerModel * viewModel;

@property (nonatomic, assign) id<PBSubviewDelegate> delegate;

@end
