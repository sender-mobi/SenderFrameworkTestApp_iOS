//
//  PBConsoleView.m
//  ZiZZ
//
//  Created by Eugene Gilko on 7/18/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBConsoleView.h"
#import "PBConsoleConstants.h"
#import "Contact.h"
#import "ParamsFacade.h"
#import "UIImage+Resize.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "CoreDataFacade.h"
#import "CellWithWebView.h"
#import "SenderNotifications.h"
#import "ServerFacade.h"
#import "ConsoleCaclulator.h"
#import "ColVewContainer.h"
#import "Owner.h"
#import "PBSelectedView.h"
#import "ImagesManipulator.h"
#import "Dialog.h"

@implementation PBConsoleView
{
    CGRect mainRect;
    UIImage * viewBg;
}

- (Class)viewControllerClass:(NSString *)className
{
    return NSClassFromString(className);
}

- (PBConsoleView *)initWithCellModel:(MainConteinerModel *)cellModel
                             message:(Message *)message
                             forRect:(CGRect)rect
                  rootViewController:(UIViewController *)rootViewController
{
    if ((self = [super initWithFrame:CGRectMake(0, 0, rect.size.width, 0)]))
    {

        _cellModel = cellModel;
        _message = message;

        if ([self.cellModel.state isEqualToString:@"disable"])
        {

            self.alpha = 0.3;

            self.userInteractionEnabled = NO;
        }

        mainRect = self.frame;

        if (IS_IPAD)
        {
            CGFloat oldWidth = mainRect.size.width;
            mainRect.size.width = oldWidth > 400.0f ? 400.0f : oldWidth;
            mainRect.origin.x = (oldWidth - mainRect.size.width) / 2;
        }

        if ([_cellModel viewHavePadding])
        {

            mainRect = CorrectRectWithPaddingList(mainRect, _cellModel.pd);
        }

        ColVewContainer *formSubView = [self colView:mainRect andModel:_cellModel];

        [self addSubview:formSubView];

        mainRect = self.frame;

        mainRect.size.height = formSubView.frame.size.height;
        if ([_cellModel viewHavePadding])
        {
            mainRect.size.height += (int) [_cellModel.pd[2] integerValue] + 16;
        }

        self.frame = mainRect;

        self.rootViewController = rootViewController;

        if ([message.robotId isEqualToString:@"alert"])
            [self addAuthor];

        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (ColVewContainer *)containerWithRect:(CGRect)contRect andModel:(MainConteinerModel *)contModel
{
    ColVewContainer * contView = [[[self viewControllerClass:contModel.className] alloc] init];
    
    if (contModel.w) {
        contRect.size.width = [contModel.w floatValue];
    }
    if (contModel.h) {
        contRect.size.height = [contModel.h floatValue];
    }
    
    contView.frame = contRect;
    
    contRect.origin.x = 0;
    contRect.origin.y = 0;
    
    if ([_cellModel viewHaveMargins]) {
        contRect = CorrectRectWithMargingList(contRect, contModel.mg);
    }
    
    if ([_cellModel viewHavePadding]) {
        contRect = CorrectRectWithPaddingList(contRect, contModel.pd);
    }
    
    __strong PBSubviewFacade * innerView;
    if ([contModel.type isEqualToString:@"col"]) {
   
        innerView = [self colView:contRect andModel:contModel];
        innerView.viewModel = contModel;
    }
    else if ([contModel.type isEqualToString:@"row"]) {
        
        innerView = [self rowView:contRect andModel:contModel];
        innerView.viewModel = contModel;
    }

    innerView.delegate = self;
    contRect = contView.frame;
    contRect.size.height = innerView.frame.size.height;
    contRect.size.width = innerView.frame.size.width;
    contView.frame = contRect;
    [contView addSubview:innerView];

    return contView;
}

- (ColVewContainer *)colView:(CGRect)locRect andModel:(MainConteinerModel *)cellModel
{
    __strong ColVewContainer * colView = [[ColVewContainer alloc] init];
    
    colView.viewModel = cellModel;

        if (cellModel.submodels && ![cellModel.state isEqualToString:@"gone"]) {
            
            CGRect tmpRect = locRect;
            tmpRect.origin.x = 0;
            tmpRect.origin.y = 0;
            tmpRect.size.height = 0;
            int totalHeight = 0;
            
            if (cellModel.pd.count) {
                tmpRect = CorrectRectWithPaddingList(tmpRect, cellModel.pd);
            }
            
            if (cellModel.mg.count) {
                tmpRect = CorrectRectWithMargingList(tmpRect, cellModel.mg);
            }
            
            int mainBottomSpace = 0;

            for (MainConteinerModel * viewModel in cellModel.submodels) {

                if ([viewModel.state isEqualToString:@"gone"]) { // NOTHING TO DO HERE
                
                }
                else {
                    
                    __strong PBSubviewFacade * innerView;
                    
                    tmpRect.origin.y += (int)[viewModel.mg[0] integerValue] + (int)[viewModel.pd[0] integerValue];
                    
                    totalHeight += (int)[viewModel.mg[0] integerValue] + (int)[viewModel.pd[0] integerValue];

                    if ([viewModel.type isEqualToString:@"col"]) {
                        innerView = [self containerWithRect:tmpRect andModel:viewModel];
                        innerView.viewModel = viewModel;
                    }
                    else if ([viewModel.type isEqualToString:@"row"]) {
                        innerView = [self containerWithRect:tmpRect andModel:viewModel];
                        innerView.viewModel = viewModel;
                    }
                    else {
                        innerView = [self configureViewForModel:viewModel topFrame:tmpRect];
                        innerView.viewModel = viewModel;
                        tmpRect.origin.y += (int)[viewModel.pd[2] integerValue] + (int)[viewModel.pd[0] integerValue];
                    }
                    
                    int tempBottomSpace = (int)[viewModel.pd[2] integerValue] + (int)[viewModel.pd[0] integerValue];
                    mainBottomSpace = (mainBottomSpace < tempBottomSpace) ? tempBottomSpace:mainBottomSpace;
                    int tempYVar = innerView.frame.size.height + (int)[viewModel.mg[0] integerValue] + (int)[viewModel.mg[2] integerValue] + (int)[viewModel.pd[2] integerValue] + (int)[viewModel.pd[0] integerValue];
                    totalHeight += tempYVar;
                    tmpRect.origin.y += tempYVar;

                    [colView addSubview:innerView];

                    tmpRect.size.height = 0;
                }
            }
            
            locRect.size.height = totalHeight;
            locRect.size.height += (int)[cellModel.pd[0] integerValue] + (int)[cellModel.pd[2] integerValue];
            locRect.size.height += (int)[cellModel.mg[0] integerValue] + (int)[cellModel.mg[2] integerValue];

        }
    
    if (cellModel.w) {
        locRect.size.width = [cellModel.w floatValue];
    }
    if (cellModel.h) {
        locRect.size.height = [cellModel.h floatValue];
    }
    
    colView.frame = locRect;
    
    if (colView.subviews.count > 0) {
        VerticalAlignSubviewInview(colView);
    }

    HorisontalAlignSubviewInview(colView);
    
    if (cellModel.bg && cellModel.bg.length) {
        
        NSString * firstBg = [cellModel.bg substringToIndex:1];
        
        if ([firstBg isEqualToString:@"#"]) {
            
            colView.backgroundColor = [PBConsoleConstants colorWithHexString:cellModel.bg];
        }
        else {
            CGRect rect = colView.frame;
            rect.origin.x = 0;
            rect.origin.y = 0;
            UIImageView * imgView = [[UIImageView alloc] initWithFrame:rect];
            
            [imgView sd_setImageWithURL:[NSURL URLWithString:cellModel.bg]
                       placeholderImage:[UIImage imageFromSenderFrameworkNamed:@""]];
            [colView insertSubview:imgView atIndex:0];
        }
    }
    else {
        colView.backgroundColor = [UIColor clearColor];
    }
    
    SettingBorderForView (colView,cellModel);

    if (cellModel.action || cellModel.actions) {
        [self addActionButtonToObject:colView];
    }

    return colView;
}

- (ColVewContainer *)rowView:(CGRect)locRect andModel:(MainConteinerModel *)rowModel
{
    ColVewContainer * colView = [[ColVewContainer alloc] init];
    
    colView.viewModel = rowModel;
    if (rowModel.submodels && ![rowModel.state isEqualToString:@"gone"]) {
        
        CGRect tmpRect = locRect;
        
        if ([rowModel viewHavePadding]) {
            tmpRect = CorrectRectWithPaddingList(tmpRect, rowModel.pd);
        }
        
        tmpRect.origin.x = 0;
        
        if (RebuildWidthForRowInModel(rowModel,tmpRect.size.width)){
        
            int mainBottomSpace = 0;
            
            for (MainConteinerModel * viewModel in rowModel.submodels) {
            
                if ([viewModel.state isEqualToString:@"gone"]) { // NOTHING TO DO HERE
//                    // NSLog(@"ROW GONE");
                }
                else {
                    tmpRect.origin.y = 0;
                    __strong PBSubviewFacade * innerView;
                    tmpRect.size.width = [viewModel.w floatValue];

                    if ([viewModel.type isEqualToString:@"col"]) {
                        innerView = [self containerWithRect:tmpRect andModel:viewModel];
                        innerView.viewModel = viewModel;
                    }
                    else if ([viewModel.type isEqualToString:@"row"]) {
                        innerView = [self containerWithRect:tmpRect andModel:viewModel];
                        innerView.viewModel = viewModel;
                    }
                    else {
                        
                        if (viewModel.pd.count) {
                            tmpRect = CorrectRectWithPaddingList(tmpRect, viewModel.pd);
                            mainBottomSpace += (int)[rowModel.pd[2] integerValue];
                        }
                        
                        if (viewModel.mg.count) {
                            tmpRect = CorrectRectWithMargingList(tmpRect, viewModel.mg);
                        }
                        innerView = [self configureViewForModel:viewModel topFrame:tmpRect];
                        innerView.viewModel = viewModel;
                    }
                    
                    [colView addSubview:innerView];
                    tmpRect.origin.x += tmpRect.size.width;
                    
                    int tempBottomSpace = (int)[viewModel.pd[2] integerValue];
                    
                    mainBottomSpace = (mainBottomSpace < tempBottomSpace) ? tempBottomSpace:mainBottomSpace;
                    tmpRect = [self calculateNewHeightForFrame:tmpRect fromRect:innerView.frame];
                }
            }
            
            LLog(@"=====================\n========================\n  BUILD MODEL H = %i  ADD BOTTOM SPACE  = %i",(int)tmpRect.size.height,mainBottomSpace);

            locRect.size.height = tmpRect.size.height + mainBottomSpace;
            locRect.size.height += (int)[rowModel.pd[2] integerValue];
        }
    }
   
    if (rowModel.w) {
        locRect.size.width = [rowModel.w floatValue];
    }
    
    if (rowModel.h) {
        locRect.size.height = [rowModel.h floatValue];
    }

    colView.frame = locRect;
    
    if (colView.subviews.count > 1) {
        VerticalAlignSubviewInview(colView);
    }
    
    HorisontalAlignSubviewInview(colView);
    
    if (rowModel.bg) {
        
        NSString * firstBg = [rowModel.bg substringToIndex:1];
        
        if ([firstBg isEqualToString:@"#"]) {
            
            colView.backgroundColor = [PBConsoleConstants colorWithHexString:rowModel.bg];
        }
        else if ([firstBg isEqualToString:@"h"]) {
            viewBg = [[UIImage alloc] init];
            [[ServerFacade sharedInstance] downloadImageWithBlock:[^(UIImage * image) {
                viewBg = image;
                colView.backgroundColor = [UIColor colorWithPatternImage:viewBg];
            } copy] forUrl:rowModel.bg];
        }
    }
    else {
        colView.backgroundColor = [UIColor clearColor];
    }

    SettingBorderForView (colView,rowModel);
    
    if (rowModel.action || rowModel.actions) {
        [self addActionButtonToObject:colView];
        colView.viewModel = rowModel;
    }
    
    return colView;
}

- (PBSubviewFacade *)configureViewForModel:(MainConteinerModel *)modelForBuild topFrame:(CGRect)topFrame
{
    if ([modelForBuild.type isEqualToString:@"text"] && [modelForBuild viewHavePadding]) {
        
        topFrame.origin.y -= [modelForBuild.pd[0] integerValue];
    }
    
    PBSubviewFacade * viewFormClass = [[[self viewControllerClass:modelForBuild.className] alloc] init];
    viewFormClass.delegate = self;
    
    CGRect localRect = CGRectMake(topFrame.origin.x, topFrame.origin.y, topFrame.size.width, topFrame.size.height);
    [viewFormClass settingViewWithRect:localRect andModel:modelForBuild];
    viewFormClass.backgroundColor = [UIColor clearColor];
    localRect.size.height = viewFormClass.frame.size.height;
    
    if (modelForBuild.w) {
        localRect.size.width = [modelForBuild.w floatValue];
    }
    if (modelForBuild.h) {
        localRect.size.height = [modelForBuild.h floatValue];
    }
    
    viewFormClass.frame = localRect;

    return viewFormClass;
}

- (CGRect)calculateNewHeightForFrame:(CGRect)sourceRect fromRect:(CGRect)newRect
{
    if (newRect.size.height > sourceRect.size.height) {
        sourceRect.size.height = newRect.size.height;
    }
    return sourceRect;
}

#pragma mark PBSubViewFacadeDelegate

- (void)submitOnChange:(NSDictionary *)action
{
    [self submitDataWithInfo:action];
}

- (UIViewController *)presentingViewController
{
    return self.rootViewController;
}

#pragma mark ButtonDeleagate

- (void)pushOnButton:(PBButtonInFormView *)controller didFinishEnteringItem:(NSDictionary *)buttonInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:HideKeyboard object:nil];
    self.userInteractionEnabled = NO;
    [self endEditing:YES];
   
    NSMutableDictionary * outData = [[NSMutableDictionary alloc] init];
    outData[buttonInfo[@"name"]] = buttonInfo[@"val"];
    
    if (buttonInfo[@"result"])
        outData[@"result"] = buttonInfo[@"result"];
    
    [self submitDataWithInfo:outData];
}

- (void)submitDataWithInfo:(NSDictionary *)info
{
    NSMutableDictionary * outData = [[NSMutableDictionary alloc] initWithDictionary:[self.cellModel getDataFromModel]];
   
    if (!outData) {
        // ERROR STATE!!!!
        return;
    }
    
    if (info) {
        for (id key in info) {
            outData[key] = info[key];
        }
    }
    
    NSMutableDictionary * result = [[NSMutableDictionary alloc] init];
    
    if (self.cellModel.procId && ![self.cellModel.procId isEqualToString:@"(null)"]) {
        result[@"procId"] = self.cellModel.procId;
    }
    else {
        result[@"procId"] = @"";
    }
    
    result[@"model"] = outData;
    
    if (_message.classRef) {
        result[@"class"] = _message.classRef;
    }
    
    result[@"chatId"] = _message.chat;
    
    [[ServerFacade sharedInstance] sendForm:result];
}

- (void)addActionButtonToObject:(ColVewContainer *)colView
{
    CGRect rect = CGRectMake(0, 0, colView.frame.size.width, colView.frame.size.height);
    UIButton * actionButton = [[UIButton alloc] initWithFrame:rect];
    [actionButton addTarget:colView action:@selector(doAction) forControlEvents:UIControlEventTouchUpInside];
    [colView addSubview:actionButton];
}

- (void)downloadImageWithBlock:(void(^)(UIImage * image))block forUrl:(NSString *)urlString
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSError * error;
            NSData * imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]
                                                       options:NSDataReadingUncached error:&error];
            
            if (!imageData) {
                return ;
            }
            
            UIImage * newImage = [UIImage imageWithData:imageData];
            block(newImage);
        }
    });
}

- (void)addAuthor
{
    CGFloat labelX = 65.0f;
    CGFloat labelWidth = SCREEN_WIDTH - 85.0f;
    CGFloat labelHeight = 18.0f;
    CGFloat y = 0.0f;
    CGFloat imageX = [self.message.fromId isEqualToString:[CoreDataFacade sharedInstance].ownerUDID] ? SCREEN_WIDTH - 57.0f : 20.0f;
    CGFloat imageSide = 37.0f;
    
    UIImageView * fromPhoto = [[UIImageView alloc]initWithFrame:CGRectMake(imageX, y, imageSide, imageSide)];
    fromPhoto.backgroundColor = [UIColor whiteColor];
    NSString * fromNameText;
    
    if ([self.message.fromId isEqualToString:[CoreDataFacade sharedInstance].ownerUDID])
    {
        Owner * owner = [[CoreDataFacade sharedInstance]getOwner];
        [ImagesManipulator setImageForImageView:fromPhoto withOwner:owner imageChangeHandler:nil];
    }
    else
    {
        Contact * contactModel = [[CoreDataFacade sharedInstance] selectContactById:self.message.fromId];
        [ImagesManipulator setImageForImageView:fromPhoto withContact:contactModel imageChangeHandler:nil];
        if (!self.message.owner && ![self.message.dialog.p2p boolValue])
            fromNameText = contactModel.name;
    }
    
    if (![self.message.fromId isEqualToString:[CoreDataFacade sharedInstance].ownerUDID] && ![self.message.dialog.p2p boolValue])
    {
        UILabel * fromName = [[UILabel alloc]init];
        fromName.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f];
        fromName.textAlignment = NSTextAlignmentCenter;
        fromName.textColor = [PBConsoleConstants mainBlueColor];
        fromName.text = fromNameText;
        CGSize textSize = [fromName sizeThatFits:CGSizeMake(labelWidth, FLT_MAX)];
        fromName.frame = CGRectMake(labelX, y, textSize.width + 18.0f, labelHeight);
        fromName.backgroundColor = [UIColor whiteColor];
        fromName.layer.cornerRadius = fromName.frame.size.height/2;
        fromName.clipsToBounds = YES;
        [self addSubview:fromName];
    }

    [PBConsoleConstants imageSetRounds:fromPhoto];
    
    [self addSubview:fromPhoto];
}

@end

#pragma mark BoxContainer implementation

@implementation BoxContainer
{
    UIView * paddingBox;
    NSArray * paddingArray;
    NSArray * marginsArray;
    MainConteinerModel * boxModel;
}

- (instancetype)initWith:(MainConteinerModel *)boxModel andFrame:(CGRect)extRect
{
    CGRect tempRect = CGRectMake(extRect.origin.x, extRect.origin.y, extRect.size.width, 0);
    
    if (self = [super initWithFrame:tempRect]) {
    
        if ([boxModel viewHaveMargins]) {
            
            marginsArray = boxModel.mg;
            tempRect = CorrectRectWithMargingList(tempRect, marginsArray);
        }
        
        if ([boxModel viewHavePadding]) {
            
            paddingBox = [[UIView alloc] initWithFrame:tempRect];
            
            [self addSubview:paddingBox];
            tempRect.origin.x = 0;
            tempRect.origin.y = 0;
            paddingArray = boxModel.pd;
            tempRect = CorrectRectWithPaddingList(tempRect, paddingArray);
        }
        
        if (boxModel.bg) {
            NSString * firstBg = [boxModel.bg substringToIndex:1];
            
            if ([firstBg isEqualToString:@"#"]) {
                if (paddingBox)
                    paddingBox.backgroundColor = [PBConsoleConstants colorWithHexString:boxModel.bg];
                else
                    self.backgroundColor = [PBConsoleConstants colorWithHexString:boxModel.bg];
            }
            else if ([firstBg isEqualToString:@"h"]) {
                __block UIImage * paddBg = [[UIImage alloc] init];
                
                [[ServerFacade sharedInstance] downloadImageWithBlock:[^(UIImage * image) {
                    paddBg = image;
                    if (paddingBox)
                        paddingBox.backgroundColor = [UIColor colorWithPatternImage:paddBg];
                    else
                        self.backgroundColor = [UIColor colorWithPatternImage:paddBg];
                    
                } copy] forUrl:boxModel.bg];
            }
        }
        
        SettingBorderForView (paddingBox ? paddingBox:self,boxModel);
        _contentHolder = [[UIView alloc] initWithFrame:tempRect];
        
        if (paddingBox) {
            [paddingBox addSubview:_contentHolder];
        }
        else {
            [self addSubview:_contentHolder];
        }
    }
    return self;
}

- (void)updateFrame
{
    CGRect tempRect;
    
    float contentHeight = _contentHolder.frame.size.height;
    
    if (paddingBox) {
        
        tempRect = paddingBox.frame;
        tempRect.size.height += contentHeight;
        if (paddingArray) {
            tempRect.size.height += (int)[paddingArray[0] integerValue] + (int)[paddingArray[2] integerValue];
        }
        paddingBox.frame = tempRect;
        
        tempRect = self.frame;
        tempRect.size.height = paddingBox.frame.size.height;
    }
    else {
        tempRect = self.frame;
        tempRect.size.height += contentHeight;
    }
    
    if (marginsArray) {
        tempRect.size.height += (int)[marginsArray[0] integerValue] + (int)[marginsArray[2] integerValue];
    }
    
    self.frame = tempRect;
}

- (void)doAction
{
    if (boxModel.action) {
        
        [super doAction:boxModel.action];
    }
    else if (boxModel.actions) {
        for (NSDictionary * action_ in boxModel.actions) {
            [super doAction:action_];
        }
    }
}

@end
