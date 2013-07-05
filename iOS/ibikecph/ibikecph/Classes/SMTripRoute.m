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
@implementation SMTripRoute{
    NSBlockOperation* searchingOperation;
    NSMutableArray* internalRoutes;
}

@synthesize routes= _routes;

-(BOOL)isIsValid{
    return (self.routes && self.routes.count > 0);
}

-(id) initWithRoute:(SMRoute*)route{
    self = [super init];
    
    if(self){
        self.fullRoute= route;
    }

    return self;
}

-(NSArray *)routes{
    return internalRoutes;
}

//-(void) setStart:(SMCyLocation*)start andEnd:(SMCyLocation*)end{
//    self.state = RS_SEARCHING_FOR_ROUTE;
//    self.internalRoutes = [NSMutableArray new];
//    [self.internalRoutes addObject:[[SMCyBikeRoute alloc] initWithStart:start end:end andDelegate:self]];
//}

-(BOOL) breakRoute{
    if(!self.fullRoute)
        return NO;
    
//    if(self.state == RS_SEARCHING_FOR_ROUTE){
//        [searchingOperation cancel];
//        searchingOperation= nil;
//    }
    
    __weak SMTripRoute* selfRef= self;
//    self.state= RS_SEARCHING_FOR_ROUTE;
    
    searchingOperation= [NSBlockOperation blockOperationWithBlock:^{
        [selfRef breakRouteInBackground];
    }];
    
    searchingOperation.completionBlock= ^{
        //todo Change state
        if([selfRef.delegate respondsToSelector:@selector(didFinishBreakingRoute:)])
            [selfRef.delegate didFinishBreakingRoute:selfRef ];
    };
    
    if([self.delegate respondsToSelector:@selector(didStartBreakingRoute:)])
        [self.delegate didStartBreakingRoute:self];
    
    [[SMTransportation transportationQueue] addOperation:searchingOperation];
    
    return YES;
}

-(void)breakRouteInBackground{
    CLLocation* start= [self start];
    CLLocation* end= [self end];
    NSMutableArray* brokenRoutesTemp= [NSMutableArray new];
    double currentDistance= [start distanceFromLocation:end];
    
    NSArray* lines= [SMTransportation instance].lines;
    
    for( SMTransportationLine* transportationLine in lines){
        double toA= 0;
        double toB= 0;
        NSMutableArray* startDistances= [NSMutableArray new];
        NSMutableArray* endDistances= [NSMutableArray new];
        for(SMRouteStationInfo* stationLocation in transportationLine.stations){
            toA= [stationLocation.location distanceFromLocation:start];
            toB= [stationLocation.location distanceFromLocation:end];
            
            if(toA < currentDistance){
                stationLocation.startDistance= [NSNumber numberWithDouble:toA];
                [startDistances addObject:stationLocation];
            }
            
            if(toB < currentDistance){
                stationLocation.endDistance= [NSNumber numberWithDouble:toB];
                [endDistances addObject:stationLocation];
            }
        }
        
        [startDistances sortedArrayUsingComparator:^(SMRouteStationInfo* rs1, SMRouteStationInfo* rs2) {
            if(rs1.startDistance.doubleValue <rs2.startDistance.doubleValue){
                return (NSComparisonResult)NSOrderedAscending;
            }else{
                return (NSComparisonResult) NSOrderedDescending;
            }
            
        }];
        
        [endDistances sortedArrayUsingComparator:^(SMRouteStationInfo* rs1, SMRouteStationInfo* rs2) {
            if(rs1.endDistance.doubleValue <rs2.endDistance.doubleValue){
                return (NSComparisonResult)NSOrderedAscending;
            }else{
                return (NSComparisonResult) NSOrderedDescending;
            }
            
        }];
        
        SMRouteTransportationInfo* transportationRouteInfo= [SMRouteTransportationInfo new];

        transportationRouteInfo.startingStationsSorted= startDistances;
        transportationRouteInfo.endingStationsSorted= endDistances;
        transportationRouteInfo.transportationLine= transportationLine;
        
        NSLog(@"startDistances %@",startDistances);
        NSLog(@"endDistances %@",endDistances);
        [brokenRoutesTemp addObject:transportationRouteInfo];
    }

    
    self.brokenRouteInfo= [[SMBrokenRouteInfo alloc] init];
    self.brokenRouteInfo.transportationInfoArr= [NSArray arrayWithArray:brokenRoutesTemp];
    
    NSArray* trArray= [self transportationRoutesFromBrokenRoutes:self.brokenRouteInfo.transportationInfoArr];
    if(trArray && trArray.count>0){
        if([self splitWithTransportationRoute:[trArray objectAtIndex:0]]){
            NSLog(@"Route successfully splitted");
        }
    }
    
    
}

-(BOOL)splitWithTransportationRoute:(SMTransportationRoute*)transportationRoute{
    if(self.routes.count!=1)
        return NO;
    
    SMRoute* firstBikeRoute= [[SMRoute alloc] initWithRouteStart:self.fullRoute.locationStart  andEnd:transportationRoute.locationStart andDelegate:nil];
    
    SMRoute* finalBikeRoute= [[SMRoute alloc] initWithRouteStart:transportationRoute.locationEnd  andEnd:self.fullRoute.locationEnd andDelegate:nil];
    internalRoutes= [NSMutableArray new];
    [internalRoutes addObject:firstBikeRoute];
    [internalRoutes addObject:transportationRoute];
    [internalRoutes addObject:finalBikeRoute];
    
    return YES;
}

-(NSArray*)transportationRoutesFromBrokenRoutes:(NSArray*)brokenRoutes{
    return [self transportationRoutesFromBrokenRoutes:brokenRoutes limit:INT_MAX];
}

-(NSArray*)transportationRoutesFromBrokenRoutes:(NSArray*)brokenRoutes limit:(int)limit{
    if(!brokenRoutes || brokenRoutes.count==0)
        return nil;
    
    SMRouteTransportationInfo* routeInfo= [brokenRoutes objectAtIndex:0];
    
    if(routeInfo.startingStationsSorted.count==0 || routeInfo.endingStationsSorted.count==0)
        return nil;
    
    SMRouteStationInfo* closestStartingLocation= [routeInfo.startingStationsSorted objectAtIndex:0];
    SMRouteStationInfo* closestEndingLocation= [routeInfo.endingStationsSorted objectAtIndex:0];
    
    CLLocationCoordinate2D closestStartingLocationCoordinate2D= CLLocationCoordinate2DMake(closestStartingLocation.location.coordinate.latitude, closestStartingLocation.location.coordinate.longitude);
    CLLocationCoordinate2D closestEndingLocationCoordinate2D= CLLocationCoordinate2DMake(closestEndingLocation.location.coordinate.latitude, closestEndingLocation.location.coordinate.longitude);

    SMTransportationRoute* transportationRoute= [[SMTransportationRoute alloc] initWithRouteStart:closestStartingLocationCoordinate2D andEnd:closestEndingLocationCoordinate2D andDelegate:nil];
    
    return [NSArray arrayWithObject:transportationRoute];
    //    for(int i=0; i<MIN(limit, brokenRoutes.count); i++){
    //        SMCyBrokenRouteInfo* routeInfo= [brokenRoutes objectAtIndex:i];
    //
    //        for(int j=0; j<routeInfo.startingStationsSorted.count; j++){
    //
    //            for(int k=0; k<routeInfo.endingStationsSorted.count; k++){
    //
    //            }
    //
    //        }
    //
    //    }
}

#pragma mark child notifications


-(CLLocation *)start{
    return [self.fullRoute getEndLocation];
}

-(CLLocation *)end{
    return [self.fullRoute getStartLocation];
}

@end

