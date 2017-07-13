#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class CalloutMapAnnotationView;

@protocol CalloutMapAnnotationViewDelegate <NSObject>

- (void)actionButton:(CalloutMapAnnotationView *)controller;

@end

@interface CalloutMapAnnotationView : MKAnnotationView
{
	MKAnnotationView *_parentAnnotationView;
	MKMapView *_mapView;
	CGRect _endFrame;
	UIView *_contentView;
	CGFloat _yShadowOffset;
	CGPoint _offsetFromParent;
	CGFloat _contentHeight;
}

@property (nonatomic, strong) MKAnnotationView *parentAnnotationView;
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, readonly) UIView *contentView;
@property (nonatomic) CGPoint offsetFromParent;
@property (nonatomic) CGFloat contentHeight;
@property (nonatomic, strong) NSString * title4Show;
@property (nonatomic, strong) UIButton * actionButton;

- (void)animateIn;
- (void)animateInStepTwo;
- (void)animateInStepThree;

@property (nonatomic, assign)   id<CalloutMapAnnotationViewDelegate> delegate;

@end