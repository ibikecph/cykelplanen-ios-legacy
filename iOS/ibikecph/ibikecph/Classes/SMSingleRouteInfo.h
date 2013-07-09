//
//  SMSingleRouteInfo.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/8/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMTransportationLine.h"
#import "SMRouteStationInfo.h"
@interface SMSingleRouteInfo : NSObject

@property(nonatomic, strong) SMRouteStationInfo* sourceStation;
@property(nonatomic, strong) SMRouteStationInfo* destStation;
@property(nonatomic, strong) SMTransportationLine* transportationLine;

@property(nonatomic, assign) double bikeDistance;
@property(nonatomic, assign) double distance1;
@property(nonatomic, assign) double distance2;

-(CLLocation*) startLocation;
-(CLLocation*) endLocation;
@end
