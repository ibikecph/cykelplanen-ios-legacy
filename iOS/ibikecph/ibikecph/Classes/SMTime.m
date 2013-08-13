//
//  SMTime.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/6/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTime.h"

@implementation SMTime

-(SMTime*)differenceFrom:(SMTime*)other{
    SMTime* time= [SMTime new];
    
    int totalMins= self.hour*60 + self.minutes;
    int otherMins= ((other.hour>=self.hour)?other.hour:(24+other.hour))*60 + other.minutes;

    otherMins-= totalMins;
    
    int hour= otherMins/60;
    int min= otherMins- hour*60;
    
    time.hour= hour;
    time.minutes= min;
    return time;
}

-(BOOL)isBetween:(SMTime*)first and:(SMTime*)second{
    int secondHour= second.hour;
    if(first.hour > second.hour){
        secondHour+= 24;
    }

    return (self.hour>first.hour && self.hour<secondHour) || (self.hour==first.hour && self.minutes > first.minutes) || (self.hour==secondHour && self.minutes<second.minutes);
}

-(id)copy{
    SMTime* time= [SMTime new];
    time.hour= self.hour;
    time.minutes= self.minutes;
    
    return time;
}
@end
