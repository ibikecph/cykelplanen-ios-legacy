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

-(id)initWithCoordinate:(CLLocationCoordinate2D)coord{
    if(self= [self initWithLongitude:coord.longitude latitude:coord.latitude]){}
    return self;
}

-(id)initWithLongitude:(double)lon latitude:(double)lat{
    if(self= [super init]){
        self.name= [NSString stringWithFormat:@"DFNAME %lf %lf",lon, lat];
        self.location= [[CLLocation alloc] initWithLatitude:lat longitude:lon];
    }
    return self;
}

-(void)setLocation:(CLLocation *)pLocation{
    _location= pLocation;
    _longitude= pLocation.coordinate.longitude;
    _latitude= pLocation.coordinate.latitude;
    
//    [self performSelectorOnMainThread:@selector(fetchName) withObject:nil waitUntilDone:NO];
//    [self fetchName];
    [[NSOperationQueue mainQueue] addOperation:[NSBlockOperation blockOperationWithBlock:^{
        [self fetchName];
    }]];
}

-(void)fetchName{

    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(_latitude, _longitude);
    __weak SMStationInfo* selfRef= self;
    [SMGeocoder reverseGeocode:coord completionHandler:^(NSDictionary *response, NSError *error) {
        
        NSString* streetName = [response objectForKey:@"title"];
        if (!streetName || [streetName isEqual:[NSNull null]] || [streetName isEqualToString:@""]) {
            streetName = [NSString stringWithFormat:@"Station %f, %f", coord.latitude, coord.longitude];

        }
        NSLog(@"Street name %@",streetName);
        selfRef.name= streetName;
    }];

}

-(BOOL)isEqual:(id)object{
    SMStationInfo* other= object;

    return [self.location isEqual:other.location];
}
@end
