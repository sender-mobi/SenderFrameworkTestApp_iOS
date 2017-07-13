//
//  VideoMenager.h
//  SENDER
//
//  Created by Eugene on 12/11/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoManager : NSObject  <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

- (id)initWithParentController:(UIViewController *)controller chatId:(NSString *)chatId;
- (void)showCamera;

@end
