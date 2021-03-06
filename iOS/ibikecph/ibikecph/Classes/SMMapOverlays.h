//
//  SMMapOverlays.h
//  I Bike CPH
//
//  Created by Igor Jerković on 7/29/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMMapView.h"

@interface SMMapOverlays : NSObject

-(SMMapOverlays*)initWithMapView:(RMMapView*)mapView;
- (void)useMapView:(RMMapView*)mapView;
- (void)loadMarkers;
- (void)toggleMarkers:(NSString*)markerType state:(BOOL)state;
- (void)toggleMarkers;

@property BOOL metroMarkersVisible;
@property BOOL serviceMarkersVisible;
@property BOOL stationMarkersVisible;
@property BOOL localTrainMarkersVisible;
@property BOOL pathVisible;
@property (nonatomic, strong) NSMutableArray* metroTimingConst;

@end
