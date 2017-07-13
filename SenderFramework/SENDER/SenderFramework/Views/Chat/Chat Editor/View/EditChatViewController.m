//
//  EditChatViewController.m
//  SENDER
//
//  Created by Roman Serga on 29/7/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "EditChatViewController.h"
#import "PBConsoleConstants.h"
#import "ImagesManipulator.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface UITextField (CursorPosition)

- (void)selectTextInRange:(NSRange)range;

@end

@implementation UITextField (CursorPosition)

- (void)selectTextInRange:(NSRange)range
{
    UITextPosition *from = [self positionFromPosition:[self beginningOfDocument] offset:range.location];
    UITextPosition *to = [self positionFromPosition:from offset:range.length];
    [self setSelectedTextRange:[self textRangeFromPosition:from toPosition:to]];
}

@end

@interface EditChatViewController ()

@property (nonatomic, weak) IBOutlet UIImageView * chatPhotoImageView;
@property (nonatomic, weak) IBOutlet UITextField * chatNameTextField;
@property (nonatomic, weak) IBOutlet UITextField * chatDescriptionTextField;
@property (nonatomic, weak) IBOutlet UIButton * addPhotoButton;

@end

@implementation EditChatViewController

@synthesize presenter = _presenter;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.chatNameTextField becomeFirstResponder];

    self.chatNameTextField.attributedPlaceholder = [[SenderCore sharedCore].stylePalette placeholderWithString:SenderFrameworkLocalizedString(@"chat_name_ios", nil)];
    self.chatNameTextField.textColor = [SenderCore sharedCore].stylePalette.mainTextColor;

    self.view.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;
    self.tableView.backgroundColor = self.view.backgroundColor;

    [self.presenter viewWasLoaded];
}

- (void)setDialog:(Dialog *)dialog
{
    _dialog = dialog;
    if ([self isViewLoaded])
        [self updateViewForDialog];
}

- (void)updateViewForDialog
{
    [ImagesManipulator setImageForImageView:self.chatPhotoImageView withChat:self.dialog imageChangeHandler:nil];
    self.chatPhotoImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.chatPhotoImageView.layer.cornerRadius = 0.0f;
    self.chatNameTextField.text = self.dialog.name;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}


-(NSString *)title
{
    return SenderFrameworkLocalizedString(@"edit_chat_ios", nil);
}

- (void)customizeNavigationBar
{
    [self.navigationController.navigationBar setTintColor:[[SenderCore sharedCore].stylePalette mainAccentColor]];
    [[self navigationController]setNavigationBarHidden:NO];

    UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonPressed)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem * doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(doneButtonPressed)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
    [self.navigationItem setBackBarButtonItem:backItem];

    [[SenderCore sharedCore].stylePalette customizeNavigationBar:self.navigationController.navigationBar];
}

-(void)cancelButtonPressed
{
    [self.presenter cancelEditingChat];
}

- (void)doneButtonPressed
{
    [self.chatNameTextField resignFirstResponder];
    self.presenter.newName = self.chatNameTextField.text;
    [self.presenter editChat];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)changeChatImage:(id)sender
{
    [self.view endEditing:YES];

    NSString * alertTitle = SenderFrameworkLocalizedString(@"change_photo",nil);

    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                              message:nil
                                                                       preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction * libraryAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"select_from_gallery", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                               [self selectPhotos];
                                                           }];


    UIAlertAction * removeAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"remove_photo", nil)
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction *action) {
                                                              [self removePhoto];
                                                          }];

    UIAlertAction * cameraAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"take_photo", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [self takePhoto];
                                                          }];

    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];



    [alertController addAction:libraryAction];
    [alertController addAction:cameraAction];
    [alertController addAction:removeAction];
    [alertController addAction:cancelAction];
    [alertController mw_safePresentInViewController:self animated:YES completion:nil];
}

#pragma mark - Photo Changing

- (void)removePhoto
{
    self.presenter.newImageData = [NSData data];
    self.chatPhotoImageView.image = [UIImage imageFromSenderFrameworkNamed:@"def_group"];
}

- (void)takePhoto
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {

        UIAlertController * alert = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"error_ios", nil)
                                                                        message:SenderFrameworkLocalizedString(@"device_without_camera_ios", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * okAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"ok_ios", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];
        [alert addAction:okAction];
        [alert mw_safePresentInViewController:self animated:YES completion:nil];
        return;
    }

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self.navigationController presentViewController:picker animated:YES completion:NULL];
}

- (void)selectPhotos
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.allowsEditing = YES;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerController Delegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo
{
    UIImage * newImage = [self squareImageWithImage:image scaledToSize:CGSizeMake(200, 200)];
    self.chatPhotoImageView.image = newImage;
    self.presenter.newImageData = UIImageJPEGRepresentation(newImage, 0.6);
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Utilities

- (UIImage *)squareImageWithImage:(UIImage *)curImage scaledToSize:(CGSize)newSize
{
    double ratio = 1;
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.height);
    CGSize imgSize = curImage.size;
    
    if (imgSize.width > imgSize.height) {
        ratio = newSize.width / imgSize.width;
        
    } else {
        ratio = newSize.height / imgSize.height;
    }
    
    CGRect clipRect = CGRectMake(0, 0,
                                 (ratio * imgSize.width),
                                 (ratio * imgSize.height));
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [curImage drawInRect:clipRect];
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    newImage = [UIImage imageWithCGImage:[newImage CGImage]
                                   scale:(newImage.scale / 2)
                             orientation:(newImage.imageOrientation)];
    
    return newImage;
}

#pragma mark - Text Field delegate

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == self.chatNameTextField)
        [self.chatNameTextField selectTextInRange:NSMakeRange([self.chatNameTextField.text length], 0)];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 1.0f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.contentView.backgroundColor = self.view.backgroundColor;
}

- (void)showInvalidDataError
{

}

- (void)updateWithViewModel:(Dialog *)viewModel
{
    self.dialog = viewModel;
}

- (void)prepareForPresentationWithModalInNavigationWireframe:(ModalInNavigationWireframe *)modalInNavigationWireframe
{
    [self customizeNavigationBar];
}

- (void)prepareForDismissalWithModalInNavigationWireframe:(ModalInNavigationWireframe *)modalInNavigationWireframe {}

@end
