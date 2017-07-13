//
// Created by Roman Serga on 8/6/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

UIImage * imageWithAlpha(UIImage * image, CGFloat alpha);
UIImage * resizedImage(UIImage * image);
UIImage * customizeImageForChatBackground(UIImage  * image);
UIImage * scaledImageIfNeeded(CGImageRef image);
UIImage * blur(UIImage * image);

@class Dialog;
@class Contact;
@class Owner;

@interface ImagesManipulator : NSObject

/*
 * It's possible that completion handler may be called twice. First, to return default chat image.
 * And second to return real image for chat.
 */
+ (void)backgroundImageWithChat:(Dialog *)chat completionHandler :(void (^)(UIImage*))completionHandler;
+ (void)backgroundImageWithImage:(UIImage *)image completionHandler :(void (^)(UIImage*))completionHandler;
+ (void)backgroundImageWithURL:(NSURL *)url completionHandler :(void (^)(UIImage*))completionHandler;

+ (void)setImageForButton:(UIButton *)button
                 forState:(UIControlState)controlState
                 withChat:(Dialog *)chat
       imageChangeHandler:(void(^ _Nullable)(BOOL))imageChangeHandler;

+ (void)setImageForImageView:(UIImageView *)imageView
                    withChat:(Dialog *)chat
          imageChangeHandler:(void(^ _Nullable)(BOOL))imageChangeHandler;

+ (void)setImageForImageView:(UIImageView *)imageView
                   withOwner:(Owner *)owner
          imageChangeHandler:(void (^ _Nullable)(BOOL))imageChangeHandler;

+ (void)setImageForImageView:(UIImageView *)imageView
                 withContact:(Contact *)contact
          imageChangeHandler:(void(^ _Nullable)(BOOL))imageChangeHandler;

@end
