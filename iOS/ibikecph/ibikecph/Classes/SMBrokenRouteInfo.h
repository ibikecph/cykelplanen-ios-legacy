//
//  SMBrokenRouteInfo.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMBrokenRouteInfo : NSObject

@property(nonatomic, strong) NSArray* transportationInfoArr; // array of SMRouteTransportationInfo
@property(nonatomic, strong) NSArray* startDistances;
@end
