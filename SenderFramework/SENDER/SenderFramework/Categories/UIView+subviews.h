//
//  UIView+subviews.h
//  iPay
//
//  Created by Serg Cyclone on 12.09.12.
//  Copyright (c) 2012 Serg Cyclone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (subviews)

-(void) iterateSubviewsWithBlock:(void(^)(UIView *subview))block;
-(void) removeAllSubviews;
-(void) removeAllGestureRecognizers;
+(UIView *) findFirstResponder;
-(void) printSubviews;
-(UIView *) findFirstResponder;
-(void) replaceWith:(UIView*)anotherView;

/*
 * Pins subview with constraints to top, bottom, left and right of superview
 */
- (void)pinSubview:(UIView *)subview;

@end
