//
//  GAHelper.m
//  Magasin
//
//  Created by Ivan Pavlovic on 10/30/14.
//  Copyright (c) 2014 Spoiled Milk. All rights reserved.
//

#import "GAHelper.h"

#import "GAI.h"
#import "GAITracker.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@implementation GAHelper

+ (BOOL)trackEventWithCategory:(NSString*)category withAction:(NSString*)action withLabel:(NSString*)label withValue:(NSInteger)value {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    NSDictionary * d = [[GAIDictionaryBuilder
                        createEventWithCategory:category
                        action:action
                        label:label
                        value:[NSNumber numberWithInteger:value]
                        ] build];
    [tracker send:d];
    return YES;
}

+ (BOOL)trackTimingWithCategory:(NSString*)category withValue:(NSTimeInterval)time withName:(NSString*)name withLabel:(NSString*)label {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    NSDictionary * d = [[GAIDictionaryBuilder
                         createTimingWithCategory:category
                         interval:@((int)(time * 1000))
                         name:name
                         label:label]
                        build];
    [tracker send:d];
    return YES;
}

+ (BOOL)trackSocial:(NSString*)social withAction:(NSString*)action withTarget:(NSString*)url {
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder
                                                createSocialWithNetwork:social
                                                action:action
                                                target:url]
                                               build]];
    return YES;
}

@end
