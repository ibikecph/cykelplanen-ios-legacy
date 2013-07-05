//
//  SMTripRoute.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMRoute.h"
#import "SMBrokenRouteInfo.h"
@class SMTripRoute;

@protocol SMBreakRouteDelegate <NSObject>
- (void) didStartBreakingRoute:(SMTripRoute*)route;
- (void) didFinishBreakingRoute:(SMTripRoute*)route;
- (void) didFailBreakingRoute:(SMTripRoute*)route;
@end

@interface SMTripRoute : NSObject

@property(nonatomic, readonly) BOOL isValid;
@property(nonatomic, strong, readonly) NSArray * routes;
@property(nonatomic, strong) SMRoute* fullRoute;
@property(nonatomic, strong) SMBrokenRouteInfo* brokenRouteInfo;

@property(nonatomic, weak) id<SMBreakRouteDelegate> delegate;

-(BOOL) breakRoute;

@end
