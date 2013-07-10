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
        _longitude= lon;
        _latitude= lat;
        self.name= [NSString stringWithFormat:@"Station %lf %lf",_latitude,_longitude];
    }
    return self;
}

-(void)setLocation:(CLLocation *)pLocation{
    _location= pLocation;
    _longitude= pLocation.coordinate.longitude;
    _latitude= pLocation.coordinate.latitude;
    self.name= [NSString stringWithFormat:@"Station %lf %lf",_latitude,_longitude];
}

@end
