//
//  SMTransportation.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTransportation.h"
#import "SMTransportationLine.h"

#define MAX_CONCURENT_ROUTE_THREADS 4

@implementation SMTransportation

+(SMTransportation*)instance{
    static SMTransportation* instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance= [[SMTransportation alloc] init];
    });
    
    return instance;
}

+(NSOperationQueue*) transportationQueue{
    static NSOperationQueue * sRequestQueue;
    
    if(!sRequestQueue){
        sRequestQueue = [NSOperationQueue new];
        sRequestQueue.maxConcurrentOperationCount = MAX_CONCURENT_ROUTE_THREADS;
    }
    
    return sRequestQueue;
}


-(void) loadDummyData{
    NSString * filePath0 = [[NSBundle mainBundle] pathForResource:@"Albertslundruten" ofType:@"line"];
    NSString * filePath1 = [[NSBundle mainBundle] pathForResource:@"Farumruten" ofType:@"line"];
    SMTransportationLine * line0 = [[SMTransportationLine alloc] initWithFile:filePath0];
    SMTransportationLine * line1 = [[SMTransportationLine alloc] initWithFile:filePath1];

    self.lines = @[line0,line1];
}

@end
