//
//  CameraManager.h
//  SENDER
//
//  Created by Nick Gromov on 11/14/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CameraType) {
    CameraTypeImage,
    CameraTypeVideo
};


@class CameraManager;
@class Dialog;

@protocol CameraManagerDelegate <NSObject>

- (void)cameraManager:(CameraManager *)camera sendImageToServer:(UIImage *)image forURL:(NSString *)urlSting;

@end

@interface CameraManager : NSObject <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

- (id)initWithParentController:(UIViewController *)controller chat:(Dialog *)chat;
- (void)showCamera;
@property (nonatomic, assign) id<CameraManagerDelegate> delegate;

@end
