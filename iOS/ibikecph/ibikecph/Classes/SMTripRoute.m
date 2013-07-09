//
//  SMTripRoute.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTripRoute.h"
#import "SMTransportationRoute.h"
#import "SMTransportation.h"
#import "SMTransportationLine.h"
#import "SMRouteStationInfo.h"
#import "SMRouteTransportationInfo.h"
#import "SMBrokenRouteInfo.h"
#import "SMSingleRouteInfo.h"

@implementation SMTripRoute{
    NSBlockOperation* searchingOperation;
    NSMutableArray* internalRoutes;
}

-(id) initWithRoute:(SMRoute*)route{
    self = [super init];
    
    if(self){
        self.fullRoute= route;
        self.brokenRoutes= @[route];
    }

    return self;
}



-(BOOL) breakRoute{
    if(!self.fullRoute)
        return NO;
    
//    if(self.state == RS_SEARCHING_FOR_ROUTE){
//        [searchingOperation cancel];
//        searchingOperation= nil;
//    }
    
    __weak SMTripRoute* selfRef= self;

    
    searchingOperation= [NSBlockOperation blockOperationWithBlock:^{
        [selfRef breakRouteInBackground];
    }];
    
    searchingOperation.completionBlock= ^{
        //todo Change state
        if([selfRef.delegate respondsToSelector:@selector(didCalculateRouteDistances:)])
            [selfRef.delegate didCalculateRouteDistances:selfRef ];
    };
    
    if([self.delegate respondsToSelector:@selector(didStartBreakingRoute:)])
        [self.delegate didStartBreakingRoute:self];
    
    [[SMTransportation transportationQueue] addOperation:searchingOperation];
    
    return YES;
}

-(void)breakRouteInBackground{
    CLLocation* start= [self start];
    CLLocation* end= [self end];
    NSMutableArray* transportationRoutesTemp= [NSMutableArray new];
    double routeDistance= [start distanceFromLocation:end];
    
    NSArray* lines= [SMTransportation instance].lines;
    
    for( SMTransportationLine* transportationLine in lines){

        for(int i=0; i<transportationLine.stations.count; i++){
            SMRouteStationInfo* stationLocation= [transportationLine.stations objectAtIndex:i];
            
            for(int j=0; j<transportationLine.stations.count; j++){
                if(i==j)
                    continue;
                
                SMRouteStationInfo* stationLocationDest= [transportationLine.stations objectAtIndex:j];
                float bikeDistanceToSourceStation= [start distanceFromLocation:stationLocation.location];
                float bikeDistanceFromDestinationStation= [end distanceFromLocation:stationLocationDest.location];
                float bikeDistance= bikeDistanceToSourceStation + bikeDistanceFromDestinationStation;
                
                if(bikeDistance> routeDistance)
                    continue;
                
                SMSingleRouteInfo* singleRouteInfo= [[SMSingleRouteInfo alloc] init];//WithStart:stationLocation.location end:stationLocationDest.location transportationLine:transportationLine bikeDistance:bikeDistance];
                singleRouteInfo.sourceStation= stationLocation;
                singleRouteInfo.destStation= stationLocationDest;

                singleRouteInfo.transportationLine= transportationLine;
                singleRouteInfo.bikeDistance= bikeDistance;
                singleRouteInfo.distance1= bikeDistanceToSourceStation;
                singleRouteInfo.distance2= bikeDistanceFromDestinationStation;
                [transportationRoutesTemp addObject:singleRouteInfo];
                }
        }
        
    }

    self.transportationRoutes= [transportationRoutesTemp sortedArrayUsingComparator:^NSComparisonResult(SMSingleRouteInfo* r1, SMSingleRouteInfo* r2){
        if(r1.bikeDistance < r2.bikeDistance)
            return NSOrderedAscending;
        else
            return NSOrderedDescending;
    }];
    
    
}

-(NSArray*)sortedEndStationsForTransportationLine:(SMTransportationLine*)pTransportationLine{
    NSArray* endDistances= [pTransportationLine.stations sortedArrayUsingComparator:^NSComparisonResult(SMRouteStationInfo* s1, SMRouteStationInfo* s2){
        if( [s1.location distanceFromLocation:[self end]] < [s2.location distanceFromLocation:[self end]])
            return NSOrderedAscending;
        else
            return NSOrderedDescending;
    }];
    
    return endDistances;
}

-(float)bikeDistanceForStart:(CLLocation*)start end:(CLLocation*)end sourceStationLocation:(CLLocation*)source desination:(CLLocation*)destination{
    
    return [start distanceFromLocation:source] + [end distanceFromLocation:destination];
}
#pragma mark child notifications


-(CLLocation *)start{
    return [self.fullRoute getStartLocation];
}

-(CLLocation *)end{
    return [self.fullRoute getEndLocation];
}

#pragma mark - getters&setters

-(void)setBrokenRouteInfo:(SMBrokenRouteInfo *)pBrokenRouteInfo{
    _brokenRouteInfo= pBrokenRouteInfo;
    
    [self performSelectorOnMainThread:@selector(createSplitRoutes) withObject:nil waitUntilDone:NO];
//    [self createSplitRoutes];
}

-(void)createSplitRoutes{
    if(!self.brokenRouteInfo)
        self.brokenRoutes= nil;
    
    SMRoute* startRoute= [[SMRoute alloc] initWithRouteStart:[self start].coordinate andEnd:self.brokenRouteInfo.sourceStation.location.coordinate andDelegate:self];
    SMRoute* endRoute= [[SMRoute alloc] initWithRouteStart:self.brokenRouteInfo.destinationStation.location.coordinate andEnd:[self end].coordinate andDelegate:self];
    
    self.brokenRoutes= @[startRoute, endRoute];
//            CLLocation* loc= [[CLLocation alloc] initWithLatitude:55.663117 longitude:12.542664];
//    SMRoute* startRoute= [[SMRoute alloc] initWithRouteStart:[self start].coordinate andEnd:CLLocationCoordinate2DMake(55.672820, 12.571004) andDelegate:self];
//    SMRoute* endRoute= [[SMRoute alloc] initWithRouteStart:CLLocationCoordinate2DMake(55.668344, 12.564604) andEnd:loc.coordinate andDelegate:self];
//    
//    self.brokenRoutes= @[startRoute, endRoute];
}

- (void) updateTurn:(BOOL)firstElementRemoved{
    
}
- (void) reachedDestination{
    
}
- (void) updateRoute{
    
}
- (void) startRoute{
    NSLog(@"waypoint count ");
    
    for(SMRoute* route in self.brokenRoutes){
        if(!route.waypoints)
            return;
    }
    
    if([self.delegate respondsToSelector:@selector(didFinishBreakingRoute:)])
        [self.delegate didFinishBreakingRoute:self ];

    
    
}
- (void) routeNotFound{
    
}
- (void) serverError{
    NSLog(@"Server error");
}

@end

