//
//  SMTransportationLine.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTransportationLine.h"
#import "SMRouteStationInfo.h"

@interface SMTransportationLine()
@property(nonatomic, strong, readwrite) NSArray * stations;
@property(nonatomic, strong, readwrite) NSString * name;
@end

@implementation SMTransportationLine
-(id) initWithFile:(NSString*)filePath{
    self = [super init];
    if(self){
        [self loadFromFile:filePath];
    }
    return self;
}

-(void) loadFromFile:(NSString*)filePath{
    NSError * err;
    NSData * data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    
    self.name = [dict valueForKey:@"name"];
    NSArray * coord = [dict valueForKey:@"coordinates"];
    NSNumber * lon;
    NSNumber * lat;
    NSMutableArray * stations = [NSMutableArray new];
    for(NSArray * arr in coord){
        lon = [arr objectAtIndex:0];
        lat = [arr objectAtIndex:1];
        SMRouteStationInfo* stationInfo= [[SMRouteStationInfo alloc] initWithLongitude:lon.doubleValue latitude:lat.doubleValue];

        [stations addObject:stationInfo];
    }
    self.stations = stations;
}

@end
