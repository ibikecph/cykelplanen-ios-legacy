//
//  SMMapOverlays.m
//  I Bike CPH
//
//  Created by Igor Jerković on 7/29/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMMapOverlays.h"
#import "SMStationInfo.h"
#import "SMAnnotation.h"
#import "SMTransportation.h"
#import "SMTransportationLine.h"

@interface SMMapOverlays()
@property (nonatomic, weak) RMMapView* mpView;
@property (nonatomic, strong) NSString* source;
@property (nonatomic, strong) NSMutableArray* metroMarkers;
@property (nonatomic, strong) NSMutableArray* serviceMarkers;
@property (nonatomic, strong) NSMutableArray* stationMarkers;
@end

@implementation SMMapOverlays
-(SMMapOverlays*)initWithMapView:(RMMapView*)mapView {
    self = [super init];
    if(self) {
        self.mpView = mapView;
        
        self.pathVisible = YES;
        self.serviceMarkersVisible = NO;
        self.stationMarkersVisible = NO;
        self.metroMarkersVisible = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loadMarkers)
                                                     name:NOTIFICATION_STATIONS_FETCHED
                                                   object:nil];
    }
    return self;
}

- (void)useMapView:(RMMapView*)mapView {
    self.mpView = mapView;
}

- (void)loadMarkers {
    
//    if ( !self.mpView ) {
//        return;
//    }
    
    self.stationMarkers = [[NSMutableArray alloc] init];
    NSArray* lines= [SMTransportation instance].lines;
    
    for( SMTransportationLine* transportationLine in lines){
        
        for(int i=0; i<transportationLine.stations.count; i++){
            SMStationInfo* stationLocation= [transportationLine.stations objectAtIndex:i];
            //[stationLocation fetchName];
            NSLog(@"Station %@",stationLocation.name);
            CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(stationLocation.latitude, stationLocation.longitude);
            //[self addMarkerToMapView:self.mpView withCoordinate:coord title:@"Marker" imageName:@"station_icon" annotationTitle:@"Marker text" alternateTitle:@"Marker alternate title"];
            
            NSString* imageName = @"station_icon";
            NSString* title = @"station";
            NSString* annotationTitle = @"Station";
            NSString* alternateTitle = @"alternate title";
            
            SMAnnotation *annotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:coord andTitle:title];
            annotation.annotationType = @"marker";
            annotation.annotationIcon = [UIImage imageNamed:imageName];
            annotation.anchorPoint = CGPointMake(0.5, 1.0);
            NSMutableArray* arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
            annotation.title = annotationTitle;
            
            if ([annotation.title isEqualToString:@""] && alternateTitle) {
                annotation.title = alternateTitle;
            }
            
//            annotation.userInfo= @{keyZIndex: [NSNumber numberWithInt:MAP_LEVEL_STATIONS]};
            
            annotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            //[self.mpView addAnnotation:annotation];
            
            [self.stationMarkers addObject:annotation];
            
        }
    }
      
    // Add metro markers
    self.metroMarkers = [[NSMutableArray alloc] init];
    for (int i=0; i<150*3; i++) {
        float jitterx = (rand() % 1000 / 1000.0 * 0.5) - 0.25;
        float jittery = (rand() % 1000 / 1000.0 * 0.5) - 0.25;
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(55.678974+jitterx, 12.540156+jittery);
        //[self addMarkerToMapView:self.mpView withCoordinate:coord title:@"Marker" imageName:@"station_icon" annotationTitle:@"Marker text" alternateTitle:@"Marker alternate title"];
        
        NSString* imageName = @"metro_logo_pin";
        NSString* title = @"metro";
        NSString* annotationTitle = @"title";
        NSString* alternateTitle = @"alternate title";
        
        SMAnnotation *annotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:coord andTitle:title];
        
        annotation.annotationType = @"marker";
        annotation.annotationIcon = [UIImage imageNamed:imageName];
        annotation.anchorPoint = CGPointMake(0.5, 1.0);
        NSMutableArray * arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
        annotation.title = annotationTitle;
        
        if ([annotation.title isEqualToString:@""] && alternateTitle) {
            annotation.title = alternateTitle;
        }
        
        annotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //[self.mpView addAnnotation:annotation];
        
        [self.metroMarkers addObject:annotation];
    }
    
    // Add service markers
    self.serviceMarkers = [[NSMutableArray alloc] init];
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"service_stations" ofType:@"json"];
    NSError* err;
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary* dict = nil;
    if ( data ) {
        dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        NSLog(@"Error %@", err);
    }
    NSArray* stations = [dict valueForKey:@"stations"];
    NSNumber* lon;
    NSNumber* lat;
    
    for(NSDictionary* station in stations){
        
        NSString* stationName = [station objectForKey:@"name"];
        NSDictionary* coords = [station objectForKey:@"point"];
        
        lon = [coords objectForKey:@"long"];
        lat = [coords objectForKey:@"lat"];
        SMStationInfo* stationInfo= [[SMStationInfo alloc] initWithLongitude:lon.doubleValue latitude:lat.doubleValue andName:stationName];
        
        //[self.serviceMarkers addObject:stationInfo];
        
        NSLog(@"SERVICE STATION: %f %f %@", stationInfo.longitude, stationInfo.latitude, stationInfo.name);
        
        NSString* imageName = @"service_pin";
        NSString* title = @"service";
        NSString* annotationTitle = stationName;
        NSString* alternateTitle = stationName;
        
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(lon.floatValue, lat.floatValue);
        SMAnnotation *annotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:coord andTitle:title];
        annotation.annotationType = @"marker";
        annotation.annotationIcon = [UIImage imageNamed:imageName];
        annotation.anchorPoint = CGPointMake(0.5, 1.0);
        
        NSMutableArray * arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
        annotation.title = annotationTitle;
        
        if ([annotation.title isEqualToString:@""] && alternateTitle) {
            annotation.title = alternateTitle;
        }
        
        annotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //[self.mpView addAnnotation:annotation];
        [self.serviceMarkers addObject:annotation];
    }
    
    [self toggleMarkers];
}

-(void)toggleMarkers{
    if ( self.metroMarkersVisible ) {
        [self.mpView addAnnotations:self.metroMarkers];
    } else {
        [self.mpView removeAnnotations:self.metroMarkers];
    }
    
    if ( self.serviceMarkersVisible ) {
        [self.mpView addAnnotations:self.serviceMarkers];
    } else {
        [self.mpView removeAnnotations:self.serviceMarkers];
    }
    
    if ( self.stationMarkersVisible ) {
        [self.mpView addAnnotations:self.stationMarkers];
    } else {
        [self.mpView removeAnnotations:self.stationMarkers];
    }
    
    if ( self.pathVisible ) {
        //        [self showRouteAnnotation];
    } else {
        //        [self hideRouteAnnotation];
    }
}

- (void)toggleMarkers:(NSString*)markerType state:(BOOL)state {
    if ( [markerType isEqualToString:@"metro"] ) {
        self.metroMarkersVisible = state;
        
    } else if ( [markerType isEqualToString:@"service"] ) {
        self.serviceMarkersVisible = state;
        
    } else if ( [markerType isEqualToString:@"station"] ) {
        self.stationMarkersVisible = state;
        
    }else if([markerType isEqualToString:@"path"]){
        self.pathVisible= state;
        
    }
    
    [self toggleMarkers];
    NSLog(@"Toggle markers: %@ %d", markerType, state);
}


@end
