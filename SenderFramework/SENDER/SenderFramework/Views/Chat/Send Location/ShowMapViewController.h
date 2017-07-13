//
//  ShowMapViewController.h
//  SENDER
//
//  Created by Eugene on 11/21/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "CalloutMapAnnotationView.h"

@class ShowMapViewController;

@protocol ShowMapViewControllerDelegate <NSObject>

- (void)pushOnLocation:(ShowMapViewController *)controller
                            didFinishEnteringLocation:(CLLocation *)location
                            andImge:(UIImage *)image
                            withDesc:(NSString *)description;

- (void)locationSelect:(ShowMapViewController *)controller
            didFinishEnteringLocation:(CLLocation *)location
              withDesc:(NSString *)description;

@end

@interface ShowMapViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, CalloutMapAnnotationViewDelegate>

@property (nonatomic, assign)   id<ShowMapViewControllerDelegate> delegate;
@property (nonatomic, strong) NSDictionary * incommingLocale;
@property (nonatomic) BOOL secondDelegateRun;
@property (nonatomic, strong) NSArray * poiArray;

@end