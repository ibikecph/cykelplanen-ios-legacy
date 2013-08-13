//
//  SMTrain.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/12/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTrain.h"

@implementation SMTrain

-(SMArrivalInformation*)informationForStation:(SMStationInfo*)station{
    if(!self.arrivalInformation){
        self.arrivalInformation= [NSMutableArray new];
    }
    
    SMArrivalInformation* arrivalInfo;
    NSArray* st= [self.arrivalInformation filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.station == %@",station]];
    if(st.count==0){
        arrivalInfo= [SMArrivalInformation new];
        arrivalInfo.station= station;
        [self.arrivalInformation addObject:arrivalInfo];
    }else{
        NSAssert(st.count==1, @"Invalid arrival info count");
        arrivalInfo= st[0];
    }
    return arrivalInfo;
}

-(BOOL)isOnRouteWithSourceStation:(SMStationInfo*)sourceSt destinationStation:(SMStationInfo*)destinationSt forDay:(int)dayIndex{
    BOOL hasSource= NO;
    BOOL hasDestination= NO;
    for(SMArrivalInformation* arrivalInformation in self.arrivalInformation){
        if(arrivalInformation.station == sourceSt && [arrivalInformation hasInfoForDayAtIndex:dayIndex]){
            hasSource= YES;
            if(hasDestination)
                break;
        }else if(arrivalInformation.station == destinationSt && [arrivalInformation hasInfoForDayAtIndex:dayIndex]){
            hasDestination= YES;
            if(hasSource)
                break;
        }
    }
    
    return hasSource && hasDestination;
}
@end
