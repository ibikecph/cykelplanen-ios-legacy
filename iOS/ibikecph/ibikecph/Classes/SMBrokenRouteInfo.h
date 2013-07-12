//
//  SMBrokenRouteInfo.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMStationInfo.h"

// contains information about a route
@interface SMBrokenRouteInfo : NSObject

@property(nonatomic, strong) SMStationInfo* sourceStation;
@property(nonatomic, strong) SMStationInfo* destinationStation;

@end
