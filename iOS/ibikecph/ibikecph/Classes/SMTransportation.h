//
//  SMTransportation.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMTransportation : NSObject<NSXMLParserDelegate>

+(SMTransportation*)instance;
+(NSOperationQueue*) transportationQueue;

@property(nonatomic, strong) NSArray* lines;
@property(nonatomic, assign) BOOL loadingStations;

@end
