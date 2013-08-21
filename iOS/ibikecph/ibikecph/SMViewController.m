	//
//  SMViewController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 22/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMViewController.h"

#import "SMContactsCell.h"
#import "SMContactsHeader.h"

#import "SMLocationManager.h"

#import "RMMapView.h"
#import "RMAnnotation.h"
#import "RMMarker.h"
#import "RMShape.h"

#import "SMiBikeCPHMapTileSource.h"
#import "RMOpenStreetMapSource.h"

#import "SMRouteNavigationController.h"
#import "SMAppDelegate.h"
#import "SMAnnotation.h"
#import "SMGeocoder.h"
#import <MapKit/MapKit.h>

#import "SMEnterRouteController.h"
#import "SMUtil.h"
#import "SMAddFavoriteCell.h"
#import "SMEmptyFavoritesCell.h"

#import "DAKeyboardControl.h"
#import "SMFavoritesUtil.h"
#import "SMAPIRequest.h"

#import "SMReminderTableViewCell.h"

#import "SMRouteTypeSelectCell.h"

#import "SMTransportation.h"
#import "SMTransportationLine.h"
#import "SMStationInfo.h"

typedef enum {
    menuFavorites = 0,
    menuAccount = 1,
    menuInfo = 2,
    menuReminders = 3
} MenuType;

typedef enum {
    typeFavorite,
    typeHome,
    typeWork,
    typeSchool,
    typeNone
} FavoriteType;

@interface SMViewController () <SMAPIRequestDelegate>{
    MenuType menuOpen;
    
    FavoriteType currentFav;
    
    CLLocation* lastLocation;
    
    CLLocation* cStart;
    CLLocation* cEnd;
}

@property (nonatomic, strong) SMContacts *contacts;
@property (nonatomic, strong) RMMapView *mpView;

@property (weak, nonatomic) IBOutlet UIButton *btnReminders;
@property (weak, nonatomic) IBOutlet UIView *headerReminders;
@property (weak, nonatomic) IBOutlet UITableView *tblFavorites;
@property (weak, nonatomic) IBOutlet UIButton *btnFavorites;
@property (weak, nonatomic) IBOutlet UIImageView *imgReminders;
@property BOOL reminderFolded;

/**
 * data sources for tables
 */
@property (nonatomic, strong) NSMutableArray * favoritesList;
@property (nonatomic, strong) NSMutableArray * favorites;
@property (nonatomic, strong) NSString * destination;
@property (nonatomic, strong) NSString * source;

@property (nonatomic, strong) NSString * findFrom;
@property (nonatomic, strong) NSString * findTo;
@property (nonatomic, strong) NSArray * findMatches;
@property (nonatomic, strong) SMAnnotation * destinationPin;

@property (nonatomic, strong) id jsonRoot;

@property (weak, nonatomic) IBOutlet UITableView *overlaysMenuTable;
@property (nonatomic, strong) NSArray* overlaysMenuItems;

@property CLLocationCoordinate2D startLoc;
@property CLLocationCoordinate2D endLoc;
@property (nonatomic, strong) NSString * startName;
@property (nonatomic, strong) NSString * endName;

@property (nonatomic, strong) NSDictionary * locDict;
@property NSInteger locIndex;
@property (nonatomic, strong) NSString * favName;

@property (nonatomic, strong) SMFavoritesUtil * favs;

@property (nonatomic, strong) SMAPIRequest * request;

// Markers
//@property BOOL metroMarkersVisible;
//@property BOOL serviceMarkersVisible;
//@property BOOL stationMarkersVisible;
//@property BOOL pathVisible;
//@property (nonatomic, strong) NSMutableArray* metroMarkers;
//@property (nonatomic, strong) NSMutableArray* serviceMarkers;
//@property (nonatomic, strong) NSMutableArray* stationMarkers;

@end

@implementation SMViewController{
    BOOL observersAdded;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - view lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];

    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackTranslucent];
    
    [RMMapView class];
    
    animationShown = NO;
    self.reminderFolded = NO;
    
    self.endMarkerAnnotation = nil;
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(0, 0);
    self.endMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:coord andTitle:@""];
    
    menuOpen = menuFavorites;
    
    [SMLocationManager instance];
    
//    // Markers
//    self.metroMarkers = [[NSMutableArray alloc] init];
//    self.serviceMarkers = [[NSMutableArray alloc] init];
//    self.stationMarkers = [[NSMutableArray alloc] init];
//    self.pathVisible = YES;
//    self.metroMarkersVisible = NO;
//    self.serviceMarkersVisible = NO;
//    self.stationMarkersVisible = NO;
    
    /**
     * start with empty favorites array
     */
    self.favorites = [@[] mutableCopy];
    [self setFavoritesList:[SMFavoritesUtil getFavorites]];
    
    [self.appDelegate.mapOverlays loadMarkers];

#ifndef TESTING     
    [buttonAddFakeStation setHidden:YES];
#endif
    /**
     * removed for alpha
     */
//    [self performSelector:@selector(getPhoneContacts) withObject:nil afterDelay:0.001f];
    /**
     * end alpha remove
     */
    
    currentScreen = screenMap;
    [self.mpView setTileSource:TILE_SOURCE];
    [self.mpView setDelegate:self];
    [self.mpView setMaxZoom:MAX_MAP_ZOOM];

    [self.mpView setCenterCoordinate:CLLocationCoordinate2DMake(55.675455,12.566643) animated:NO];
    [self.mpView setZoom:16];
    [self.mpView setEnableBouncing:TRUE];
    
    [self openMenu:menuFavorites];
    
    UITapGestureRecognizer * dblTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    [dblTap setNumberOfTapsRequired:2];
    [blockingView addGestureRecognizer:dblTap];

    self.tableFooter = [SMAddFavoriteCell getFromNib];

    [self.tableFooter setDelegate:self];
    [self.tableFooter.text setText:translateString(@"cell_add_favorite")];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(favoritesChanged:) name:kFAVORITES_CHANGED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidToken:) name:@"invalidToken" object:nil];
    
    [centerView setupForHorizontalSwipeWithStart:0.0f andEnd:260.0f andStart:0.0f andPullView:menuBtn];

    [centerView addPullView:blockingView];

    [centerView setupForHorizontalSwipeWithStart:0.0f andEnd:260.0f andStart:0.0f andPullView:overlayMenuBtn];
    
    [self setTitle:translateString(@"reminder_title") forButton:remindersHeaderButton];
    [self setTitle:translateString(@"account") forButton:accountHeaderButton];
    [self setTitle:translateString(@"about_css") forButton:aboutHeaderButton];

    self.overlaysMenuItems = OSRM_SERVERS;
    [self.overlaysMenuTable setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [self.overlaysMenuTable reloadData];
    
    if ( self.appDelegate.mapOverlays == nil ) {
        self.appDelegate.mapOverlays = [[SMMapOverlays alloc] initWithMapView:nil];
    }
    [self.appDelegate.mapOverlays useMapView:self.mpView];
    [self.appDelegate.mapOverlays loadMarkers];
    
    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapMenuBtn:)];
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanMenuBtn:)];
    [menuBtn addGestureRecognizer:singleTap];
    [menuBtn addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer* singleTapOverlayMenu = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapOverlayMenuBtn:)];
    UIPanGestureRecognizer* panGestureOverlayMenu = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanOverlayMenuBtn:)];
    [overlayMenuBtn addGestureRecognizer:singleTapOverlayMenu];
    [overlayMenuBtn addGestureRecognizer:panGestureOverlayMenu];
}

-(void)onTapMenuBtn:(UITapGestureRecognizer*)tapGR {
    //if (centerView.frame.origin.x == 0) {
        
        [UIView animateWithDuration:0.2f animations:^{
            [menuView setAlpha:1.0];
        }];
        
        //[menuView setHidden:YES];
    //}
    NSLog(@"onTap");
}

-(void)onPanMenuBtn:(UIPanGestureRecognizer*)panGR {
    if (centerView.frame.origin.x == 0) {
        [UIView animateWithDuration:0.2f animations:^{
            [menuView setAlpha:1.0];
        }];
        NSLog(@"onPan");
    }
}

-(void)onTapOverlayMenuBtn:(UITapGestureRecognizer*)tapGR {
    //if (centerView.frame.origin.x == 0) {
        
        [UIView animateWithDuration:0.2f animations:^{
            [menuView setAlpha:0.0];
        }];
        
        //[menuView setHidden:YES];
    //}
    NSLog(@"onTapOverlay");
}

-(void)onPanOverlayMenuBtn:(UIPanGestureRecognizer*)panGR {
    if (centerView.frame.origin.x == 0) {
        [UIView animateWithDuration:0.2f animations:^{
            [menuView setAlpha:0.0];
        }];
        NSLog(@"onPanOverlay");
    }
}


-(void)setTitle:(NSString*)pTitle forButton:(UIButton*)pButton{
    [pButton setTitle:pTitle forState:UIControlStateNormal];
    [pButton setTitle:pTitle forState:UIControlStateHighlighted];
    [pButton setTitle:pTitle forState:UIControlStateSelected];
}

- (void)invalidToken:(NSNotification*)notification {
    [SMFavoritesUtil saveFavorites:@[]];
    [account_label setText:translateString(@"account_login")];
    self.favoritesList = [SMFavoritesUtil getFavorites];
    [self openMenu:menuFavorites];
}

- (IBAction)doubleTap:(UITapGestureRecognizer*)sender {
    
}

- (void)viewDidUnload {
    self.mpView = nil;
    menuView = nil;
    centerView = nil;
    dropPinView = nil;
    tblMenu = nil;
    fadeView = nil;
    debugLabel = nil;
    buttonTrackUser = nil;
    favHeader = nil;
    accHeader = nil;
    infHeader = nil;
    favEditStart = nil;
    favEditDone = nil;
    addFavFavoriteButton = nil;
    addFavHomeButton = nil;
    addFavWorkButton = nil;
    addFavSchoolButton = nil;
    addFavAddress = nil;
    addFavName = nil;
    mainMenu = nil;
    addMenu = nil;
    editTitle = nil;
    editSaveButton = nil;
    editDeleteButton = nil;
    addSaveButton = nil;
    blockingView = nil;
    findRouteBig = nil;
    findRouteSmall = nil;
    self.tableFooter = nil;
    account_label = nil;
    routeStreet = nil;
    menuBtn = nil;
    menuBtn = nil;
    pinButton = nil;
    [self setBtnReminders:nil];
    [self setBtnReminders:nil];
    [self setHeaderReminders:nil];
    [self setTblFavorites:nil];
    [self setBtnFavorites:nil];
    [self setImgReminders:nil];
    remindersHeaderButton = nil;
    accountHeaderButton = nil;
    aboutHeaderButton = nil;
    overlayMenuBtn = nil;
    overlayMenu = nil;

    [self setOverlaysMenuTable:nil];

    buttonAddFakeStation = nil;

    [self setMainMenuBtn:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackTranslucent];
    
    [self readjustViewsForRotation:self.interfaceOrientation];
    
    self.findFrom = @"";
    self.findTo = @"";
    
    [debugLabel setText:BUILD_STRING];
    
    findRouteSmall.alpha = 1.0f;
    findRouteBig.alpha = 0.0f;
    
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        [account_label setText:translateString(@"account")];
    } else {
        [SMFavoritesUtil saveFavorites:@[]];
        [account_label setText:translateString(@"account_login")];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];

    if(observersAdded){
        [self.mpView removeObserver:self forKeyPath:@"userTrackingMode"];
        [centerView removeObserver:self forKeyPath:@"frame"];
        [tblMenu removeObserver:self forKeyPath:@"editing"];
    }
    CGRect frame = dropPinView.frame;
    frame.origin.y = self.mpView.frame.origin.y + self.mpView.frame.size.height;
    [dropPinView setFrame:frame];
    frame = buttonTrackUser.frame;
    frame.origin.y = dropPinView.frame.origin.y - 65.0f;
    [buttonTrackUser setFrame:frame];
    
    frame = overlayMenuBtn.frame;
    frame.origin.y = dropPinView.frame.origin.y - 65.0f;
    [overlayMenuBtn setFrame:frame];

    [self.view removeKeyboardControl];
    [super viewWillDisappear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [SMUser user].tripRoute= nil;
    [SMUser user].route= nil;

    if ([[NSFileManager defaultManager] fileExistsAtPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"]]) {
        NSDictionary * d = [NSDictionary dictionaryWithContentsOfFile: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"]];
        
        NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)",CURRENT_POSITION_STRING, [[d objectForKey:@"startLat"] doubleValue], [[d objectForKey:@"startLong"] doubleValue], [d objectForKey:@"destination"], [[d objectForKey:@"endLat"] doubleValue], [[d objectForKey:@"endLong"] doubleValue]];
        debugLog(@"%@", st);
        if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Route:" withAction:@"Resume" withLabel:st withValue:0]) {
            debugLog(@"error in trackPageview");
        }
        
        /**
         * show new route
         */
        CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:[[d objectForKey:@"endLat"] floatValue] longitude:[[d objectForKey:@"endLong"] floatValue]];
        CLLocation * cStart = [[CLLocation alloc] initWithLatitude:[[d objectForKey:@"startLat"] floatValue] longitude:[[d objectForKey:@"startLong"] floatValue]];
        
        SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
        [r setRequestIdentifier:@"rowSelectRoute"];
        [r setAuxParam:[d objectForKey:@"destination"]];
        [r findNearestPointForStart:cStart andEnd:cEnd];        
        
//        /**
//         * drop pin
//         */
//        CLLocation * loc = [[CLLocation alloc] initWithLatitude:[[d objectForKey:@"endLat"] doubleValue] longitude:[[d objectForKey:@"endLong"] doubleValue]];
//        
//        SMRequestOSRM * r2 = [[SMRequestOSRM alloc] initWithDelegate:self];
//        [r2 setRequestIdentifier:@"getNearestForPinDrop"];
//        [r2 findNearestPointForLocation:loc];
//        
//        [self.mpView removeAllAnnotations];
//        SMAnnotation *endMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:CLLocationCoordinate2DMake([[d objectForKey:@"endLat"] doubleValue], [[d objectForKey:@"endLong"] doubleValue]) andTitle:@""];
//        endMarkerAnnotation.annotationType = @"marker";
//        endMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerFinish"];
//        endMarkerAnnotation.anchorPoint = CGPointMake(0.5, 0.5);
//        [self.mpView addAnnotation:endMarkerAnnotation];
//        [self setDestinationPin:endMarkerAnnotation];
    } else {
        observersAdded= YES;
        [self.mpView addObserver:self forKeyPath:@"userTrackingMode" options:0 context:nil];
        [tblMenu addObserver:self forKeyPath:@"editing" options:0 context:nil];
        [centerView addObserver:self forKeyPath:@"frame" options:0 context:nil];
    }
    
    [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
    
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        SMFavoritesUtil * fv = [[SMFavoritesUtil alloc] initWithDelegate:self];
        [self setFavs:fv];
        [self.favs fetchFavoritesFromServer];
    } else {
        [self favoritesChanged:nil];
    }
    
    [self.appDelegate.mapOverlays useMapView:self.mpView];
    [self.appDelegate.mapOverlays toggleMarkers];
    
    if ( self.appDelegate.mapOverlays.pathVisible )
        [self.overlaysMenuTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
    if ( self.appDelegate.mapOverlays.serviceMarkersVisible )
        [self.overlaysMenuTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
    if ( self.appDelegate.mapOverlays.stationMarkersVisible )
        [self.overlaysMenuTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
    if ( self.appDelegate.mapOverlays.metroMarkersVisible )
        [self.overlaysMenuTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
}

#pragma mark - custom methods

- (CGFloat)heightForFavorites {
    if ([self.favoritesList count] == 0) {
        //return [SMEmptyFavoritesCell getHeight] + 45.0f * 2.0;
        CGFloat startY = favHeader.frame.origin.y;
        CGFloat maxHeight = menuView.frame.size.height - startY;
        return MIN(tblMenu.contentSize.height + 45.0f, maxHeight - 3 * 45.0f);
    } else {
        CGFloat startY = favHeader.frame.origin.y;
        CGFloat maxHeight = menuView.frame.size.height - startY;
        return MIN(tblMenu.contentSize.height + 45.0f, maxHeight - 3 * 45.0f);
    }
    return 45.0f;
}

-(void)setDestination:(NSString *)pDestination{
    _destination= pDestination;
}
- (IBAction)openOverlaysMenu:(UIImageView*)sender {
    if (centerView.frame.origin.x == 0) {
        
        [UIView animateWithDuration:0.2f animations:^{
            [menuView setAlpha:0.0];
        }];
        
        //[menuView setHidden:YES];
    }
}

- (IBAction)panMainMenu:(id)sender {
    if (centerView.frame.origin.x == 0) {
        [menuView setHidden:NO];
    }
}

- (IBAction)touchOpenOverlaysMenu:(id)sender {
    //if (centerView.frame.origin.x == 0) {
        //[menuView setHidden:YES];
        [UIView animateWithDuration:0.2f animations:^{
            [menuView setAlpha:0.0];
        }];
    //}
}
- (IBAction)touchOpenMainMenu:(id)sender {
    if (centerView.frame.origin.x == 0) {
       // [menuView setHidden:NO];
    }
}

- (void)openMenu:(NSInteger)menuType {
    
    [UIView animateWithDuration:0.2f animations:^{
        [menuView setAlpha:1.0];
    }];
    
    //[menuView setHidden:NO];
    
    CGFloat startY = favHeader.frame.origin.y;
    CGFloat maxHeight = menuView.frame.size.height - startY;
    [tblMenu reloadData];
    switch (menuType) {
        case menuReminders: {
            [favEditDone setHidden:YES];
            [favEditStart setHidden:YES];
                       
            CGRect frame = self.headerReminders.frame;
            frame = self.headerReminders.frame;
            frame.origin.y = favHeader.frame.origin.y + 45.0f;
            frame.size.height = maxHeight - 3 * 45.0f;
            [self.headerReminders setFrame:frame];            
            
            //frame.origin.y = startY + 2 * 45.0f;
            
            startY = self.headerReminders.frame.origin.y + self.headerReminders.frame.size.height;
            
            frame.origin.y = startY;
            frame.size.height = 45.0f;
            [infHeader setFrame:frame];
            
            frame = favHeader.frame;
            frame.origin.y = 0; //startY;
            frame.size.height = 45.0f;
            [favHeader setFrame:frame];
            
            frame = accHeader.frame;
            frame.origin.y = startY + 45.0f;
            frame.size.height = 45.0f;
            [accHeader setFrame:frame];

            
        }
            break;
        case menuInfo: {
            [favEditDone setHidden:YES];
            [favEditStart setHidden:YES];
            CGRect frame = infHeader.frame;
            frame.origin.y = startY + 2 * 45.0f;
            frame.size.height = maxHeight - 2 * 45.0f;
            [infHeader setFrame:frame];
            
            frame = favHeader.frame;
            frame.origin.y = startY;
            frame.size.height = 45.0f;
            [favHeader setFrame:frame];
            
            frame = accHeader.frame;
            frame.origin.y = startY + 45.0f;
            frame.size.height = 45.0f;
            [accHeader setFrame:frame];
            
            frame = self.btnReminders.frame;
            frame.origin.y = infHeader.frame.origin.y + 45.0f;
            frame.size.height = 45.0f;
            [self.btnReminders setFrame:frame];
        }
            break;
        case menuAccount: {
            [favEditDone setHidden:YES];
            [favEditStart setHidden:YES];
            CGRect frame = accHeader.frame;
            frame.origin.y = startY + 45.0f;
            frame.size.height = maxHeight - 2 * 45.0f;
            [accHeader setFrame:frame];
            
            frame = favHeader.frame;
            frame.origin.y = startY;
            frame.size.height = 45.0f;
            [favHeader setFrame:frame];
            
            frame = infHeader.frame;
            frame.origin.y = accHeader.frame.size.height + accHeader.frame.origin.y;
            frame.size.height = 45.0f;
            [infHeader setFrame:frame];
            
            frame = self.btnReminders.frame;
            frame.origin.y = infHeader.frame.origin.y + 45.0f;
            frame.size.height = 45.0f;
            [self.btnReminders setFrame:frame];
        }
            break;
        case menuFavorites: {
        
            [tblMenu reloadData];
            
            if ([self.favoritesList count] == 0) {
                [favEditDone setHidden:YES];
                [favEditStart setHidden:YES];
            } else {
                if (tblMenu.isEditing) {
                    [favEditDone setHidden:NO];
                    [favEditStart setHidden:YES];
                } else {
                    [favEditDone setHidden:YES];
                    [favEditStart setHidden:NO];
                }
            }
            CGRect frame = favHeader.frame;
            frame.origin.y = startY;
            frame.size.height = [self heightForFavorites];
            [favHeader setFrame:frame];
            frame = accHeader.frame;
            frame.origin.y = startY + favHeader.frame.size.height + 45.0;
            frame.size.height = 45.0f;
            [accHeader setFrame:frame];
            frame = infHeader.frame;
            frame.origin.y = accHeader.frame.origin.y + 45.0f;
            frame.size.height = 45.0f;
            [infHeader setFrame:frame];
            
            frame = self.headerReminders.frame;
            frame.origin.y = accHeader.frame.origin.y - 45.0f;
            frame.size.height = 45.0f;
            [self.headerReminders setFrame:frame];
            
            if (favHeader.frame.size.height < tblMenu.contentSize.height) {
                [tblMenu setBounces:YES];
            } else {
                [tblMenu setBounces:NO];
            }
            
        }
            break;
        default:
            break;
    }    
}

- (IBAction)tapFavorites:(id)sender {
    [UIView animateWithDuration:0.4f animations:^{
        [self openMenu:menuFavorites];
    }];
}

- (IBAction)onSelectAccount:(UIButton *)sender {
    [self tapAccount:sender];
}

- (IBAction)tapAccount:(id)sender {
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        [self performSegueWithIdentifier:@"mainToAccount" sender:nil];
    } else {
        [self performSegueWithIdentifier:@"mainToLogin" sender:nil];
    }
}

- (IBAction)onSelectInfo:(UIButton *)sender {
    [self tapInfo:sender];
}

- (IBAction)tapInfo:(id)sender {
    [self performSegueWithIdentifier:@"openAbout" sender:nil];
}

-(void)addFakeStationWithLocation:(CLLocation*)loc{

    SMTransportationLine* line= [[SMTransportation instance].lines objectAtIndex:0];
    NSMutableArray* arr= [[NSMutableArray alloc] initWithArray:line.stations];
    SMStationInfo* station= [[SMStationInfo alloc] initWithLongitude:lastLocation.coordinate.longitude latitude:lastLocation.coordinate.latitude name:@"Station" type:SMStationInfoTypeTrain];
    [arr addObject:station];
    line.stations= [NSArray arrayWithArray:arr];
}

- (void)longSingleTapOnMap:(RMMapView *)map at:(CGPoint)point {
    if (blockingView.alpha > 0) {
        return;
    }
    
    for (SMAnnotation * annotation in self.mpView.annotations) {
        if ([annotation.annotationType isEqualToString:@"marker"] && [annotation isKindOfClass:[SMAnnotation class]]) {
            if (annotation.calloutShown) {
                [annotation hideCallout];
            }
        }
    }
    
    CLLocationCoordinate2D coord = [self.mpView pixelToCoordinate:point];
    CLLocation * loc = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    debugLog(@"pin drop LOC: %@", loc);
    debugLog(@"pin drop POINT: %@", NSStringFromCGPoint(point));
    
#ifdef TESTING
    lastLocation= loc;
#endif

    [self displayPinWithPoint:point atLocation:loc ];
    [self showPinDrop];
    [self displayDestinationNameWithLocation:loc];
}

-(void)displayPinWithPoint:(CGPoint)point atLocation:(CLLocation*)loc{
    UIImageView * im = [[UIImageView alloc] initWithFrame:CGRectMake(point.x - 17.0f, 0.0f, 34.0f, 34.0f)];
    [im setImage:[UIImage imageNamed:@"markerFinish"]];
    [self.mpView addSubview:im];
    [UIView animateWithDuration:0.2f animations:^{
        [im setFrame:CGRectMake(point.x - 17.0f, point.y - 34.0f, 34.0f, 34.0f)];
    } completion:^(BOOL finished) {
        debugLog(@"dropped pin");
        
        if ( self.endMarkerAnnotation != nil ) {
            [self.mpView removeAnnotation:self.endMarkerAnnotation];
            self.endMarkerAnnotation = nil;
            self.endMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:loc.coordinate andTitle:@""];
        }
        
        self.endMarkerAnnotation.annotationType = @"marker";
        self.endMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerFinish"];
        self.endMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
        [self.mpView addAnnotation:self.endMarkerAnnotation];
        [self setDestinationAnnotation:self.endMarkerAnnotation withLocation:loc];
        
        [im removeFromSuperview];
        
//        [self showPinDrop];
        
        
    }];
}

-(void)setDestinationAnnotation:(SMAnnotation*)annotation withLocation:(CLLocation*)loc{
    [self setDestinationPin:annotation];
    
    [self.destinationPin setSubtitle:@""];
    [self.destinationPin setDelegate:self];
    [self.destinationPin setRoutingCoordinate:loc];
}

-(void)displayDestinationNameWithString:(NSString*)str{
    [routeStreet setText:str];
}

-(void)displayDestinationNameWithLocation:(CLLocation*)loc{
    [SMGeocoder reverseGeocode:loc.coordinate completionHandler:^(NSDictionary *response, NSError *error) {
        [routeStreet setText:[response objectForKey:@"title"]];
        if ([routeStreet.text isEqualToString:@""]) {
            [routeStreet setText:[NSString stringWithFormat:@"%f, %f", loc.coordinate.latitude, loc.coordinate.longitude]];
        }
        
        NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF.name = %@ AND SELF.address = %@", routeStreet.text, routeStreet.text];
        NSArray * arr = [[SMFavoritesUtil getFavorites] filteredArrayUsingPredicate:pred];
        if ([arr count] > 0) {
            [pinButton setSelected:YES];
        } else {
            [pinButton setSelected:NO];
        }
        
        NSNumber* loginID= [self.appDelegate.appSettings objectForKey:@"id"];
        if(loginID && loginID.intValue!=0){
            pinButton.enabled = YES;
        }
        
        
        [self.destinationPin setTitle:[response objectForKey:@"title"]];
        
    }];

}
- (void)readjustViewsForRotation:(UIInterfaceOrientation) orientation {
    CGFloat scrWidth;
    CGFloat scrHeight;
    
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        scrWidth = self.view.frame.size.width;
        scrHeight = self.view.frame.size.height;
    } else {
        scrWidth = self.view.frame.size.height;
        scrHeight = self.view.frame.size.width;
    }
    
    CGRect frame = centerView.frame;
    frame.size.width = scrWidth;
    frame.size.height = scrHeight;
//    frame.origin.x = 0.0f;
    [centerView setFrame:frame];
    
    frame = dropPinView.frame;
    frame.origin.y = self.mpView.frame.origin.y + self.mpView.frame.size.height;
    [dropPinView setFrame:frame];
}

#pragma mark - rotation

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self readjustViewsForRotation:toInterfaceOrientation];
}

#pragma mark - button actions

- (IBAction)goToPin:(id)sender {
    [self annotationActivated:self.destinationPin];
    [self hidePinDrop];
}

- (IBAction)pinAddToFavorites:(id)sender {
    
    NSDictionary * d = @{
                         @"name" : routeStreet.text,
                         @"address" : routeStreet.text,
                         @"startDate" : [NSDate date],
                         @"endDate" : [NSDate date],
                         @"source" : @"favorites",
                         @"subsource" : @"favorite",
                         @"lat" :[NSNumber numberWithDouble: self.destinationPin.coordinate.latitude],
                         @"long" : [NSNumber numberWithDouble: self.destinationPin.coordinate.longitude],
                         @"order" : @0
                         };
    NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF.name = %@ AND SELF.address = %@", routeStreet.text, routeStreet.text];
    NSArray * arr = [[SMFavoritesUtil getFavorites] filteredArrayUsingPredicate:pred];
    SMFavoritesUtil * fv = [SMFavoritesUtil instance];
    if ([arr count] > 0) {
        [pinButton setSelected:NO];
        [fv deleteFavoriteFromServer:[arr objectAtIndex:0]];
        if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Favorites" withAction:@"Delete" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude] withValue:0]) {
            debugLog(@"error in trackEvent");
        }        
    } else {
        [pinButton setSelected:YES];
        [fv addFavoriteToServer:d];
        if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Favorites" withAction:@"New" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude] withValue:0]) {
            debugLog(@"error in trackEvent");
        }
    }
}

- (void)showPinDrop {
    CGRect frame = dropPinView.frame;
    frame.origin.y = centerView.frame.size.height - 6.0f;
    [dropPinView setFrame:frame];
    [dropPinView setHidden:NO];
    routeStreet.text = @"";
    [pinButton setEnabled:NO];
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        CGRect frame = dropPinView.frame;
        frame.origin.y = centerView.frame.size.height - dropPinView.frame.size.height;
        [dropPinView setFrame:frame];
        
        frame = buttonTrackUser.frame;
        frame.origin.y = dropPinView.frame.origin.y - 65.0f;
        [buttonTrackUser setFrame:frame];
        
        frame = overlayMenuBtn.frame;
        frame.origin.y = dropPinView.frame.origin.y - 65.0f;
        [overlayMenuBtn setFrame:frame];
        
    } completion:^(BOOL finished) {
    }];
}

- (void)hidePinDrop {
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        CGRect frame = dropPinView.frame;
        frame.origin.y = self.mpView.frame.origin.y + self.mpView.frame.size.height;
        [dropPinView setFrame:frame];
        frame = buttonTrackUser.frame;
        frame.origin.y = dropPinView.frame.origin.y - 65.0f;
        [buttonTrackUser setFrame:frame];
        
        frame = overlayMenuBtn.frame;
        frame.origin.y = dropPinView.frame.origin.y - 65.0f;
        [overlayMenuBtn setFrame:frame];
        
    } completion:^(BOOL finished) {
        
    }];
    
}

- (IBAction)slideMenuOpen:(id)sender {
    if (centerView.frame.origin.x == 0.0f) {
        [UIView animateWithDuration:0.2f animations:^{
            CGRect frame = centerView.frame;
            frame.origin.x = 260.0f;
            [centerView setFrame:frame];
        } completion:^(BOOL finished) {
            blockingView.alpha = 1.0f;
        }];
    } else {
        [UIView animateWithDuration:0.2f animations:^{
            CGRect frame = centerView.frame;
            frame.origin.x = 0.0f;
            [centerView setFrame:frame];
        } completion:^(BOOL finished) {
            blockingView.alpha = 0.0f;
        }];        
    }    
}

- (IBAction)enterRoute:(id)sender {
    [self performSegueWithIdentifier:@"enterRouteSegue" sender:nil];
}

- (IBAction)editFavoriteShow:(id)sender {
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
    }];

    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        addFavAddress.text = [self.locDict objectForKey:@"address"];
        addFavName.text = [self.locDict objectForKey:@"name"];
        editTitle.text = translateString(@"edit_favorite");
        [addSaveButton setHidden:YES];
        [editSaveButton setHidden:NO];
        [editDeleteButton setHidden:NO];
        
        if ([[self.locDict objectForKey:@"subsource"] isEqualToString:@"home"]) {
            currentFav = typeHome;
            [self addSelectHome:nil];
        } else if ([[self.locDict objectForKey:@"subsource"] isEqualToString:@"work"]) {
            currentFav = typeWork;
            [self addSelectWork:nil];
        } else if ([[self.locDict objectForKey:@"subsource"] isEqualToString:@"school"]) {
            currentFav = typeSchool;
            [self addSelectSchool:nil];
        } else {
            currentFav = typeFavorite;
            [self addSelectFavorite:nil];
        }
        
        [self animateEditViewShow];
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_not_logged_in") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
    }
}

- (IBAction)addFavoriteShow:(id)sender {
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
    }];

    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        self.locDict = nil;
        addFavAddress.text = @"";
        addFavName.text = @"";
        currentFav = typeFavorite;
        [self addSelectFavorite:nil];
        editTitle.text = translateString(@"add_favorite");
        [addSaveButton setHidden:NO];
        [editSaveButton setHidden:YES];
        [editDeleteButton setHidden:YES];
        
        [self animateEditViewShow];
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_not_logged_in") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
    }
    
    
}

- (void)animateEditViewShow {
    CGRect frame = mainMenu.frame;
    frame.origin.x = 0.0f;
    [mainMenu setFrame:frame];
    
    frame.origin.x = 260.0f;
    [addMenu setFrame:frame];
    [addMenu setHidden:NO];
    
    [UIView animateWithDuration:0.4f animations:^{
        CGRect frame = mainMenu.frame;
        frame.origin.x = -260.0f;
        [mainMenu setFrame:frame];
        frame = addMenu.frame;
        frame.origin.x = 0.0f;
        [addMenu setFrame:frame];
    } completion:^(BOOL finished) {
    }];
    
}

- (IBAction)addFavoriteHide:(id)sender{
    [self.view hideKeyboard];
    [self.view removeKeyboardControl];
    [UIView animateWithDuration:0.4f animations:^{
        CGRect frame = mainMenu.frame;
        frame.origin.x = 0.0f;
        [mainMenu setFrame:frame];
        frame = addMenu.frame;
        frame.origin.x = 260.0f;
        [addMenu setFrame:frame];
    } completion:^(BOOL finished) {
        [mainMenu setHidden:NO];
        [addMenu setHidden:YES];
        [self setFavoritesList:[SMFavoritesUtil getFavorites]];
        if ([self.favoritesList count] == 0) {
            [tblMenu setEditing:NO];
        }
        [UIView animateWithDuration:0.4f animations:^{
            [self openMenu:menuFavorites];
        }];
    }];
}

- (IBAction)saveFavorite:(id)sender {
    NSString* name = [addFavName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    for (NSDictionary* fav in self.favoritesList) {
        NSString* favName = [fav objectForKey:@"name"];
        
        
        if ( [favName isEqualToString:name] ) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_favorites_name_exists") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
            return;
        }
    }
        
    if (self.locDict && [self.locDict objectForKey:@"address"] && name.length> 0) {
        if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
            NSString * favType;
            switch (currentFav) {
                case typeFavorite:
                    favType = @"favorite";
                    break;
                case typeHome:
                    favType = @"home";
                    break;
                case typeWork:
                    favType = @"work";
                    break;
                case typeSchool:
                    favType = @"school";
                    break;
                default:
                    favType = @"favorite";
                    break;
            }
            SMFavoritesUtil * fv = [SMFavoritesUtil instance];
            [fv addFavoriteToServer:@{
             @"name" : addFavName.text,
             @"address" : [self.locDict objectForKey:@"address"],
             @"startDate" : [NSDate date],
             @"endDate" : [NSDate date],
             @"source" : @"favorites",
             @"subsource" : favType,
             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude],
             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude],
             @"order" : @0
             }];
            
            [self addFavoriteHide:nil];
            
            
            if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Favorites" withAction:@"New" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude] withValue:0]) {
                debugLog(@"error in trackEvent");
            }
        } else {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_not_logged_in") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
        }
    }
}

- (IBAction)deleteFavorite:(id)sender {
    
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        SMFavoritesUtil * fv = [SMFavoritesUtil instance];
        [fv deleteFavoriteFromServer:@{
         @"id" : [[self.favoritesList objectAtIndex:self.locIndex] objectForKey:@"id"]
         }];
        if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Favorites" withAction:@"Delete" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude] withValue:0]) {
            debugLog(@"error in trackEvent");
        }
        [self addFavoriteHide:nil];
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_not_logged_in") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];

    }
    
    
    }

- (IBAction)editSaveFavorite:(id)sender {
    
    
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        NSString * favType;
        switch (currentFav) {
            case typeFavorite:
                favType = @"favorite";
                break;
            case typeHome:
                favType = @"home";
                break;
            case typeWork:
                favType = @"work";
                break;
            case typeSchool:
                favType = @"school";
                break;
            default:
                favType = @"favorite";
                break;
        }
        
        double currentLat = 0;
        double currentLong = 0;
        
        NSDictionary* item = [self.favoritesList objectAtIndex:self.locIndex];
        currentLat = [[item objectForKey:@"lat"] floatValue];
        currentLong = [[item objectForKey:@"long"] floatValue]; 
        
        NSDictionary * dict = @{
                                @"id" : [[self.favoritesList objectAtIndex:self.locIndex] objectForKey:@"id"],
                                @"name" : addFavName.text,
                                @"address" : [self.locDict objectForKey:@"address"],
                                @"startDate" : [NSDate date],
                                @"endDate" : [NSDate date],
                                @"source" : @"favorites",
                                @"subsource" : favType,
                                @"lat" : [NSNumber numberWithDouble:currentLat], //[NSNumber numberWithDouble:((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude],
                                @"long" : [NSNumber numberWithDouble:currentLong], //[NSNumber numberWithDouble:((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude],
                                @"order" : @0
                                };
        
        debugLog(@"%@", dict);
        
        SMFavoritesUtil * fv = [SMFavoritesUtil instance];
        [fv editFavorite:dict];
        [self addFavoriteHide:nil];
        if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Favorites" withAction:@"Save" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude] withValue:0]) {
            debugLog(@"error in trackEvent");
        }
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_not_logged_in") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
        
    }
}


- (IBAction)findAddress:(id)sender {
    [self.view hideKeyboard];
    self.favName = addFavAddress.text;
    [self performSegueWithIdentifier:@"mainToSearch" sender:nil];
    
}

- (IBAction)addSelectFavorite:(id)sender {
    if ([addFavName.text isEqualToString:translateString(@"Favorite")] || [addFavName.text isEqualToString:translateString(@"Home")] ||
        [addFavName.text isEqualToString:translateString(@"Work")] || [addFavName.text isEqualToString:translateString(@"Schoole")] ||
        [addFavName.text isEqualToString:@""]) {
        [addFavName setText:translateString(@"Favorite")];
    }
    
    
    [addFavFavoriteButton setSelected:YES];
    [addFavHomeButton setSelected:NO];
    [addFavWorkButton setSelected:NO];
    [addFavSchoolButton setSelected:NO];
    currentFav = typeFavorite;
}

- (IBAction)addSelectHome:(id)sender {
    if ([addFavName.text isEqualToString:translateString(@"Favorite")] || [addFavName.text isEqualToString:translateString(@"Home")] ||
        [addFavName.text isEqualToString:translateString(@"Work")] || [addFavName.text isEqualToString:translateString(@"School")] ||
        [addFavName.text isEqualToString:@""]) {
        [addFavName setText:translateString(@"Home")];
    }
    [addFavFavoriteButton setSelected:NO];
    [addFavHomeButton setSelected:YES];
    [addFavWorkButton setSelected:NO];
    [addFavSchoolButton setSelected:NO];
    currentFav = typeHome;
}

- (IBAction)addSelectWork:(id)sender {
    if ([addFavName.text isEqualToString:translateString(@"Favorite")] || [addFavName.text isEqualToString:translateString(@"Home")] ||
        [addFavName.text isEqualToString:translateString(@"Work")] || [addFavName.text isEqualToString:translateString(@"School")] ||
        [addFavName.text isEqualToString:@""]) {
        [addFavName setText:translateString(@"Work")];
    }
    [addFavFavoriteButton setSelected:NO];
    [addFavHomeButton setSelected:NO];
    [addFavWorkButton setSelected:YES];
    [addFavSchoolButton setSelected:NO];
    currentFav = typeWork;
}

- (IBAction)addSelectSchool:(id)sender {
    if ([addFavName.text isEqualToString:translateString(@"Favorite")] || [addFavName.text isEqualToString:translateString(@"Home")] ||
        [addFavName.text isEqualToString:translateString(@"Work")] || [addFavName.text isEqualToString:translateString(@"School")] ||
        [addFavName.text isEqualToString:@""]) {
        [addFavName setText:translateString(@"School")];
    }
    [addFavFavoriteButton setSelected:NO];
    [addFavHomeButton setSelected:NO];
    [addFavWorkButton setSelected:NO];
    [addFavSchoolButton setSelected:YES];
    currentFav = typeSchool;
}

- (IBAction)startEdit:(id)sender {
    [tblMenu setEditing:YES];
    [tblMenu reloadData];
}

- (IBAction)stopEdit:(id)sender {
    [tblMenu setEditing:NO];
    int i = 0;
    NSMutableArray * arr = [NSMutableArray array];
    for (NSDictionary * d in self.favoritesList) {
        [arr addObject:@{
         @"id" : [d objectForKey:@"id"],
         @"position" : [NSString stringWithFormat:@"%d", i]
         }];
        i += 1;
    }
    self.request = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self.request executeRequest:API_SORT_FAVORITES withParams:@{@"auth_token" : [self.appDelegate.appSettings objectForKey:@"auth_token"], @"pos_ary" : arr}];
}

- (void)trackingOn {
    [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
}

- (IBAction)trackUser:(id)sender {
    if (buttonTrackUser.gpsTrackState != SMGPSTrackButtonStateNotFollowing)
        debugLog(@"Warning: trackUser button state was invalid: 0x%0x", buttonTrackUser.gpsTrackState);

    if ([SMLocationManager instance].hasValidLocation) {
        [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
//        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackingOn) object:nil];
//        [self performSelector:@selector(trackingOn) withObject:nil afterDelay:1.0];
        [self.mpView setCenterCoordinate:[SMLocationManager instance].lastValidLocation.coordinate];
    } else {
        [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
    }
}

- (IBAction)showMenu:(id)sender {
    if (currentScreen == screenMenu) {
        [UIView animateWithDuration:0.2f animations:^{
            CGRect frame = centerView.frame;
            frame.origin.x = 0.0f;
            [centerView setFrame:frame];
        } completion:^(BOOL finished) {
            currentScreen = screenMap;
        }];
    } else {
        [UIView animateWithDuration:0.2f animations:^{
            CGRect frame = centerView.frame;
            frame.origin.x = 260.0f;
            [centerView setFrame:frame];
        } completion:^(BOOL finished) {
            currentScreen = screenMenu;
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"enterRouteSegue"]) {
        SMEnterRouteController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
    } else if ([segue.identifier isEqualToString:@"goToNavigationView"]) {
        [self.mpView removeAllAnnotations];
        for (id v in self.mpView.subviews) {
            if ([v isKindOfClass:[SMCalloutView class]]) {
                [v removeFromSuperview];
            }
        }
        
        NSDictionary * params = (NSDictionary*)sender;
        SMRouteNavigationController *destViewController = segue.destinationViewController;
        
        [destViewController setStartLocation:[params objectForKey:@"start"]];
        [destViewController setEndLocation:[params objectForKey:@"end"]];
        [destViewController setDestination:self.destination];
        [destViewController setSource:self.source];
        [destViewController setJsonRoot:self.jsonRoot];
        
        NSDictionary * d = @{
                             @"endLat": [NSNumber numberWithDouble:((CLLocation*)[params objectForKey:@"end"]).coordinate.latitude],
                             @"endLong": [NSNumber numberWithDouble:((CLLocation*)[params objectForKey:@"end"]).coordinate.longitude],
                             @"startLat": [NSNumber numberWithDouble:((CLLocation*)[params objectForKey:@"start"]).coordinate.latitude],
                             @"startLong": [NSNumber numberWithDouble:((CLLocation*)[params objectForKey:@"start"]).coordinate.longitude],
                             @"destination": self.destination,
                             };
        
        NSString * s = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"];
        BOOL x = [d writeToFile:s atomically:NO];
        if (x == NO) {
            NSLog(@"Temp route not saved!");
        }
    } else if ([segue.identifier isEqualToString:@"mainToSearch"]) {
        SMSearchController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
        [destViewController setSearchText:self.favName];
    }
}



- (IBAction)addFakeStation:(id)sender {

    
    if(lastLocation){
        [self addFakeStationWithLocation:lastLocation];
        lastLocation= nil;
    }
    [[SMTransportation instance] save];
}


- (IBAction)toggleReminders:(UIButton *)sender {
    self.reminderFolded = !self.reminderFolded;
    
    if (self.headerReminders.frame.size.height <= 50) {
        self.reminderFolded = YES;
    }
    
    //[sender setSelected:self.reminderFolded];
    
//    NSIndexSet* sections = [NSIndexSet indexSetWithIndex:1];
//    [tblMenu reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
    
    //[self tapFavorites:sender];
    
    CGFloat startY = favHeader.frame.origin.y;
    CGFloat maxHeight = menuView.frame.size.height - 0;//startY;
    if ( self.reminderFolded ) {
        
        [UIView animateWithDuration:0.4f animations:^{
            //[self openMenu:menuReminders];
            
            [self.imgReminders setImage:[UIImage imageNamed:@"reminders_arrow_up"]];
            
            [favEditDone setHidden:YES];
            [favEditStart setHidden:YES];
            CGRect frame = favHeader.frame;
            frame.size.height = 45.0f;
            [favHeader setFrame:frame];
            
//            frame = infHeader.frame;
//            frame.origin.y = maxHeight - 45.0f * 1.0;
//            frame.size.height = 45.0f;
//            [infHeader setFrame:frame];
//            
//            frame = accHeader.frame;
//            frame.origin.y = maxHeight - 2.0*45.0f;
//            frame.size.height = 45.0f;
//            [accHeader setFrame:frame];
            
            frame = self.headerReminders.frame;
            frame.origin.y = favHeader.frame.origin.y + 45.0f;
            frame.size.height = maxHeight - 3 * 45.0f;
            [self.headerReminders setFrame:frame];
            
            float startY = self.headerReminders.frame.origin.y + 6*45; //self.headerReminders.frame.size.height;
            
            frame = favHeader.frame;
            //frame.origin.y = 0; //startY;
            frame.size.height = 45.0f;
            [favHeader setFrame:frame];
            
            frame = accHeader.frame;
            frame.origin.y = startY;
            frame.size.height = 45.0f;
            [accHeader setFrame:frame];
            
            frame = infHeader.frame;
            frame.origin.y = startY + 45.0f;
            frame.size.height = 45.0f;
            [infHeader setFrame:frame];
            
        }];
    } else {
        [UIView animateWithDuration:0.4f animations:^{
             [self.imgReminders setImage:[UIImage imageNamed:@"reminders_arrow_down"]];
            [self openMenu:menuFavorites];
        }];
        
    }
    
//    if ( self.reminderFolded == NO && [self.favoritesList count] > 0 ) {
//        int numItems = [tblMenu numberOfRowsInSection:0];
//        float height = (numItems + 0) * 45.0f + 1.0f;
//        [tblMenu setContentOffset:CGPointMake(0, height) animated:YES];
//    }
}

#pragma mark - tableview delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if (tableView == self.overlaysMenuTable) {
        return 1;
    }
    
    if (tableView == self.tblFavorites) {
        return 1;
    } else {
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (tableView == self.overlaysMenuTable) {
        return [self.overlaysMenuItems count];
    }
    
    if (tableView == self.tblFavorites) {
        return 5;
    }
    
    if (section == 0) {
        if ([self.favoritesList count] > 0) {
            return [self.favoritesList count];
        } else {
            return 1;
        }
        return [self.favoritesList count];
    } else {
        if ( self.reminderFolded ){
            return 0;
        } else {
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == self.overlaysMenuTable) {
        SMRouteTypeSelectCell* cell= [tableView dequeueReusableCellWithIdentifier:@"overlaysMenuCell"];
        NSDictionary* overlaysMenuItem = [self.overlaysMenuItems objectAtIndex:indexPath.row];
        [cell setupCellWithData:overlaysMenuItem];
        
        return cell;
    }
    
    if (tableView == self.tblFavorites) {
        NSArray* weekDays = @[translateString(@"monday"),
                              translateString(@"tuesday"),
                              translateString(@"wednesday"),
                              translateString(@"thursday"),
                              translateString(@"friday")];
        SMReminderTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"reminderTableCell"];
        cell.currentDay= indexPath.row;
        [cell setupWithTitle:[weekDays objectAtIndex:indexPath.row]];

        return cell;
    }
    
    if (tableView == tblMenu) {
        if ([self.favoritesList count] > 0) {
            if (tblMenu.isEditing) {
                NSDictionary * currentRow = [self.favoritesList objectAtIndex:indexPath.row];
                SMMenuCell * cell = [tableView dequeueReusableCellWithIdentifier:@"favoritesCell"];
                [cell.image setContentMode:UIViewContentModeCenter];
                [cell setDelegate:self];
                [cell.image setImage:[UIImage imageNamed:@"favReorder"]];
                [cell.editBtn setHidden:NO];
                [cell.text setText:[currentRow objectForKey:@"name"]];
                return cell;
            } else {
                    NSDictionary * currentRow = [self.favoritesList objectAtIndex:indexPath.row];
                    SMMenuCell * cell = [tableView dequeueReusableCellWithIdentifier:@"favoritesCell"];
                    [cell.image setContentMode:UIViewContentModeCenter];
                    [cell setDelegate:self];
                    [cell setIndentationLevel:2];
                    if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"home"]) {
                        [cell.image setImage:[UIImage imageNamed:@"favHomeGrey"]];
                        [cell.image setHighlightedImage:[UIImage imageNamed:@"favHomeWhite"]];
                    } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"work"]) {
                        [cell.image setImage:[UIImage imageNamed:@"favWorkGrey"]];
                        [cell.image setHighlightedImage:[UIImage imageNamed:@"favWorkWhite"]];
                    } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"school"]) {
                        [cell.image setImage:[UIImage imageNamed:@"favSchoolGrey"]];
                        [cell.image setHighlightedImage:[UIImage imageNamed:@"favSchoolWhite"]];
                    } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"favorite"]) {
                        [cell.image setImage:[UIImage imageNamed:@"favStarGreySmall"]];
                        [cell.image setHighlightedImage:[UIImage imageNamed:@"favStarWhiteSmall"]];
                    } else {
                        [cell.image setImage:nil];
                    }
                    [cell.editBtn setHidden:YES];
                    [cell.text setText:[currentRow objectForKey:@"name"]];
                    return cell;

            }
        } else {
            SMEmptyFavoritesCell * cell = [tableView dequeueReusableCellWithIdentifier:@"favoritesEmptyCell"];
            [cell.text setText:translateString(@"cell_add_favorite")];
            if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
                [cell.addFavoritesText setText:translateString(@"cell_empty_favorite_text")];
                [cell.text setTextColor:[UIColor colorWithRed:245.0f/255.0f green:130.0f/255.0f blue:32.0f/255.0f alpha:1.0f]];
                [cell.addFavoritesSymbol setImage:[UIImage imageNamed:@"favAdd"]];
            } else {
                [cell.addFavoritesText setText:translateString(@"favorites_login")];
                [cell.addFavoritesText setTextColor:[UIColor colorWithRed:77.0f/255.0f green:77.0f/255.0f blue:77.0f/255.0f alpha:1.0f]];
                [cell.text setTextColor:[UIColor colorWithRed:77.0f/255.0f green:77.0f/255.0f blue:77.0f/255.0f alpha:1.0f]];
                [cell.addFavoritesSymbol setImage:[UIImage imageNamed:@"fav_plus_none_grey"]];
            }
            
            [cell.contentView setBackgroundColor:[UIColor colorWithRed:244/255.0 green:244/255.0 blue:244/255.0 alpha:1.0]];
            return cell;
        }
    }
    UITableViewCell * cell;
    return cell;
}


-(void) overlaysMenuItemSelected:(int)row selected:(BOOL)pSelected{
    if (row == 0){
        [self.appDelegate.mapOverlays toggleMarkers:@"path" state:pSelected];
    } else if ( row == 1 ) {
        [self.appDelegate.mapOverlays toggleMarkers:@"service" state:pSelected];
    } else if ( row == 2 ) {
        [self.appDelegate.mapOverlays toggleMarkers:@"station" state:pSelected];
    } else if ( row == 3 ) {
        [self.appDelegate.mapOverlays toggleMarkers:@"metro" state:pSelected];
    } else if ( row == 4 ) {
        [self.appDelegate.mapOverlays toggleMarkers:@"local-trains" state:pSelected];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if( tableView == self.overlaysMenuTable ){
        [self overlaysMenuItemSelected:indexPath.row selected:NO];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if( tableView == self.overlaysMenuTable ){
        [self overlaysMenuItemSelected:indexPath.row selected:YES];
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (tableView == tblMenu && indexPath.section == 0) {
        if ([self.favoritesList count] == 0) {
            if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
                /**
                 * add favorite
                 */
                [self addFavoriteShow:nil];
            }
        } else {
            if (tblMenu.isEditing) {
                /**
                 * edit favorite
                 */
                self.locDict = [self.favoritesList objectAtIndex:indexPath.row];
                self.locIndex = indexPath.row;
                [self editFavoriteShow:nil];
            } else {
                /**
                 * navigate to favorite
                 */
                if (indexPath.row < [self.favoritesList count]) {
                    NSDictionary * currentRow = [self.favoritesList objectAtIndex:indexPath.row];
                    
                    [self.view bringSubviewToFront:fadeView];
                    [UIView animateWithDuration:0.4f animations:^{
                        [fadeView setAlpha:1.0f];
                    }];
                    
                    CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:[[currentRow objectForKey:@"lat"] floatValue] longitude:[[currentRow objectForKey:@"long"] floatValue]];
                    CLLocation * cStart = [[CLLocation alloc] initWithLatitude:[SMLocationManager instance].lastValidLocation.coordinate.latitude longitude:[SMLocationManager instance].lastValidLocation.coordinate.longitude];
                    
                    if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Route" withAction:@"Menu" withLabel:@"Favorites" withValue:0]) {
                        debugLog(@"error in trackEvent");
                    }
                    
                    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
                    [r setRequestIdentifier:@"rowSelectRoute"];
                    [r setAuxParam:[currentRow objectForKey:@"name"]];
                    [r findNearestPointForStart:cStart andEnd:cEnd];
                } else {
                    /**
                     * add favorite
                     */
                    [self addFavoriteShow:nil];
                }
            }
        }
    }
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(tableView==self.overlaysMenuTable) {
        return [SMRouteTypeSelectCell getHeight];
    }
    
    if (tableView == tblMenu) {
        if ([self.favoritesList count] == 0) {
            if ( indexPath.section == 0 ) {
                return [SMEmptyFavoritesCell getHeight];
            } else if ( indexPath.section == 1) {
                return 45.0f;
            }
        } else {
            return [SMMenuCell getHeight];
        }
    }
    return 45.0f;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (tableView == tblMenu) {
        if ([self.favoritesList count] == 0) {
            return;
        }
        NSDictionary * src = [self.favoritesList objectAtIndex:sourceIndexPath.row];
        [self.favoritesList removeObjectAtIndex:sourceIndexPath.row];
        [self.favoritesList insertObject:src atIndex:destinationIndexPath.row];
        [SMFavoritesUtil saveFavorites:self.favoritesList];
    }
    
    [tableView reloadData];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	//	Grip customization code goes in here...
	for(UIView* view in cell.subviews) {
		if([[[view class] description] isEqualToString:@"UITableViewCellReorderControl"]) {
			UIView* resizedGripView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetMaxX(view.frame), CGRectGetMaxY(view.frame))];
			[resizedGripView addSubview:view];
			[cell addSubview:resizedGripView];
            
			CGSize sizeDifference = CGSizeMake(resizedGripView.frame.size.width - view.frame.size.width, resizedGripView.frame.size.height - view.frame.size.height);
			CGSize transformRatio = CGSizeMake(resizedGripView.frame.size.width / view.frame.size.width, resizedGripView.frame.size.height / view.frame.size.height);
            
			//	Original transform
			CGAffineTransform transform = CGAffineTransformIdentity;
            
			//	Scale custom view so grip will fill entire cell
			transform = CGAffineTransformScale(transform, transformRatio.width, transformRatio.height);
            
			//	Move custom view so the grip's top left aligns with the cell's top left
			transform = CGAffineTransformTranslate(transform, -sizeDifference.width / 2.0, -sizeDifference.height / 2.0);
            
			[resizedGripView setTransform:transform];
            
			for(UIImageView* cellGrip in view.subviews)
			{
				if([cellGrip isKindOfClass:[UIImageView class]])
					[cellGrip setImage:nil];
			}
		}
	}
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (tableView == tblMenu && section == 0) {
        if (tableView.isEditing) {
            return [[UIView alloc] initWithFrame:CGRectZero];
        } else {
            if ([self.favoritesList count] > 0) {
                return self.tableFooter;
            } else {
                return [[UIView alloc] initWithFrame:CGRectZero];
            }
        }
    } else {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ( section == 0 ) {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    } else {
//        UITableViewCell* header = [tableView dequeueReusableCellWithIdentifier:@"reminderHeader"];
//        return header;
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == tblMenu) {
        if (section == 0) {
            return 0;
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (tableView == tblMenu && section == 0) {
        if (tableView.isEditing) {
            return 0.0f;
        } else {
            if ([self.favoritesList count] > 0) {
                return [SMAddFavoriteCell getHeight];
            } else {
                return 0.0f;
            }
        }
    } else {
        return 0.0f;
    }
}

#pragma mark - route finder delegate
- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString *)src toAddress:(NSString *)dst{
    [self findRouteFrom:from to:to fromAddress:src toAddress:dst withJSON:nil];
}

- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString *)src toAddress:(NSString *)dst withJSON:(id)jsonRoot{
    CLLocation * start = [[CLLocation alloc] initWithLatitude:from.latitude longitude:from.longitude];
    CLLocation * end = [[CLLocation alloc] initWithLatitude:to.latitude longitude:to.longitude];    
    self.destination = dst;
    self.source = src;
    self.jsonRoot = jsonRoot;
    if (self.navigationController.topViewController == self) {
        [self performSegueWithIdentifier:@"goToNavigationView" sender:@{@"start" : start, @"end" : end}];
    }
}

#pragma mark - gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

#pragma mark - mapView delegate

- (void)afterMapMove:(RMMapView *)map byUser:(BOOL)wasUserAction {
    [self checkCallouts];
}

- (void)checkCallouts {
    for (SMAnnotation * annotation in self.mpView.annotations) {
        if ([annotation.annotationType isEqualToString:@"marker"] && [annotation isKindOfClass:[SMAnnotation class]]) {
            if (annotation.calloutShown) {
                [annotation showCallout];
            }
        }
    }
}

- (void)mapViewRegionDidChange:(RMMapView *)mapView {
    [self checkCallouts];
}

- (RMMapLayer *)mapView:(RMMapView *)aMapView layerForAnnotation:(SMAnnotation *)annotation {
    if ([annotation.annotationType isEqualToString:@"marker"] || [annotation.annotationType isEqualToString:@"station"]) {
        RMMarker * m = [[RMMarker alloc] initWithUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint];

        return m;
    }
    return nil;
}

- (void)afterMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction {
    [self checkCallouts];
}

- (void)mapView:(RMMapView *)mapView didUpdateUserLocation:(RMUserLocation *)userLocation {
    [self checkCallouts];
}

- (void)tapOnAnnotation:(SMAnnotation *)annotation onMap:(RMMapView *)map {
//    if ([annotation.annotationType isEqualToString:@"marker"]) {
        for (id v in self.mpView.subviews) {
            if ([v isKindOfClass:[SMCalloutView class]]) {
                [v removeFromSuperview];
            }
        }
        [self.mpView removeAnnotation:self.endMarkerAnnotation];
//        [self hidePinDrop];
//    }
    
    if([annotation.annotationType.lowercaseString isEqualToString:@"station"]){
        SMStationInfo* station= [annotation.userInfo objectForKey:@"station"];
        if(station){
            [self showPinDrop];
            [self displayDestinationNameWithString:station.name];
            [self setDestinationAnnotation:annotation withLocation:station.location];
            
            RMMapLayer* layer= [self mapView:map layerForAnnotation:annotation];

//            layer.frame= CGRectMake(layer.frame.origin.x-layer.frame.size.width/4, layer.frame.origin.y-layer.frame.size.height/4, 1.5*layer.frame.size.width, 1.5*layer.frame.size.height);
//            [layer setNeedsDisplay];
        }
    }

    
}

#pragma mark - SMAnnotation delegate methods

- (void)annotationActivated:(SMAnnotation *)annotation {
    
    self.findFrom = @"";
    self.findTo = [NSString stringWithFormat:@"%@, %@", annotation.title, annotation.subtitle];
    self.findMatches = annotation.nearbyObjects;
    
    [self.view bringSubviewToFront:fadeView];
    [UIView animateWithDuration:0.4f animations:^{
        [fadeView setAlpha:1.0f];
    }];
    
    cEnd = [[CLLocation alloc] initWithLatitude:annotation.routingCoordinate.coordinate.latitude longitude:annotation.routingCoordinate.coordinate.longitude];
    cStart = [[CLLocation alloc] initWithLatitude:[SMLocationManager instance].lastValidLocation.coordinate.latitude longitude:[SMLocationManager instance].lastValidLocation.coordinate.longitude];
    /**
     * remove this if we need to find the closest point
     */
    NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)", @"", cStart.coordinate.latitude, cStart.coordinate.longitude, @"", cEnd.coordinate.latitude, cEnd.coordinate.longitude];
    debugLog(@"%@", st);
    if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Route:" withAction:@"Pin" withLabel:st withValue:0]) {
        debugLog(@"error in trackPageview");
    }
    self.startName = CURRENT_POSITION_STRING;
    SMStationInfo* station= [annotation.userInfo objectForKey:@"station"];
    if(station){
        self.endName= station.name;
    }else{
        self.endName = annotation.title;
    }

    self.startLoc = cStart.coordinate;
    self.endLoc = cEnd.coordinate;
    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
    [r setAuxParam:@"startRoute"];
    [r getRouteFrom:cStart.coordinate to:cEnd.coordinate via:nil];
    /**
     * end routing
     */
}


#pragma mark - nearby places delegate

- (void) nearbyPlaces:(SMNearbyPlaces *)owner foundLocations:(NSArray *)locations {
    [routeStreet setText:owner.title];
    if ([routeStreet.text isEqualToString:@""]) {
        [routeStreet setText:[NSString stringWithFormat:@"%f, %f", owner.coord.coordinate.latitude, owner.coord.coordinate.longitude]];
    }
    
    NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF.name = %@ AND SELF.address = %@", routeStreet.text, routeStreet.text];
    NSArray * arr = [[SMFavoritesUtil getFavorites] filteredArrayUsingPredicate:pred];
    if ([arr count] > 0) {
        [pinButton setSelected:YES];
    } else {
        [pinButton setSelected:NO];
    }
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"] && [[self.appDelegate.appSettings objectForKey:@"auth_token"] isEqualToString:@""] == NO) {
        pinButton.enabled = YES;
    }
    
    [self showPinDrop];
}

#pragma mark - osrm request delegate
- (void)request:(SMRequestOSRM *)req finishedWithResult:(id)res {
    if ([req.requestIdentifier isEqualToString:@"getNearestForPinDrop"]) {
        NSDictionary * r = res;
        CLLocation * coord;
        if ([r objectForKey:@"mapped_coordinate"] && [[r objectForKey:@"mapped_coordinate"] isKindOfClass:[NSArray class]] && ([[r objectForKey:@"mapped_coordinate"] count] > 1)) {
            coord = [[CLLocation alloc] initWithLatitude:[[[r objectForKey:@"mapped_coordinate"] objectAtIndex:0] doubleValue] longitude:[[[r objectForKey:@"mapped_coordinate"] objectAtIndex:1] doubleValue]];
        } else {
            coord = req.coord;
        }
        SMNearbyPlaces * np = [[SMNearbyPlaces alloc] initWithDelegate:self];
        [np findPlacesForLocation:[[CLLocation alloc] initWithLatitude:coord.coordinate.latitude longitude:coord.coordinate.longitude]];
    } else if ([req.requestIdentifier isEqualToString:@"rowSelectRoute"]) {
        CLLocation * s = [res objectForKey:@"start"];
        CLLocation * e = [res objectForKey:@"end"];
        
        NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)", @"", s.coordinate.latitude, s.coordinate.longitude, @"", e.coordinate.latitude, e.coordinate.longitude];
        debugLog(@"%@", st);
        if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Route:" withAction:@"Pin" withLabel:st withValue:0]) {
            debugLog(@"error in trackPageview");
        }
        
        self.startName = CURRENT_POSITION_STRING;
        self.endName = req.auxParam;
        self.startLoc = s.coordinate;
        self.endLoc = e.coordinate;
        
        SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
        [r setAuxParam:@"startRoute"];
        [r getRouteFrom:s.coordinate to:e.coordinate via:nil];
    } else if ([req.auxParam isEqualToString:@"startRoute"]){
        id jsonRoot = [NSJSONSerialization JSONObjectWithData:req.responseData options:NSJSONReadingAllowFragments error:nil];
        if (!jsonRoot || ([jsonRoot isKindOfClass:[NSDictionary class]] == NO) || ([[jsonRoot objectForKey:@"status"] intValue] != 0)) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_route_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
        } else {
            [self findRouteFrom:self.startLoc to:self.endLoc fromAddress:self.startName toAddress:self.endName withJSON:jsonRoot];
            NSDictionary* dict= jsonRoot;
            
            NSDictionary* routeDict= [dict objectForKey:@"route_summary"];
            NSString* name= [routeDict objectForKey:@"end_point"];
            NSString* address= [routeDict objectForKey:@"end_point"];
            
            address = self.endName;
            name = self.endName;
            
            [SMGeocoder reverseGeocode:self.endLoc completionHandler:^(NSDictionary *response, NSError *error) {
                NSString* streetName = [response objectForKey:@"title"];
                
                NSString* new_address = streetName;
                NSString* new_name = streetName; //[NSString stringWithFormat:@"%@, %@", streetName, [response objectForKey:@"subtitle"] ];
                
                if ([streetName isEqualToString:self.endName]) {
                    new_name = streetName;
                    new_address = streetName;
                } else {
                    new_name = self.endName;
                    new_address = streetName;
                }
                
                if ([new_name isEqualToString:@""]) {
                    new_name = [NSString stringWithFormat:@"%f, %f", self.endLoc.latitude, self.endLoc.longitude];
                }
                
                NSDictionary * d = @{
                                     @"name" : new_name,
                                     @"address" : new_address,
                                     @"startDate" : [NSDate date],
                                     @"endDate" : [NSDate date],
                                     @"source" : @"searchHistory",
                                     @"subsource" : @"",
                                     @"lat" : [NSNumber numberWithDouble:cEnd.coordinate.latitude],
                                     @"long" : [NSNumber numberWithDouble:cEnd.coordinate.longitude],
                                     @"order" : @1
                                     };
                [SMSearchHistory saveToSearchHistory:d];
                
                [self dismissViewControllerAnimated:YES completion:^{
                    
                }];
                
            }];
            
        }
        [UIView animateWithDuration:0.4f animations:^{
            [fadeView setAlpha:0.0f];
        }];
    }
}
-(void)setEndName:(NSString *)pEndName{
    _endName= pEndName;
}

- (void)request:(SMRequestOSRM *)req failedWithError:(NSError *)error {
    [fadeView setAlpha:1.0];
    [UIView animateWithDuration:0.4f animations:^{
        [fadeView setAlpha:0.0f];
    }];
}

#pragma mark - observers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.mpView && [keyPath isEqualToString:@"userTrackingMode"]) {
        if (self.mpView.userTrackingMode == RMUserTrackingModeFollow) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateFollowing];
        } else if (self.mpView.userTrackingMode == RMUserTrackingModeFollowWithHeading) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateFollowingWithHeading];
        } else if (self.mpView.userTrackingMode == RMUserTrackingModeNone) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateNotFollowing];
        }
    } else if (object == tblMenu && [keyPath isEqualToString:@"editing"]) {
        if (tblMenu.editing) {
            [favEditDone setHidden:NO];
            [favEditStart setHidden:YES];
        } else {
            [favEditDone setHidden:YES];
            [favEditStart setHidden:NO];
        }
        [UIView animateWithDuration:0.4f animations:^{
            [self openMenu:menuFavorites];
        }];
    } else if (object == centerView  && [keyPath isEqualToString:@"frame"]) {
        if (centerView.frame.origin.x == 260.0f) {
            blockingView.alpha = 1.0f;
        } else if (centerView.frame.origin.x == 0.0f) {
            blockingView.alpha = 0.0f;            
            /**
             * close edit/save/delete menu if open
             */
            [self.view hideKeyboard];
            CGRect frame = mainMenu.frame;
            frame.origin.x = 0.0f;
            [mainMenu setFrame:frame];
            frame = addMenu.frame;
            frame.origin.x = 260.0f;
            [addMenu setFrame:frame];
            [mainMenu setHidden:NO];
            [addMenu setHidden:YES];
            [self setFavoritesList:[SMFavoritesUtil getFavorites]];
            if ([self.favoritesList count] == 0) {
                [tblMenu setEditing:NO];
            }
            [UIView animateWithDuration:0.4f animations:^{
                [self openMenu:menuFavorites];
            }];
        }
        
    }
}

#pragma mark - menu header delegate

- (void)editFavorite:(SMMenuCell *)cell {
    NSInteger ind = [tblMenu indexPathForCell:cell].row;
    debugLog(@"%d", ind);
}

#pragma mark - search delegate

- (void)locationFound:(NSDictionary *)locationDict {
    [self setLocDict:locationDict];
    [addFavAddress setText:[locationDict objectForKey:@"address"]];
    if ([locationDict objectForKey:@"subsource"] && [[locationDict objectForKey:@"subsource"] isEqualToString:@"foursquare"]) {
        [addFavName setText:[locationDict objectForKey:@"name"]];
    } else {
        switch (currentFav) {
            case typeFavorite:
                [addFavName setText:translateString(@"Favorite")];
                break;
            case typeHome:
                [addFavName setText:translateString(@"Home")];
                break;
            case typeWork:
                [addFavName setText:translateString(@"Work")];
                break;
            case typeSchool:
                [addFavName setText:translateString(@"School")];
                break;
            default:
                [addFavName setText:translateString(@"Favorite")];
                break;
        }
    }
}

#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Add cell delegate

- (void)viewTapped:(id)view {
    [self addFavoriteShow:nil];
}

#pragma mark - custom methods

- (void)inputKeyboardWillHide:(NSNotification *)notification {
    CGRect frame = addMenu.frame;
    frame.size.height = menuView.frame.size.height;
    [addMenu setFrame:frame];
}

#pragma mark - notifications

- (void)favoritesChanged:(NSNotification*) notification {
    self.favoritesList = [SMFavoritesUtil getFavorites];
    [self openMenu:menuFavorites];
    
}

#pragma mark - smfavorites delegate

- (void)favoritesOperationFinishedSuccessfully:(id)req withData:(id)data {
    
}

#pragma mark - api request delegate

- (void)request:(SMAPIRequest *)req completedWithResult:(NSDictionary *)result {
    
}

- (void)serverNotReachable {
    SMNetworkErrorView * v = [SMNetworkErrorView getFromNib];
    CGRect frame = v.frame;
    frame.origin.x = roundf((self.view.frame.size.width - v.frame.size.width) / 2.0f);
    frame.origin.y = roundf((self.view.frame.size.height - v.frame.size.height) / 2.0f);
    [v setFrame: frame];
    [v setAlpha:0.0f];
    [self.view addSubview:v];
    [UIView animateWithDuration:ERROR_FADE animations:^{
        v.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:ERROR_FADE delay:ERROR_WAIT options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            v.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [v removeFromSuperview];
        }];
    }];
}

@end

