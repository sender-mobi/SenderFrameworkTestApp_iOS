//
//  SpinnerAccountsView.h
//  Privat24
//
//  Created by Eugene Gilko on 27.07.14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const int kSpinnerAccountsViewTag;

@interface SpinnerAccountsView : UIView

@property (retain, nonatomic) UIImageView *imgViewSpinner;
@property (assign, nonatomic) NSInteger framesPerSecond;

- (void)startAnimation;
- (void)stopAnimation;

+ (SpinnerAccountsView *)spinnerView;
+ (SpinnerAccountsView *)spinerViewWithFrame:(CGRect)frame;

@end
