//
//  SMTransportationLine.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTransportationLine.h"
#import "SMStationInfo.h"
#import "SMNode.h"

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

-(id)initWithRelation:(SMRelation*)pRelation{
    if(self=[super init]){
        NSMutableArray * tempStations = [NSMutableArray new];
        for(SMNode* node in pRelation.nodes){
            SMStationInfo* stationInfo= [[SMStationInfo alloc] initWithCoordinate:node.coordinate];
            [tempStations addObject:stationInfo];
        }
        
        SMStationInfo* si= [[SMStationInfo alloc] initWithLongitude:20.453004 latitude:44.815098];
        SMStationInfo* si2= [[SMStationInfo alloc] initWithLongitude:20.433537 latitude:44.815286];
        [tempStations addObject:si];
        [tempStations addObject:si2];
        self.stations = [NSArray arrayWithArray:tempStations];
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
        SMStationInfo* stationInfo= [[SMStationInfo alloc] initWithLongitude:lon.doubleValue latitude:lat.doubleValue];
        
        [stations addObject:stationInfo];
    }
    self.stations = stations;
}

@end
