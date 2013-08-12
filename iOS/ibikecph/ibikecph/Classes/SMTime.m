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
@end
