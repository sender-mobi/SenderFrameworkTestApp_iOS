//
//  CameraManager.m
//  SENDER
//
//  Created by Nick Gromov on 11/14/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "CameraManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CoreDataFacade.h"
#import "FileManager.h"
#import "ServerFacade.h"
#import "CometController.h"
#import <AVFoundation/AVFoundation.h>

@class UsePhotoViewController;

@protocol UsePhotoViewControllerDelegate <NSObject>

- (void)usePhotoViewControllerDidCancel:(UsePhotoViewController *)controller;
- (void)usePhotoViewControllerDidDismiss:(UsePhotoViewController *)controller;
- (void)usePhotoViewControllerDidAccept:(UsePhotoViewController *)controller;

@end

@interface UsePhotoViewController: UIViewController

@property (nonatomic, weak) id<UsePhotoViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIImageView * imageView;

@end

@implementation UsePhotoViewController

+ (instancetype)controller
{
    NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
    return [[self alloc] initWithNibName:@"UsePhotoViewController" bundle:NSBundle.senderFrameworkResourcesBundle];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (IBAction)cancelButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(usePhotoViewControllerDidCancel:)])
        [self.delegate usePhotoViewControllerDidCancel:self];
}

- (IBAction)acceptButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(usePhotoViewControllerDidAccept:)])
        [self.delegate usePhotoViewControllerDidAccept:self];
}

- (IBAction)dismissButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(usePhotoViewControllerDidDismiss:)])
        [self.delegate usePhotoViewControllerDidDismiss:self];
}

@end

@interface CameraManager () {
    __weak UIViewController * parentController;
    __weak UIImagePickerController * imagePickerController;
    CameraType cameraType;
    BOOL isRecording;
    NSURL * localUrl;
    UIImage * image;
    Dialog * currentChat;

    IBOutlet UIImageView * photoImageView;
    __strong IBOutlet UIView * overlayCameraView;
    IBOutlet UIView * bottomBar;
    __strong IBOutlet UIView * usePhotoCameraView;
    __strong IBOutlet UIButton * backButton;
    IBOutlet UIButton * cancelButton;
    IBOutlet UIButton * changeCameraButton;
    IBOutlet UIButton * changeTypeButton;
    IBOutlet UIButton * startButton;
    IBOutlet UIButton * libraryButton;
    IBOutlet UIButton * flashModeButton;
}
//// overlayCameraView buttons
- (IBAction)cancelButtonClick:(id)sender;
- (IBAction)changeCameraButtonClick:(id)sender;
- (IBAction)changeTypeButtonClick:(id)sender;
- (IBAction)startButtonClick:(id)sender;
- (IBAction)libraryButtonClick:(id)sender;
- (IBAction)changeFlashModeButtonClick:(id)sender;
- (IBAction)usePhotoButtonClick:(id)sender;
- (IBAction)backButtonClick:(id)sender;

@end

@implementation CameraManager

- (id)initWithParentController:(UIViewController *)controller chat:(Dialog *)chat
{
    if (self = [super init]) {
        parentController = controller;
        cameraType = CameraTypeImage;
        isRecording = NO;
        currentChat = chat;
    }
    return self;
}

- (void)dealloc
{
    imagePickerController = nil;
    parentController = nil;
}

- (void)showCamera
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus != AVAuthorizationStatusAuthorized)
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
         {
             if(granted)
             {
                 // NSLog(@"Granted access to %@", AVMediaTypeVideo);
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self popCamera];
                 });
             }
             else
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self showCameraPermissionAlert];
                 });
             }
         }];
    }
    else {
        [self popCamera];
    }
}

- (void)popCamera
{
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.allowsEditing = NO;
    picker.delegate = self;
    picker.showsCameraControls = NO;
    picker.mediaTypes = @[(NSString *) kUTTypeImage,(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4];

    NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
    [NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"OverlayCameraView" owner:self options:nil];
    overlayCameraView.frame =  CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    picker.cameraOverlayView = overlayCameraView;
    
    float yOffset = 44.0;
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, yOffset);
    CGFloat widthScale = SCREEN_WIDTH / 320.0f;
    CGFloat heightScale = SCREEN_HEIGHT / 568.0f + 0.1f;
    
    picker.cameraViewTransform = CGAffineTransformScale(translate, widthScale, heightScale);
    overlayCameraView = nil;
    [parentController presentViewController:picker animated:YES completion:NULL];
    imagePickerController = picker;
}

- (IBAction)cancelButtonClick:(id)sender
{
    [parentController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)changeCameraButtonClick:(id)sender
{
    if (imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
        imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    else {
        imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
    flashModeButton.hidden = ![UIImagePickerController isFlashAvailableForCameraDevice:imagePickerController.cameraDevice];
}

- (IBAction)changeTypeButtonClick:(id)sender
{
    if (cameraType == CameraTypeImage) {
        cameraType = CameraTypeVideo;
        imagePickerController.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *) kUTTypeMovie, nil];
        
        [startButton setBackgroundImage:[UIImage imageFromSenderFrameworkNamed:@"start_recording"] forState:UIControlStateNormal];
        [changeTypeButton setBackgroundImage:[UIImage imageFromSenderFrameworkNamed:@"media_photo"] forState:UIControlStateNormal];
    }
    else {
        cameraType = CameraTypeImage;
        imagePickerController.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
        
        [startButton setBackgroundImage:[UIImage imageFromSenderFrameworkNamed:@"button_take_photo"] forState:UIControlStateNormal];
        [changeTypeButton setBackgroundImage:[UIImage imageFromSenderFrameworkNamed:@"media_camera"] forState:UIControlStateNormal];
        [flashModeButton setHidden:[UIImagePickerController isFlashAvailableForCameraDevice:imagePickerController.cameraDevice]];
    }
}

- (IBAction)startButtonClick:(id)sender
{
    if (cameraType == CameraTypeImage) {
        [imagePickerController takePicture];
    }
    else {
        if (!isRecording) {
            isRecording = [imagePickerController startVideoCapture];
        }
        else {
            [imagePickerController stopVideoCapture];
        }
    }
}

- (IBAction)libraryButtonClick:(id)sender
{
    if (imagePickerController.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//        imagePickerController.mediaTypes = @[(NSString *) kUTTypeImage,(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4];
    }
}

- (IBAction)changeFlashModeButtonClick:(id)sender
{
    UIButton * button = (UIButton *)sender;
    if ([UIImagePickerController isFlashAvailableForCameraDevice:imagePickerController.cameraDevice]) {
        if (imagePickerController.cameraFlashMode == UIImagePickerControllerCameraFlashModeAuto) {
            imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
            [button setImage:[UIImage imageFromSenderFrameworkNamed:@"flash_disabled"] forState:UIControlStateNormal];
        }
        else {
            imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
            [button setImage:[UIImage imageFromSenderFrameworkNamed:@"flash_auto"] forState:UIControlStateNormal];
        }
        [button setHidden:NO];
    }
    else {
        [button setHidden:YES];
    }
}

- (IBAction)usePhotoButtonClick:(id)sender
{
    UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:SenderFrameworkLocalizedString(@"send_photo", nil)
                                                          message:SenderFrameworkLocalizedString(@"send_photo_question_ios", nil)
                                                         delegate:self
                                                cancelButtonTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                otherButtonTitles: SenderFrameworkLocalizedString(@"ok_ios", nil),nil];

    [myAlertView show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title
              isEqualToString:SenderFrameworkLocalizedString(@"error_camera_not_available", nil)])
    {
        if (buttonIndex != [alertView cancelButtonIndex])
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
    else
    {
        if (buttonIndex == 1)
        {
          [self.delegate cameraManager:self sendImageToServer:[image copy] forURL:localUrl.absoluteString];
          image = nil;
        }
        else
        {
          image = nil;
          [self backButtonClick:self];
        }
    }
}

- (void)sendImageData:(NSData *)imageData
{
    
}

- (IBAction)backButtonClick:(id)sender
{
    if (imagePickerController.sourceType == UIImagePickerControllerSourceTypeCamera)
    {
        [imagePickerController dismissViewControllerAnimated:NO completion:nil];
    }
    else
    {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
        [NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"OverlayCameraView" owner:self options:nil];
        overlayCameraView.frame = imagePickerController.cameraOverlayView.frame;
        imagePickerController.cameraOverlayView = overlayCameraView;
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString * type = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ([type isEqualToString:(NSString *)kUTTypeVideo] || [type isEqualToString:(NSString *)kUTTypeMovie]) {
        
        [self getVideoThumbnail:(NSURL *)[info valueForKey:UIImagePickerControllerReferenceURL]];
        [parentController.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        localUrl = (NSURL *)[info valueForKey:UIImagePickerControllerReferenceURL];
        image = (UIImage*)[info objectForKey:UIImagePickerControllerOriginalImage];

        UsePhotoViewController * usePhotoViewController = [UsePhotoViewController controller];
        usePhotoViewController.delegate = self;
        usePhotoViewController.view;
        usePhotoViewController.imageView.image = image;

        [imagePickerController presentViewController:usePhotoViewController animated:NO completion:nil];
    }
}

- (void)getVideoThumbnail:(NSURL *)videoURL
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], AVURLAssetPreferPreciseDurationAndTimingKey, nil]];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    NSTimeInterval durationInSeconds = 0.0;
    if (asset)
        durationInSeconds = CMTimeGetSeconds(asset.duration);
    __block float durationOfFile = durationInSeconds;
    asset = nil;
    
    generator.appliesPreferredTrackTransform=TRUE;
    CMTime thumbTime = CMTimeMakeWithSeconds(0,30);
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result != AVAssetImageGeneratorSucceeded) {
            // LLog(@"couldn't generate thumbnail, error:%@", error);
        }
        UIImage * thumbnail = [UIImage imageWithCGImage:im];
        if (thumbnail != nil){
           UIImage * finalImage = thumbnail;
            [self sendDataToServer:videoURL duration:durationOfFile image:finalImage];
        }
    };
    
    CGSize maxSize = CGSizeMake(600, 600);
    generator.maximumSize = maxSize;
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
}

- (void)sendDataToServer:(NSURL *)videoURL duration:(float)durationOfFile image:(UIImage *)finalImage
{
    if (!currentChat.chatID)
    {
        [self backButtonClick:nil];
        return;
    }

    finalImage = [self squareImageWithImage:finalImage scaledToSize:CGSizeMake(300, 300)];
    
    NSData * imageData = UIImageJPEGRepresentation(finalImage, 0.6);
    
    [[ServerFacade sharedInstance] sendVideoMessage:nil
                                       fromLocalURL:videoURL
                                          imageData:imageData
                                      videoDuration:durationOfFile
                                             chatId:currentChat.chatID
                                  completionHandler:^(NSDictionary *response, NSError *error) {
        if (!error) {
            
        }
    }];
}

- (UIImage *)squareImageWithImage:(UIImage *)curImage scaledToSize:(CGSize)newSize {
    double ratio;
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.height);
    
    if (curImage.size.width > curImage.size.height) {
        ratio = newSize.width / curImage.size.width;
        
    } else {
        ratio = newSize.height / curImage.size.height;
    }
    
    CGRect clipRect = CGRectMake(0, 0,
                                 (ratio * curImage.size.width),
                                 (ratio * curImage.size.height));
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [curImage drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)showCameraPermissionAlert
{
    UIAlertView * cameraNotAvailiableAlert = [[UIAlertView alloc] initWithTitle:SenderFrameworkLocalizedString(@"error_camera_not_available", nil)
                                                                        message:nil
                                                                       delegate:self
                                                              cancelButtonTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                              otherButtonTitles:SenderFrameworkLocalizedString(@"error_camera_not_available_go_to_settings", nil), nil];
    [cameraNotAvailiableAlert show];
}

@end

@interface CameraManager (UsePhotoViewControllerDelegate) <UsePhotoViewControllerDelegate>
@end

@implementation CameraManager (UsePhotoViewControllerDelegate)

- (void)usePhotoViewControllerDidCancel:(UsePhotoViewController *)controller
{
    [self backButtonClick:nil];
}

- (void)usePhotoViewControllerDidDismiss:(UsePhotoViewController *)controller
{
    [parentController dismissViewControllerAnimated:YES completion:nil];
}
- (void)usePhotoViewControllerDidAccept:(UsePhotoViewController *)controller
{
    [self usePhotoButtonClick:nil];
}

@end
