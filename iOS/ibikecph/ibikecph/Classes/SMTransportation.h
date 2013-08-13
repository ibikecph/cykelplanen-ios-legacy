//
//  SMTransportation.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    TravelTimeWeekDay = 0,
    TravelTimeWeekend = 1,
    TravelTimeWeekendNight = 2
}  TravelTime ;

@interface SMTransportation : NSObject<NSXMLParserDelegate,NSCoding>

+(SMTransportation*)instance;
+(NSOperationQueue*) transportationQueue;

@property(nonatomic, strong) NSArray* allStations;
@property(nonatomic, strong) NSMutableArray* lines;
@property(nonatomic, strong) NSArray* trains;
@property(nonatomic, assign) BOOL loadingStations;
-(void)save;
-(void)validateAndSave;
@end
