//
//  SMBrokenRouteInfo.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMRouteStationInfo.h"

// contains information about a route
@interface SMBrokenRouteInfo : NSObject

@property(nonatomic, strong) SMRouteStationInfo* sourceStation;
@property(nonatomic, strong) SMRouteStationInfo* destinationStation;

@end
