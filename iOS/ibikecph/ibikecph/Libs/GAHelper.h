//
//  GAHelper.h
//  Magasin
//
//  Created by Ivan Pavlovic on 10/30/14.
//  Copyright (c) 2014 Spoiled Milk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GAHelper : NSObject

+ (BOOL)trackEventWithCategory:(NSString*)category withAction:(NSString*)action withLabel:(NSString*)label withValue:(NSInteger)value;
+ (BOOL)trackTimingWithCategory:(NSString*)category withValue:(NSTimeInterval)time withName:(NSString*)name withLabel:(NSString*)label;
+ (BOOL)trackSocial:(NSString*)social withAction:(NSString*)action withTarget:(NSString*)url;

@end
