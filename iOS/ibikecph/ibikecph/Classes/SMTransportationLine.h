//
//  SMTransportationLine.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMRelation.h"
#import "SMLineData.h"
#import "SMTransportation.h"
#import "SMSingleRouteInfo.h"

@interface SMTransportationLine : NSObject<NSCoding>

@property(nonatomic, strong) NSArray * stations;

@property(nonatomic, strong) NSString * name;

@property(nonatomic, strong) SMStationInfo* startStation;
@property(nonatomic, strong) SMStationInfo* endStation;

@property(nonatomic, strong) SMLineData* weekLineData;
@property(nonatomic, strong) SMLineData* weekendLineData;
@property(nonatomic, strong) SMLineData* weekendNightLineData;

@property(nonatomic, strong, readonly) NSString * name;
@property(nonatomic, strong, readonly) NSString* lineType;


-(id) initWithFile:(NSString*)filePath;
-(id)initWithRelation:(SMRelation*)pRelation;
-(void) loadFromFile:(NSString*)filePath;
-(SMTransportationLine*)clone;
-(BOOL)containsRouteFrom:(SMStationInfo*)sourceStation to:(SMStationInfo*)destStation forTime:(TravelTime)time;

-(void)addTimestampsForRouteInfo:(SMSingleRouteInfo*)singleRouteInfo array:(NSMutableArray*)arr currentTime:(NSDate*)date time:(TravelTime)time;
@end
