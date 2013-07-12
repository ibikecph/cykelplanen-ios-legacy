//
//  SMReminder.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/10/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMReminder.h"

#define REMINDERS_FILE_NAME @"reminders.plist"

@implementation SMReminder{
    NSMutableDictionary* days;
}

+(SMReminder*)sharedInstance{
    static SMReminder* instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance= [SMReminder new];
    });
    return instance;
}

-(id)init{
    if(self=[super init]){
        [self load];
    }
    return self;
}

-(void)load{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:REMINDERS_FILE_NAME];
    // write plist to disk
    
    days= [NSDictionary dictionaryWithContentsOfFile:path];
    
    if(!days){ // no reminders set, yet
        days= [NSMutableDictionary new];
    }
}

-(void)save{
    if(!days) // can't save a nil dictionary
        return;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:REMINDERS_FILE_NAME];
    
    if([days writeToFile:path atomically:YES]){
        [self scheduleReminderNotifications];
    }
}

-(void)scheduleReminderNotifications{
    // remove all notifications
    [[UIApplication sharedApplication] cancelAllLocalNotifications];

    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate* now= [NSDate new];

    const int SECONDS_IN_DAY= 60*60*24;
    for(int i=0; i<7; i++){
        NSDate* currentDate= [now dateByAddingTimeInterval:i*SECONDS_IN_DAY];
        NSLog(@"currentDate %@",currentDate);
        NSDateComponents *weekdayComponents =[gregorian components:NSWeekdayCalendarUnit fromDate:currentDate];
        NSInteger weekday = [weekdayComponents weekday]-2;
        NSNumber* notifyNum= [days objectForKey:[NSNumber numberWithInt:weekday].stringValue];
        if(notifyNum && [notifyNum boolValue ]){

            UILocalNotification* notification= [UILocalNotification new];
             
            NSDate* fireDate= currentDate;
            [notification setTimeZone:[NSTimeZone defaultTimeZone]];
            [notification setFireDate:fireDate];
            notification.soundName= UILocalNotificationDefaultSoundName;
            notification.repeatInterval= NSWeekCalendarUnit;
            [notification setAlertAction:@"Open App"];
            [notification setAlertBody:@"Cykelsuperstierne Reminder"];

            [notification setHasAction:YES];
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        }
    }

}

-(void)setReminder:(BOOL)shouldRemind forDay:(Day)day{
    if(!days){ 
        days= [NSMutableDictionary new];
    }
    [days setObject:[NSNumber numberWithBool:shouldRemind] forKey:[NSNumber numberWithInt:day].stringValue];
}
@end
