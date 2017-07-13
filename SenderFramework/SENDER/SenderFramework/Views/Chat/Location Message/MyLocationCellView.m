//
//  MyLocationCellView.m
//  SENDER
//
//  Created by Eugene on 1/11/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "MyLocationCellView.h"
#import "PBConsoleConstants.h"
#import "ParamsFacade.h"
#import "Contact.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "CoreDataFacade.h"
#import "SenderNotifications.h"
#import "ConsoleCaclulator.h"
#import <MapKit/MapKit.h>

NSString * const SendMyLocaton = @"SendMyLocaton";

@implementation MyLocationCellView
{
    int innerViewHeight;
    UITextView * headerText;
    MKMapView * mapView;
    UIView * labelBackground;
}

- (void)initWithModel:(Message *)submodel width:(CGFloat)maxWidth timeLabelSize:(CGSize)timeLabelSize
{
    self.viewModel = submodel;
    
    if (self) {
        
        self.frame = CGRectMake(0, 0, 208.0f, 208.0f);
        
        CGRect innerRect = CGRectMake(4.0f, 4.0f, 200.0, 200.0);
        mapView = [[MKMapView alloc]initWithFrame:innerRect];
        mapView.layer.cornerRadius = 14.0;
        mapView.clipsToBounds = YES;
        mapView.userInteractionEnabled = NO;
        
        [self addSubview:mapView];
        
        labelBackground = [[UIView alloc]init];

        labelBackground.backgroundColor = self.viewModel.owner ? [SenderCore sharedCore].stylePalette.myMessageBackgroundColor : [SenderCore sharedCore].stylePalette.foreignMessageBackgroundColor;
        labelBackground.clipsToBounds = YES;
        
        [self insertSubview:labelBackground aboveSubview:mapView];
        
        [self fixWidthForTimeLabelSize:timeLabelSize maxWidth:maxWidth];
        
        UIButton * actionButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
        [actionButton addTarget:self action:@selector(showLocationAction) forControlEvents:UIControlEventTouchUpInside];
        [self insertSubview:actionButton aboveSubview:labelBackground];
        
        NSDictionary * locData = [[ParamsFacade sharedInstance] dictionaryFromNSData:self.viewModel.modelData];
        CLLocationDegrees latitude = [locData[@"lat"]doubleValue];
        CLLocationDegrees longtitude = [locData[@"lon"]doubleValue];
        CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake(latitude, longtitude);
        
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinates, 600, 600);
        [mapView setRegion:[mapView regionThatFits:region] animated:YES];
        
        MKPointAnnotation * locationFromMessage = [[MKPointAnnotation alloc] init];
        locationFromMessage.coordinate = coordinates;
        [mapView addAnnotation:locationFromMessage];
    }
}


- (void)fixWidthForTimeLabelSize:(CGSize)timeSize maxWidth:(CGFloat)maxWidth
{
    CGFloat newWidth = timeSize.width + 5.0f;
    CGFloat newHeight = timeSize.height + 10.0f;
    
    labelBackground.frame = CGRectMake(self.frame.size.width - newWidth, self.frame.size.height - newHeight, newWidth, newHeight);
    labelBackground.layer.cornerRadius = labelBackground.frame.size.height / 2;
}

- (void)showLocationAction
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SendMyLocaton
                                                        object:self.viewModel];
}

@end
