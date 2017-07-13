//
//  ShowMapViewController.m
//  SENDER
//
//  Created by Eugene on 11/21/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "ShowMapViewController.h"
#import <AddressBookUI/AddressBookUI.h>
#import "PBConsoleConstants.h"
#import "UIImage+Resize.h"
#import "UIAlertView+CompletionHandler.h"
#import "ServerFacade.h"
#import "MWLocationFacade.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface ShowMapViewController ()
{
    IBOutlet MKMapView * mapView;
    IBOutlet UIButton * setDefaultLocationButton;
    IBOutlet UIButton * cancelButton;
    CLLocation * userCoordinates;
    CLLocation * currentCoordinates;
    MKAnnotationView * selectedAnnotationView;
    NSString * description;
    
    NSTimer * updateLocationTimer;
}

@end

@implementation ShowMapViewController

- (NSBundle *)nibBundle
{
    return NSBundle.senderFrameworkResourcesBundle;
}

- (NSString *)nibName
{
    return @"ShowMapViewController";
}

- (IBAction)setDefaultLocationAction:(id)sender
{
    [[MWLocationFacade sharedInstance] isLocationUsageAllowed:^(BOOL locationAllowed) {
        if (locationAllowed)
            [self showMapAtZoom:0.01 andLocation:userCoordinates];
        else
            [self showLocationNotAvailiableAlert];
    }];
}

- (void)showLocationNotAvailiableAlert
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"error_location_not_available", nil)
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * okAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil];

    UIAlertAction * goToSettingsAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"error_location_not_available_go_to_settings", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {
                                                                    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                                }];
    [alert addAction:goToSettingsAction];
    [alert addAction:okAction];
    [alert mw_safePresentInViewController:self animated:YES completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)cancelAction:(id)sender
{
    [self.delegate pushOnLocation:self
        didFinishEnteringLocation:nil
                          andImge:nil
                         withDesc:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView * padView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 24)];
    [self.view addSubview:padView];
    padView.backgroundColor = [UIColor blackColor];
    
    UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(foundTap:)];
    
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [mapView addGestureRecognizer:tapRecognizer];
    mapView.delegate = self;
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    mapView = nil;
    setDefaultLocationButton = nil;
    cancelButton = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    CLLocation * showFromStart;
    userCoordinates = [[MWLocationFacade sharedInstance].locationManager deviceLocation];
    if (_incommingLocale) {
        showFromStart = [[CLLocation alloc] initWithLatitude:[_incommingLocale[@"lat"] floatValue]
                                                   longitude:[_incommingLocale[@"lon"] floatValue]];
    }
    else
    {
        if (_poiArray.count)
            [self addPoiFromArray];
        
        if (!userCoordinates)
            updateLocationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(setUserLocation) userInfo:nil repeats:YES];
        else
            showFromStart = userCoordinates;
    }

    if (showFromStart)
        [self showMapAtZoom:0.01 andLocation:showFromStart];
}

- (void)setUserLocation
{
    userCoordinates = [[MWLocationFacade sharedInstance].locationManager deviceLocation];
    if (userCoordinates)
    {
        [self showMapAtZoom:0.01 andLocation:userCoordinates];
        [updateLocationTimer invalidate];
        updateLocationTimer = nil;
    }
}

- (void)addPoiFromArray
{
    for (NSDictionary * poiDict in _poiArray)
    {
        [self addAnotationWithTitle:poiDict[@"t"] atLatitude:[poiDict[@"lt"] doubleValue] andLongitude:[poiDict[@"lg"] doubleValue]];
    }
}

- (void)addAnotationWithTitle:(NSString *)title atLatitude:(double)latitude andLongitude:(double)longitude
{
    CLLocationCoordinate2D annotationCoord;
    annotationCoord.latitude = latitude;
    annotationCoord.longitude = longitude;
    
    MKPointAnnotation * annotationPoint = [[MKPointAnnotation alloc] init];
    annotationPoint.coordinate = annotationCoord;
    annotationPoint.title = title;
    
    [mapView addAnnotation:annotationPoint];
}

- (void)openAnnotation:(id)annotation;
{
    [mapView selectAnnotation:annotation animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [updateLocationTimer invalidate];
    updateLocationTimer = nil;
}

- (IBAction)foundTap:(UITapGestureRecognizer *)recognizer
{
    [mapView setShowsUserLocation:NO];
    CGPoint point = [recognizer locationInView:mapView];
    
    CLLocationCoordinate2D tapPoint = [mapView convertPoint:point toCoordinateFromView:self.view];
    
    MKPointAnnotation * point1 = [[MKPointAnnotation alloc] init];
    
    point1.coordinate = tapPoint;
    
    point1.subtitle = [NSString stringWithFormat:@"Lat: %f, Long: %f",tapPoint.latitude, tapPoint.longitude];
    
    CLLocation * location = [[CLLocation alloc] initWithLatitude:tapPoint.latitude longitude:tapPoint.longitude];
    [self showMapAtZoom:0.01 andLocation:location];
}

- (void)locateAddress:(CLLocationCoordinate2D)coordinate {
    
    MKPointAnnotation * point = [[MKPointAnnotation alloc] init];
    point.coordinate = coordinate;
    point.title = @"";
    
    // NSLog(@"Lat: %f, Long: %f", coordinate.latitude, coordinate.longitude);
    MKCoordinateRegion region;
    region.center = coordinate;
    MKCoordinateSpan span;
    span.latitudeDelta=.005;
    span.longitudeDelta=.005;
    region.span = span;
    [mapView setRegion:region animated:YES];
    [mapView regionThatFits:region];
    
    [mapView addAnnotation:point];
}


- (void)showMapAtZoom:(float)zoom andLocation:(CLLocation *)locationForPin
{
    [mapView removeAnnotations:[mapView annotations]];
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    
    span.latitudeDelta = zoom;
    span.longitudeDelta = zoom;
    region.span = span;
    
    CLLocationCoordinate2D location = [self addressLocationFor:locationForPin.coordinate.latitude andLongitude:locationForPin.coordinate.longitude];
    region.center = location;
    
    [mapView setRegion:region animated:TRUE];
    [mapView regionThatFits:region];
    
    [self findDescription:locationForPin];
}

- (void)addAnnotationForMeWithTitle:(NSString *)title andLocation:(CLLocation *)location
{
    currentCoordinates = location;
    CLLocationCoordinate2D annotationCoord;
    annotationCoord.latitude = location.coordinate.latitude;
    annotationCoord.longitude = location.coordinate.longitude;
    
    MKPointAnnotation * annotationPoint = [[MKPointAnnotation alloc] init];
    annotationPoint.coordinate = annotationCoord;
    annotationPoint.title = title;
    description = title;
    [mapView addAnnotation:annotationPoint];
    [self performSelector:@selector(addAnnotation:) withObject:annotationPoint afterDelay:2.0];
}

- (void)addAnnotation:(MKPointAnnotation *)annotationPoint
{
    [self openAnnotation:annotationPoint];
}

- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation
{
    CalloutMapAnnotationView * calloutMapAnnotationView = (CalloutMapAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"CalloutAnnotation"];
    
    if (!calloutMapAnnotationView) {
        calloutMapAnnotationView = [[CalloutMapAnnotationView alloc] initWithAnnotation:annotation
                                                                                     reuseIdentifier:@"CalloutAnnotation"];
    }
    
    NSString * title = @"";
    if ([annotation.title length])
    {
        title = annotation.title;
    }
    else if ([annotation isKindOfClass:[MKPointAnnotation class]])
    {
        MKPointAnnotation * pointAnnotation = (MKPointAnnotation *)annotation;
        NSString * lat = [NSString stringWithFormat:@"%.6g", pointAnnotation.coordinate.latitude];
        NSString * lon = [NSString stringWithFormat:@"%.6g", pointAnnotation.coordinate.longitude];
        title = [NSString stringWithFormat:@"%@, %@", lat, lon];
    }

    calloutMapAnnotationView.title4Show = title;
    calloutMapAnnotationView.parentAnnotationView = selectedAnnotationView;
    calloutMapAnnotationView.mapView = mapView;
    calloutMapAnnotationView.delegate = self;
    
    return calloutMapAnnotationView;
}

- (void)actionButton:(CalloutMapAnnotationView *)controller
{
    if (_incommingLocale) {
        return;
    }
    
    if (_secondDelegateRun)
    {
        [self.delegate locationSelect:self
            didFinishEnteringLocation:currentCoordinates
                             withDesc:description];
    }
    else
    {
        UIImage * imageFromMap = [PBConsoleConstants renderViewToImage:mapView];
        
        CGSize sizeOfImage = imageFromMap.size;
        
        float yPosition = (sizeOfImage.height - 100)/2;
        float xPosition = (sizeOfImage.width - 100)/2;
        
        CGRect newBounds = CGRectMake(xPosition, yPosition, 100.0, 100.0);
        
        UIImage * imageSend = [imageFromMap croppedImage:newBounds];
        [self.delegate pushOnLocation:self
            didFinishEnteringLocation:currentCoordinates
                              andImge:imageSend
                             withDesc:description];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {

    selectedAnnotationView = view;
}

- (void)findDescription:(CLLocation *)descLoaction
{
    CLGeocoder * geocoder = [[CLGeocoder alloc] init];

    __block NSString * name;
    [geocoder reverseGeocodeLocation:descLoaction completionHandler:^(NSArray *placemarks, NSError *error) {
        // LLog(@"Finding address");
        if (error) {
            // LLog(@"Error %@", error.description);
        } else {
            CLPlacemark * placemark = [placemarks lastObject];
            name = [NSString stringWithFormat:@"%@", ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO)];
            [self addAnnotationForMeWithTitle:name andLocation:descLoaction];
        }
    }];
}

- (CLLocationCoordinate2D) addressLocationFor:(double)latitude andLongitude:(double)longitude
{
    CLLocationCoordinate2D location;
    location.latitude = latitude;
    location.longitude = longitude;
    return location;
}

@end
