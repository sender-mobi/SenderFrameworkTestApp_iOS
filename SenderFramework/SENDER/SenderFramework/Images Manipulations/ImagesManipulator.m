//
// Created by Roman Serga on 8/6/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import "ImagesManipulator.h"
#import "Dialog.h"
#import "Contact.h"
#import <SDWebImage/UIView+WebCache.h>
#import <SDWebImage/UIButton+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageEffects.h"
#import "DefaultContactImageGenerator.h"
#import "NSURL+PercentEscapes.h"
#import "Owner.h"

#define maxImageSide 400.0f

UIImage * resizedImage(UIImage * image)
{
    UIImage * resizedImage;

    CGFloat biggestSide = image.size.width > image.size.height ? image.size.width : image.size.height;
    CGFloat compressRate = maxImageSide / biggestSide;
    CGFloat newWidth = image.size.width * compressRate;
    CGFloat newHeight = image.size.height * compressRate;

    CGSize newSize = CGSizeMake(newWidth, newHeight);
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return resizedImage;
}

UIImage * customizeImageForChatBackground(UIImage * image)
{
    UIImage * result;
    result = image;

    if ([SenderCore sharedCore].stylePalette.chatBackgroundImageType == ChatBackgroundImageTypeLightBlur)
        result = [UIImageEffects imageByApplyingLightEffectToImage:image];
    else if ([SenderCore sharedCore].stylePalette.chatBackgroundImageType == ChatBackgroundImageTypeDarkBlur)
        result = [UIImageEffects imageByApplyingDarkEffectToImage:image];

    return result;
}

UIImage * blur(UIImage * image)
{
    CIContext * context = [CIContext contextWithOptions:nil];
    CIImage * inputImage = [CIImage imageWithCGImage:image.CGImage];

    CIFilter * filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:10.0f] forKey:@"inputRadius"];
    CIImage * result = [filter valueForKey:kCIOutputImageKey];

    CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];

    UIImage * returnImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);

    return returnImage;
}

UIImage * scaledImageIfNeeded(CGImageRef image)
{
    bool isRetina = [[[UIDevice currentDevice] systemVersion] intValue] >= 4 && [[UIScreen mainScreen] scale] == 2.0;
    if (isRetina) {
        return [UIImage imageWithCGImage:image scale:2.0 orientation:UIImageOrientationUp];
    } else {
        return [UIImage imageWithCGImage:image];
    }
}

UIImage * reorientatedImageIfNeeded(UIImage * image)
{
    if (image.imageOrientation != UIImageOrientationUp) {

        CGAffineTransform reOrient = CGAffineTransformIdentity;
        switch (image.imageOrientation) {
            case UIImageOrientationDown:
            case UIImageOrientationDownMirrored:
                reOrient = CGAffineTransformTranslate(reOrient, image.size.width, image.size.height);
                reOrient = CGAffineTransformRotate(reOrient, M_PI);
                break;
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
                reOrient = CGAffineTransformTranslate(reOrient, image.size.width, 0);
                reOrient = CGAffineTransformRotate(reOrient, M_PI_2);
                break;
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                reOrient = CGAffineTransformTranslate(reOrient, 0, image.size.height);
                reOrient = CGAffineTransformRotate(reOrient, -M_PI_2);
                break;
            case UIImageOrientationUp:
            case UIImageOrientationUpMirrored:
                break;
        }

        switch (image.imageOrientation) {
            case UIImageOrientationUpMirrored:
            case UIImageOrientationDownMirrored:
                reOrient = CGAffineTransformTranslate(reOrient, image.size.width, 0);
                reOrient = CGAffineTransformScale(reOrient, -1, 1);
                break;
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRightMirrored:
                reOrient = CGAffineTransformTranslate(reOrient, image.size.height, 0);
                reOrient = CGAffineTransformScale(reOrient, -1, 1);
                break;
            case UIImageOrientationUp:
            case UIImageOrientationDown:
            case UIImageOrientationLeft:
            case UIImageOrientationRight:
                break;
        }

        CGContextRef myContext = CGBitmapContextCreate(NULL, image.size.width, image.size.height, CGImageGetBitsPerComponent(image.CGImage), 0, CGImageGetColorSpace(image.CGImage), CGImageGetBitmapInfo(image.CGImage));

        CGContextConcatCTM(myContext, reOrient);

        switch (image.imageOrientation) {
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                CGContextDrawImage(myContext, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
                break;

            default:
                CGContextDrawImage(myContext, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
                break;
        }

        CGImageRef CGImg = CGBitmapContextCreateImage(myContext);
        image = [UIImage imageWithCGImage:CGImg];

        CGImageRelease(CGImg);
        CGContextRelease(myContext);
    }

    return image;
}


@implementation ImagesManipulator {

}

+ (void)backgroundImageWithChat:(Dialog *)chat completionHandler :(void (^)(UIImage*))completionHandler
{
    UIImageView * temp = [[UIImageView alloc]init];

    UIImage * tempImage = [UIImage imageFromSenderFrameworkNamed:@"_bg_chat"];
    completionHandler(tempImage);

    NSURL * encodedImageURL = [NSURL URLByAddingPercentEscapesToString:chat.imageURL];

    if ([chat.imageURL length]) {
        [temp sd_setImageWithURL:encodedImageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
                UIImage * result = customizeImageForChatBackground(temp.image);
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    completionHandler(result);
                });
            });
        }];
    }
}

+ (void)backgroundImageWithURL:(NSURL *)url completionHandler :(void (^)(UIImage*))completionHandler
{
    UIImageView * temp = [[UIImageView alloc]init];

    [temp sd_setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
            UIImage * result = customizeImageForChatBackground(temp.image);
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionHandler(result);
            });
        });
    }];
}

+ (void)backgroundImageWithImage:(UIImage *)image completionHandler :(void (^)(UIImage*))completionHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
        UIImage * result = customizeImageForChatBackground(image);
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(result);
        });
    });
}

+ (void)setImageForButton:(UIButton *)button
                 forState:(UIControlState)controlState
                 withChat:(Dialog *)chat
       imageChangeHandler:(void(^ _Nullable)(BOOL))imageChangeHandler
{
    [button sd_cancelImageLoadForState:controlState];
    button.backgroundColor = chat.defaultImageBackgroundColor;
    UIImage * defaultImage = chat.defaultImage;
    NSURL * encodedImageURL = [NSURL URLByAddingPercentEscapesToString:chat.imageURL];

    if (encodedImageURL)
    {
        [button sd_setImageWithURL:encodedImageURL
                          forState:controlState
                  placeholderImage:defaultImage
                         completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                             if (image) button.backgroundColor = chat.imageBackgroundColor;
                             if (imageChangeHandler) imageChangeHandler(NO);
                         }];
    }
    else
    {
        [button setImage:defaultImage forState:controlState];
        if (imageChangeHandler) imageChangeHandler(YES);
    }
}

+ (void)setImageForImageView:(UIImageView *)imageView
                    withChat:(Dialog *)chat
        imageChangeHandler:(void(^ _Nullable)(BOOL))imageChangeHandler
{
    [imageView sd_cancelCurrentImageLoad];

    imageView.backgroundColor = chat.defaultImageBackgroundColor;
    UIImage * defaultImage = chat.defaultImage;
    NSURL * encodedImageURL = [NSURL URLByAddingPercentEscapesToString:chat.imageURL];

    if (encodedImageURL)
    {
        if (imageChangeHandler) imageChangeHandler(YES);
        [imageView sd_setImageWithURL:encodedImageURL
                     placeholderImage:defaultImage
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                if (image)
                                {
                                    imageView.backgroundColor = [UIColor whiteColor];
                                    if (imageChangeHandler) imageChangeHandler(NO);
                                }
                            }];
    }
    else
    {
        imageView.image = defaultImage;
        if (imageChangeHandler) imageChangeHandler(YES);
    }

    imageView.layer.cornerRadius = imageView.frame.size.width/2;
    imageView.layer.borderWidth = 0;
    imageView.layer.borderColor = [UIColor clearColor].CGColor;
    imageView.clipsToBounds = YES;
}

+ (void)setImageForImageView:(UIImageView *)imageView
                   withOwner:(Owner *)owner
          imageChangeHandler:(void(^ _Nullable)(BOOL))imageChangeHandler
{
    [imageView sd_cancelCurrentImageLoad];

    imageView.backgroundColor = [UIColor whiteColor];
    UIImage * defaultImage = [UIImage imageFromSenderFrameworkNamed:@"_add_photo"];
    NSURL * encodedImageURL = [NSURL URLByAddingPercentEscapesToString:owner.ownimgurl];

    if (encodedImageURL)
    {
        if (imageChangeHandler) imageChangeHandler(YES);
        [imageView sd_setImageWithURL:encodedImageURL
                     placeholderImage:defaultImage
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                if (image)
                                {
                                    imageView.backgroundColor = [UIColor whiteColor];
                                    if (imageChangeHandler) imageChangeHandler(NO);
                                }
                            }];
    }
    else
    {
        imageView.image = defaultImage;
        if (imageChangeHandler) imageChangeHandler(YES);
    }
}

+ (void)setImageForImageView:(UIImageView *)imageView
                 withContact:(Contact *)contact
          imageChangeHandler:(void(^ _Nullable)(BOOL))imageChangeHandler
{
    NSURL * encodedImageURL = [NSURL URLByAddingPercentEscapesToString:contact.imageURL];
    if ([contact.isCompany boolValue])
    {
        imageView.backgroundColor = [UIColor whiteColor];
        UIImage * defaultImage = [UIImage imageFromSenderFrameworkNamed:@"def_shop"];

        if (encodedImageURL)
        {
            if (imageChangeHandler) imageChangeHandler(YES);
            [imageView sd_setImageWithURL:encodedImageURL
                         placeholderImage:defaultImage
                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                    if (image)
                                    {
                                        imageView.backgroundColor = [UIColor whiteColor];
                                        if (imageChangeHandler) imageChangeHandler(NO);
                                    }
                                }];
        }
        else
        {
            imageView.image = defaultImage;
            if (imageChangeHandler) imageChangeHandler(YES);
        }
    }
    else
    {
        imageView.backgroundColor = contact.cellBackgroundColor;
        NSString * defaultImageName = [DefaultContactImageGenerator convertContactNameToImageName:contact.name];
        UIImage * placeHolder = [UIImage imageFromSenderFrameworkNamed:defaultImageName];

        if (encodedImageURL)
        {
            if (imageChangeHandler) imageChangeHandler(YES);
            [imageView sd_setImageWithURL:encodedImageURL
                         placeholderImage:placeHolder
                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                    if (image)
                                    {
                                        imageView.backgroundColor = [UIColor whiteColor];
                                        if (imageChangeHandler) imageChangeHandler(NO);
                                    }
            }];
        }
        else
        {
            imageView.image = placeHolder;
            if (imageChangeHandler) imageChangeHandler(YES);
        }
    }
}

@end
