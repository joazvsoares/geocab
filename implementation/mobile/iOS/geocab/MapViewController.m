//
//  MapViewController.m
//  geocab
//
//  Created by Vinicius Ramos Kawamoto on 18/09/14.
//  Copyright (c) 2014 Itaipu. All rights reserved.
//

#import "MapViewController.h"
#import "AppDelegate.h"
#import "AddNewMarkerViewController.h"
#import "MarkerDelegate.h"
#import "Layer.h"
#import "User.h"
#import "Marker.h"
#import "MarkerAttribute.h"
#import "AttributeType.h"
#import "ControllerUtil.h"
#import "LoginViewController.h"
#import <FacebookSDK/FacebookSDK.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface MapViewController ()

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (nonatomic) CGPoint location;
@property (nonatomic, strong) NSTimer *timer;
@property (retain, nonatomic) NSArray *layers;

@property (retain, nonatomic) UIActionSheet *actionSheet;

@property (strong, nonatomic) SelectLayerViewController *layerSelector;
@property (strong, nonatomic) UINavigationController *layerSelectorNavigator;
@property (strong, nonatomic) NSMutableArray *items;
@property (strong, nonatomic) NSArray *selectedLayers;

@property (weak, nonatomic) IBOutlet UIButton *menuButton;

extern NSUserDefaults *defaults;

@end

@implementation MapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _webView.delegate = self;
    _webView.scrollView.bounces = NO;
    _webView.scrollView.scrollEnabled = NO;
    
    [self loadWebView];
    
    //Configures the location manager to fetch the users location.
    if (nil == _locationManager)
        _locationManager = [[CLLocationManager alloc] init];
    
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    _selectedLayers = [NSMutableArray array];
    
    _layerSelector = [[SelectLayerViewController alloc] init];
    _layerSelector.delegate = self;
    _layerSelector.multipleSelection = YES;
    
    //Add marker buttons customization
    [_menuButton.layer setShadowOffset:CGSizeMake(2, 2)];
    [_menuButton.layer setShadowColor:[[UIColor blackColor] CGColor]];
    [_menuButton.layer setShadowOpacity:0.5];
    
    [ControllerUtil verifyInternetConection];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [super viewWillAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void) didEndMultipleSelecting:(NSArray *)selectedLayers {
    _selectedLayers = selectedLayers;
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//    transition.type = kCATransitionPush;
    transition.type = kCATransitionFromRight;
    [self.layerSelectorNavigator.view.window.layer addAnimation:transition forKey:nil];
    
    [_layerSelectorNavigator dismissViewControllerAnimated:NO completion:^{

    }];
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
    JSContext *context = [_webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    
    context[@"changeToAddMarker"] = ^(NSString *coordinates) {
        
        dispatch_sync(dispatch_get_main_queue(), ^{
    		[self performSegueWithIdentifier:@"addNewMarkerSegue" sender:self];
        });

        
    };
    
    context[@"showMarker"] = ^(NSNumber *markerId) {
        
        MarkerDelegate *markerDelegate = [[MarkerDelegate alloc] initWithUrl:@"marker"];
        
        [markerDelegate listAttributesById:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
            
            NSString *userId = [defaults objectForKey:@"userId"];
            NSString *userRole = [defaults objectForKey:@"userRole"];
            NSString *markerAttributes = operation.HTTPRequestOperation.responseString;
            
            MarkerDelegate *delegate = [[MarkerDelegate alloc] initWithUrl:@"files/markers/"];
            
            [delegate downloadMarkerAttributePhoto:markerId success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
				NSString *imageBase64 = responseObject != nil ? [NSString stringWithFormat:@"data:image/jpeg;base64,%@", [operation.responseData base64EncodedStringWithOptions:0]] : @"";
                
                NSString *functionCall = [NSString stringWithFormat:@"geocabapp.marker.showOptions('%@','%@','%@','%@','%@')", markerId, markerAttributes, imageBase64, userId, userRole];
                
                [_webView stringByEvaluatingJavaScriptFromString:functionCall];
                
            } fail:^(AFHTTPRequestOperation *operation, NSError *error) {
                
                NSString *functionCall = [NSString stringWithFormat:@"geocabapp.marker.showOptions('%@','%@','','%@','%@')", markerId, markerAttributes, userId, userRole];
                
                [_webView stringByEvaluatingJavaScriptFromString:functionCall];
                
            } login:[defaults objectForKey:@"email"] password:[defaults objectForKey:@"password"]];
            
            
        } userName:[defaults objectForKey:@"email"] password:[defaults objectForKey:@"password"] markerId:markerId];
    };
    
    context[@"changeToAddMarker"] = ^(NSString *coordinates) {
        
        [self performSegueWithIdentifier:@"addNewMarkerSegue" sender:self];
        
    };
    
}

- (void) didCheckedLayer:(Layer *)layer {
    if (layer.dataSource.url != nil) {
        NSRange index = [layer.name rangeOfString:@":"];
        NSRange position = [layer.dataSource.url rangeOfString:@"geoserver/" options:NSBackwardsSearch];
        NSString *typeLayer = [layer.name substringWithRange:NSMakeRange(0, index.location)];
        
        NSString *urlFormated = [NSString stringWithFormat:@"%@%@/wms", [layer.dataSource.url substringWithRange:NSMakeRange(0, position.location+10)],typeLayer ];
        
        NSString *functionCall = [NSString stringWithFormat:@"showLayer('%@', '%@', '%@', 'true')", urlFormated , layer.name, layer.title];
        [_webView stringByEvaluatingJavaScriptFromString:functionCall];
    } else {
        MarkerDelegate *markerDelegate = [[MarkerDelegate alloc] initWithUrl:@"marker/"];
        [markerDelegate list:^(RKObjectRequestOperation *operation, RKMappingResult *result) {

            NSString *markers = operation.HTTPRequestOperation.responseString;
			NSString *functionCall = [NSString stringWithFormat:@"geocabapp.addMarkers('%@')", markers];
			[_webView stringByEvaluatingJavaScriptFromString:functionCall];
            
        } failBlock:^(RKObjectRequestOperation *operation, NSError *error) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", @"")
                                                            message:NSLocalizedString(@"layer-fetch.error.message", @"")
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
            
        } userName:[defaults objectForKey:@"email"] password:[defaults objectForKey:@"password"] layerId:layer.id];
    }
}

- (void) didUnheckedLayer:(Layer *)layer {
    if (layer.dataSource.url != nil) {
        NSRange index = [layer.name rangeOfString:@":"];
        NSRange position = [layer.dataSource.url rangeOfString:@"geoserver/" options:NSBackwardsSearch];
        NSString *typeLayer = [layer.name substringWithRange:NSMakeRange(0, index.location)];
        
        NSString *urlFormated = [NSString stringWithFormat:@"%@%@/wms", [layer.dataSource.url substringWithRange:NSMakeRange(0, position.location+10)],typeLayer ];
        
        NSString *functionCall = [NSString stringWithFormat:@"showLayer('%@', '%@', '%@', false)", urlFormated , layer.name, layer.title];
        [_webView stringByEvaluatingJavaScriptFromString:functionCall];
    } else {
        
        NSString *functionCall = [NSString stringWithFormat:@"showMarker(null, null, '%@', null, null, null, false)", layer.name];
        [_webView stringByEvaluatingJavaScriptFromString:functionCall];
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)toggleMenu:(id)sender {
    
    _layerSelectorNavigator = [[UINavigationController alloc] initWithRootViewController:_layerSelector];
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFromLeft;
    transition.fillMode = kCAFillModeBoth;
    [self.view.window.layer addAnimation:transition forKey:nil];

    
    [self presentViewController:_layerSelectorNavigator animated:NO completion:nil];
}

//-(IBAction)addNewPoint:(id)sender {
//    if (!_addMyLocationButton.hidden) {
//        [self hideNewMarkerButtons];
//    } else {
//        [self showNewMarkerButtons];
//    }
//    
//    
//    [self hideMarkerOptions];
//}

//-(void)showNewMarkerButtons {
//    if (_addMyLocationButton.hidden) {
//        [UIView animateWithDuration:1
//                              delay:1.5
//                            options: UIViewAnimationCurveEaseInOut
//                         animations:^{
//                             _addMyLocationButton.hidden = false;
//                             _addAnotherLocationButton.hidden = false;
//                         } 
//                         completion:nil];
//    }
//}
//
//-(void)hideNewMarkerButtons {
//    if (!_addMyLocationButton.hidden) {
//        [UIView animateWithDuration:1
//                              delay:1.5
//                            options: UIViewAnimationCurveEaseInOut
//                         animations:^{
//                             _addMyLocationButton.hidden = true;
//                             _addAnotherLocationButton.hidden = true;
//                         }
//                         completion:nil];
//    }
//}

//- (void) showMarkerOptions {
//    if (_confirmMarkerButton.hidden) {
//        [UIView animateWithDuration:1
//                              delay:1.5
//                            options: UIViewAnimationCurveEaseInOut
//                         animations:^{
//                             _markerOptionsOverlay.hidden = false;
//                             _confirmMarkerButton.hidden = false;
//                             _changeMarkerButton.hidden = false;
//                             _cancelMarkerButton.hidden = false;
//                         }
//                         completion:nil];
//    }
//        
//}

- (void)loadWebView
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"webview" ofType:@"html" inDirectory:@"/"];
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    NSDate *eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0) {
        NSString *functionCall = [NSString stringWithFormat:@"addPoint(%.5f, %.5f, false)", location.coordinate.latitude, location.coordinate.longitude];
        [_webView stringByEvaluatingJavaScriptFromString:functionCall];
        
        _location.x = location.coordinate.latitude;
        _location.y = location.coordinate.longitude;
        
        [_locationManager stopUpdatingLocation];
//        [self hideNewMarkerButtons];
//        [self showMarkerOptions];
//        if (!_hintLabel.hidden) [UIView animateWithDuration:1  delay:1.5 options: UIViewAnimationCurveEaseInOut animations:^{ _hintLabel.hidden = true;} completion:nil];
//        if (!_showMarkerOptionsButton.hidden) [UIView animateWithDuration:1  delay:1.5 options: UIViewAnimationCurveEaseInOut animations:^{ _showMarkerOptionsButton.hidden = true;} completion:nil];
    }
}

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.identifier isEqualToString:@"addNewMarkerSegue"]) {
//        
//        NSLog(@"%.5f  %.5f", _locationManager.location.coordinate.latitude, _locationManager.location.coordinate.longitude);
//        
//        AddNewMarkerViewController *addNewMarkerViewController = (AddNewMarkerViewController*) segue.destinationViewController;
//        addNewMarkerViewController.latitude = _location.x;
//        addNewMarkerViewController.longitude = _location.y;
//    }
//}

-(IBAction)addCurrentLocation:(id)sender {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
        [_locationManager requestWhenInUseAuthorization];
    }
    [_locationManager startUpdatingLocation];
}

//-(IBAction)addSelectedLocation:(id)sender {
//    [self hideNewMarkerButtons];
//    [self hideMarkerOptions];
//    [UIView animateWithDuration:1  delay:1.5 options: UIViewAnimationCurveEaseInOut animations:^{ _hintLabel.hidden = !_hintLabel.hidden;} completion:nil];
//    [_webView stringByEvaluatingJavaScriptFromString:@"bindTouchEvent()"];
//}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
            [_locationManager requestWhenInUseAuthorization];
        }
        [_locationManager startUpdatingLocation];
    }
}

//- (IBAction)changeMarkerRegistration:(id)sender {
//    [self hideMarkerOptions];
//    [self hideNewMarkerButtons];
//    
//    [UIView animateWithDuration:1  delay:1.5 options: UIViewAnimationCurveEaseInOut animations:^{ _hintLabel.hidden = false; } completion:nil];
//    if (!_showMarkerOptionsButton.hidden) [UIView animateWithDuration:1  delay:1.5 options: UIViewAnimationCurveEaseInOut animations:^{ _showMarkerOptionsButton.hidden = true; } completion:nil];
//    
//    [_webView stringByEvaluatingJavaScriptFromString:@"bindTouchEvent()"];
//}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError: %@", error);
    
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"gps.error.title", @"") message:NSLocalizedString(@"gps.error.message", @"") delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [errorAlert show];
}

-(void)logoutButtonPressed {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"logout-confirmation.title", @"")
                                                    message:NSLocalizedString(@"logout-confirmation.message", @"")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"no", @"")
                                          otherButtonTitles:NSLocalizedString(@"yes", @""), nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch(buttonIndex) {
        case 0:
            break;
        case 1: {
//            UINavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"navigationController"];
//            [[[[UIApplication sharedApplication] delegate] window] setRootViewController:navigationController];
            
            defaults = [NSUserDefaults standardUserDefaults];
            NSDictionary * dict = [defaults dictionaryRepresentation];
            for (id key in dict) {
                
                //heck the keys if u need
                [defaults removeObjectForKey:key];
            }
            [defaults synchronize];
            
            if ([[FBSession activeSession] isOpen]) {
                [[FBSession activeSession] closeAndClearTokenInformation];
            }
            
            [_layerSelectorNavigator dismissViewControllerAnimated:NO completion:^{
               [self performSegueWithIdentifier:@"logoutSegue" sender:nil];
            }];
            break;
        }
    }
}

@end
