//
//  SMRouteStationInfo.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMRouteStationInfo.h"

@implementation SMRouteStationInfo

-(id)initWithLongitude:(double)lon latitude:(double)lat{
    if(self= [super init]){
        self.location= [[CLLocation alloc] initWithLatitude:lat longitude:lon];
    }
    return self;
}

@end
