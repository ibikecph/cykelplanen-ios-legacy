//
//  SMLineData.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMLineData.h"

@implementation SMLineData

-(id)init{
    if(self=[super init]){
        self.arrivalInfos= [NSMutableArray new];
    }
    return self;
}

-(SMDepartureInfo*)departureInfo{
    if(!_departureInfo){
        _departureInfo= [SMDepartureInfo new];
    }
    return _departureInfo;
}



@end
