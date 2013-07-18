//
//  SMRouteStationInfo.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMStationInfo.h"
#import "SMGeocoder.h"
@implementation SMStationInfo

-(id)initWithLongitude:(double)lon latitude:(double)lat{
    if(self= [super init]){
        self.name= [NSString stringWithFormat:@"Station %lf %lf",lon, lat];
        self.location= [[CLLocation alloc] initWithLatitude:lat longitude:lon];
    }
    return self;
}

-(void)setLocation:(CLLocation *)pLocation{
    _location= pLocation;
    _longitude= pLocation.coordinate.longitude;
    _latitude= pLocation.coordinate.latitude;
    [self fetchName];
//    [self performSelectorOnMainThread:@selector(fetchName) withObject:nil waitUntilDone:NO];
}

-(void)fetchName{
//    self.name= @"Statio"
//    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(_latitude, _longitude);
//    __weak SMStationInfo* selfRef= self;
//    [SMGeocoder reverseGeocode:coord completionHandler:^(NSDictionary *response, NSError *error) {
//
//        NSString* streetName = [response objectForKey:@"title"];
//        if (!streetName || [streetName isEqual:[NSNull null]] || [streetName isEqualToString:@""]) {
//            streetName = [NSString stringWithFormat:@"%f, %f", coord.latitude, coord.longitude];
//            
//        }
//        selfRef.name= @"asdfasd";
//    }];

}

-(BOOL)isEqual:(id)object{
    SMStationInfo* other= object;

    return [self.location isEqual:other.location];
}
@end
