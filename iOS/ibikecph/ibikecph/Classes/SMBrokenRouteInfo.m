//
//  SMBrokenRouteInfo.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMBrokenRouteInfo.h"
#import "SMRouteTransportationInfo.h"
#import "SMRouteStationInfo.h"
@implementation SMBrokenRouteInfo

-(void)setTransportationInfoArr:(NSArray *)pTransportationInfoArr{
    _transportationInfoArr= pTransportationInfoArr;
    
    [self generateSortedDistanceArrays];
}

-(void)generateSortedDistanceArrays{
    NSMutableArray* sorted= [[NSMutableArray alloc] init];
    for(SMRouteTransportationInfo* trInfo in self.transportationInfoArr){
        [sorted addObjectsFromArray:trInfo.startingStationsSorted];
    }
    
    [sorted sortUsingComparator:^NSComparisonResult(SMRouteStationInfo* s1, SMRouteStationInfo* s2 ){
        if(s1.startDistance.doubleValue < s2.startDistance.doubleValue)
            return NSOrderedAscending;
        else
            return NSOrderedDescending;
    }];
}
@end
