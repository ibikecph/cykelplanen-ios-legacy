//
//  SMTransportationLine.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMTransportationLine : NSObject

@property(nonatomic, strong, readonly) NSArray * stations;
@property(nonatomic, strong, readonly) NSString * name;

-(id) initWithFile:(NSString*)filePath;
-(void) loadFromFile:(NSString*)filePath;

@end
