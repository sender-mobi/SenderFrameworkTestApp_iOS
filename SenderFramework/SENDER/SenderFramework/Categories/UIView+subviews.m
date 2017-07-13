//
//  UIView+subviews.m
//  iPay
//
//  Created by Serg Cyclone on 12.09.12.
//  Copyright (c) 2012 Serg Cyclone. All rights reserved.
//

#import "UIView+subviews.h"

@implementation UIView (subviews)


-(void) iterateSubviewsWithBlock:(void(^)(UIView *subview))block
{
	for (UIView *vs in [self subviews])
    {
		[vs iterateSubviewsWithBlock:block];
		block(vs);
	}
}

-(void) removeAllSubviews
{
	for (UIView *v in [self subviews])
		[v removeFromSuperview];
}

-(void) removeAllGestureRecognizers
{
	for (id rec in [self gestureRecognizers])
		[self removeGestureRecognizer:rec];
}

- (UIView *)findFirstResponder
{
    if (self.isFirstResponder)
    {
        return self;
    }
	
    for (UIView* subView in self.subviews)
    {
        UIView* firstResponder = [subView findFirstResponder];
		
        if (firstResponder != nil)
        {
			return firstResponder;
        }
    }
	
    return nil;
}

+ (UIView*) findFirstResponder
{
	return [[[UIApplication sharedApplication] keyWindow] findFirstResponder];
}

void printSubviewsInternal(UIView *view, int placeholders, BOOL noSubitems)
{
	NSString* tmp = @"";
	for (int i = 0; i < placeholders; i++)
		tmp = [tmp stringByAppendingString:@" "];
	
	if (!noSubitems)
		for (UIView *v in [view subviews])
        {
			if ([v isKindOfClass:[UIControl class]])
				printSubviewsInternal(v, placeholders + 1, YES);
			else
				printSubviewsInternal(v, placeholders + 1, NO);
		}
}

-(void) replaceWith:(UIView*)anotherView
{
	anotherView.frame = self.frame;
	[self.superview insertSubview:anotherView aboveSubview:self];
	[self removeFromSuperview];
}

void printSubviews(UIView *view)
{
	printSubviewsInternal(view, 0, NO);
}

-(void) printSubviews
{
	printSubviewsInternal(self, 0, NO);
}

- (void)pinSubview:(UIView *)subview
{
	if (subview.superview != self)
		return;

	NSLayoutAttribute attributes[] = {NSLayoutAttributeTop, NSLayoutAttributeLeft, NSLayoutAttributeRight, NSLayoutAttributeBottom};
	for (int i = 0; i < 4; i++)
	{
		NSLayoutAttribute attribute = attributes[i];
		NSLayoutConstraint  * constraint = [NSLayoutConstraint constraintWithItem:self
																		attribute:attribute
																		relatedBy:NSLayoutRelationEqual
																		   toItem:subview
																		attribute:attribute
																	   multiplier:1.0f
																		 constant:0.0f];
		[self addConstraint:constraint];
	}
}


@end
