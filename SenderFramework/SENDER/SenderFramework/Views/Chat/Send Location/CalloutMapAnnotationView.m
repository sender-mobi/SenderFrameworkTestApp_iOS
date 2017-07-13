#import "CalloutMapAnnotationView.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

#define CalloutMapAnnotationViewBottomShadowBufferSize 6.0f
#define CalloutMapAnnotationViewContentHeightBuffer 8.0f
#define CalloutMapAnnotationViewHeightAboveParent 2.0f

@interface CalloutMapAnnotationView()

@property (nonatomic, readonly) CGFloat yShadowOffset;
@property (nonatomic) BOOL animateOnNextDrawRect;
@property (nonatomic) CGRect endFrame;

- (void)prepareContentFrame;
- (void)prepareFrameSize;
- (void)prepareOffset;

@end


@implementation CalloutMapAnnotationView

@synthesize parentAnnotationView = _parentAnnotationView;
@synthesize mapView = _mapView;
@synthesize contentView = _contentView;
@synthesize animateOnNextDrawRect = _animateOnNextDrawRect;
@synthesize endFrame = _endFrame;
@synthesize yShadowOffset = _yShadowOffset;
@synthesize offsetFromParent = _offsetFromParent;
@synthesize contentHeight = _contentHeight;

- (id) initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
		self.offsetFromParent = CGPointMake(8, -14); //this works for MKPinAnnotationView
		self.enabled = YES;
		self.backgroundColor = [UIColor clearColor];
        UIImageView * uimgPin = [[UIImageView alloc] initWithImage:[UIImage imageFromSenderFrameworkNamed:@"pin_icon"]];
        CGRect rect = uimgPin.frame;
        rect.origin.x = self.contentView.frame.size.width/2 - rect.size.width/2;
        rect.origin.y = self.contentView.frame.size.height;
        uimgPin.frame = rect;
        [self addSubview:uimgPin];
	}
	return self;
}

- (void)setAnnotation:(id <MKAnnotation>)annotation {
	[super setAnnotation:annotation];
    [self prepareFrameSize];
//	[self prepareOffset];
    [self prepareContentFrame];
//	[self setNeedsDisplay];
}

- (void)prepareFrameSize {
	CGRect frame = self.frame;
	CGFloat height = self.contentHeight +
	CalloutMapAnnotationViewContentHeightBuffer +
	CalloutMapAnnotationViewBottomShadowBufferSize -
	self.offsetFromParent.y;
	
	frame.size = CGSizeMake(self.mapView.frame.size.width, height);
    frame.origin.x +=20;
    self.frame = CGRectMake(self.bounds.origin.x + 10,
                            self.bounds.origin.y -10,
                            268,
                            52);
    
    UIImageView * uimgV = [[UIImageView alloc] initWithImage:[UIImage imageFromSenderFrameworkNamed:@"label_address"]];
    
    [self.contentView addSubview:uimgV];
    
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(55,
                                                                -5,
                                                                210,
                                                                50)];
    
    NSArray * textArr = [_title4Show componentsSeparatedByString:@"\n"];
    title.text = textArr[0];
    title.numberOfLines = 2;
    
    [self.contentView addSubview:title];
    
    
    _actionButton = [[UIButton alloc] initWithFrame:CGRectMake( 0,
                                                                0,
                                                                44,
                                                                44)];
    
    [_actionButton setImage:[UIImage imageFromSenderFrameworkNamed:@"send_location"] forState:UIControlStateNormal];
    
    [self.contentView addSubview:_actionButton];
    
     [_actionButton addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)buttonAction
{
    [self.delegate actionButton:self];
}

- (void)prepareContentFrame {
	CGRect contentFrame = CGRectMake(0,
									 0,
									 268,
									 52);

	self.contentView.frame = contentFrame;
}

- (void)actionButton:(CalloutMapAnnotationView *)controller
{
    
}

- (CGFloat)xTransformForScale:(CGFloat)scale {
	CGFloat xDistanceFromCenterToParent = self.endFrame.size.width / 2;
	return (xDistanceFromCenterToParent * scale) - xDistanceFromCenterToParent;
}

- (CGFloat)yTransformForScale:(CGFloat)scale {
	CGFloat yDistanceFromCenterToParent = (((self.endFrame.size.height) / 2) + self.offsetFromParent.y + CalloutMapAnnotationViewBottomShadowBufferSize + CalloutMapAnnotationViewHeightAboveParent);
	return yDistanceFromCenterToParent - yDistanceFromCenterToParent * scale;
}

- (void)animateIn {
	self.endFrame = self.frame;
	CGFloat scale = 0.001f;
	self.transform = CGAffineTransformMake(scale, 0.0f, 0.0f, scale, [self xTransformForScale:scale], [self yTransformForScale:scale]);
	[UIView beginAnimations:@"animateIn" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:0.075];
	[UIView setAnimationDidStopSelector:@selector(animateInStepTwo)];
	[UIView setAnimationDelegate:self];
	scale = 1.1;
	self.transform = CGAffineTransformMake(scale, 0.0f, 0.0f, scale, [self xTransformForScale:scale], [self yTransformForScale:scale]);
	[UIView commitAnimations];
}

- (void)animateInStepTwo {
	[UIView beginAnimations:@"animateInStepTwo" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.1];
	[UIView setAnimationDidStopSelector:@selector(animateInStepThree)];
	[UIView setAnimationDelegate:self];
	
	CGFloat scale = 0.95;
	self.transform = CGAffineTransformMake(scale, 0.0f, 0.0f, scale, [self xTransformForScale:scale], [self yTransformForScale:scale]);
	
	[UIView commitAnimations];
}

- (void)animateInStepThree {
	[UIView beginAnimations:@"animateInStepThree" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.075];
	
	CGFloat scale = 1.0;
	self.transform = CGAffineTransformMake(scale, 0.0f, 0.0f, scale, [self xTransformForScale:scale], [self yTransformForScale:scale]);
	
	[UIView commitAnimations];
}

- (UIView *)contentView {
	if (!_contentView)
    {
		_contentView = [[UIView alloc] init];
		self.contentView.backgroundColor = [UIColor clearColor];
		self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.contentView];
	}
	return _contentView;
}

- (void)dealloc {
	self.parentAnnotationView = nil;
	self.mapView = nil;

}

- (void)didMoveToSuperview {
    
    //    [self animateIn];
}

- (void)prepareOffset {
    
    //	CGPoint parentOrigin = [self.mapView convertPoint:self.parentAnnotationView.frame.origin
    //											 fromView:self.parentAnnotationView.superview];
    //
    //	CGFloat xOffset =	(self.mapView.frame.size.width / 2) -
    //						(parentOrigin.x + self.offsetFromParent.x);
    //
    //	//Add half our height plus half of the height of the annotation we are tied to so that our bottom lines up to its top
    //	//Then take into account its offset and the extra space needed for our drop shadow
    //	CGFloat yOffset = -(self.frame.size.height / 2 +
    //						self.parentAnnotationView.frame.size.height / 2) +
    //						self.offsetFromParent.y +
    //						CalloutMapAnnotationViewBottomShadowBufferSize;
    //
    //	self.centerOffset = CGPointMake(xOffset, yOffset);
    //
}

@end
