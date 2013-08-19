//
//  SMRouteInfoViewController.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/2/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMRouteInfoViewController.h"
#import "SMTransportation.h"
#import "SMRouteTimeInfo.h"
#import "SMTrain.h"
@interface SMRouteInfoViewController ()

@end

@implementation SMRouteInfoViewController{
    NSDateFormatter* dateFormatter;
    NSArray* times;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {}
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.titleLabel setText:translateString(@"route_info")];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    dateFormatter= [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd. MMM YYYY"];
    
    [self filterLines];
}

-(void)filterLines{
    SMTransportation* transportation= [SMTransportation instance];
    NSDate* date= [NSDate new];
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *weekdayComponents =[cal components:NSWeekdayCalendarUnit fromDate:date];
    NSDateComponents *timeComponents =[cal components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
    NSInteger weekday = [weekdayComponents weekday];

    int hour= [timeComponents hour];
    int mins= [timeComponents minute];

    if(self.singleRouteInfo.type == SMStationInfoTypeLocalTrain){
        // temp
        NSArray* trains= [SMTransportation instance].trains;
        SMTime* cTime=[SMTime new];
        cTime.hour= hour;
        cTime.minutes= mins;
        NSMutableArray* timesArray= [NSMutableArray new];
        for(SMTrain* train in trains){
            NSArray* array= [train routeTimestampsForSourceStation:self.singleRouteInfo.sourceStation destinationStation:self.singleRouteInfo.destStation forDay:weekday time:cTime];
            if(array){
                [timesArray addObjectsFromArray:array];
            }
        }
        
        [timesArray sortUsingComparator:^NSComparisonResult(SMRouteTimeInfo* t1, SMRouteTimeInfo* t2){
            SMTime* src= [[SMTime alloc] initWithTime:t1.sourceTime];
            SMTime* src2= [[SMTime alloc] initWithTime:t2.sourceTime];
            
            int diff1= [cTime differenceInMinutesFrom:src];
            int diff2= [cTime differenceInMinutesFrom:src2];
            if(diff1 > diff2)
                return NSOrderedDescending;
            else
                return NSOrderedAscending;
            
        }];
     
        BOOL hasDuplicates= NO;
        do{
            hasDuplicates= NO;
            
            for(int i=0; i<((int)timesArray.count)-1; i++){
                
                SMRouteTimeInfo* first= timesArray[i];
                for(int j=i+1; j<timesArray.count; j++){
                    SMRouteTimeInfo* second= timesArray[j];
                    if([second.sourceTime isEqual:first.sourceTime]){
                        [timesArray removeObject:second];
                        hasDuplicates= YES;
                        break;
                    }
                    if(hasDuplicates)
                        break;
                    
                }
            }
        }while(hasDuplicates);
        times= [NSArray arrayWithArray:timesArray];

    }else{
        TravelTime time;
        // determine current time (weekday / weekend / weekend night)
        if([self isNightForDayAtIndex:6 components:weekdayComponents] || [self isNightForDayAtIndex:7 components:weekdayComponents]){
            time= TravelTimeWeekendNight;
        }else if(weekday>=1 && weekday<=5){
            time= TravelTimeWeekDay;
        }else if(weekday==6 || weekday==0){
            time= TravelTimeWeekend;
        }
        
        NSMutableArray* timesArr= [NSMutableArray new];
    //    NSMutableArray* lines= [NSMutableArray new];
        
        for(SMTransportationLine* line in transportation.lines){
            if([line containsRouteFrom:self.singleRouteInfo.sourceStation to:self.singleRouteInfo.destStation forTime:time]){
                [line addTimestampsForRouteInfo:self.singleRouteInfo array:timesArr currentTime:date time:time];
            }
        }
        times= [NSArray arrayWithArray:timesArr];
    }
    [self.tableView reloadData];


}

-(BOOL)isNightForDayAtIndex:(int)index components:(NSDateComponents*)comps{
    return ([comps weekday]== index && [comps hour]>20) || ( (([comps weekday]+1)%7) == index && [comps hour]<5);
}

-(BOOL)isDayForDayAtIndex:(int)index components:(NSDateComponents*)comps{
    return [comps weekday] == index && [comps hour]<20 && [comps hour]>5;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [self setTitleLabel:nil];
    [super viewDidUnload];
}

- (IBAction)didTapOnBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 6;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.row) {
        case 0:
            return 132;
        case 1:
        case 3:
        case 5:
            return 40;
        case 2:
        case 4:
            return 29;
    }
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell;
    
    switch (indexPath.row) {
        case 0:
        {
            cell= [tableView dequeueReusableCellWithIdentifier:@"CellHeader"];

            UILabel* lbl= (UILabel*)[cell viewWithTag:1];
            [lbl setText:self.singleRouteInfo.sourceStation.name];
            lbl= (UILabel*)[cell viewWithTag:2];
            [lbl setText:self.singleRouteInfo.destStation.name];
            lbl= (UILabel*)[cell viewWithTag:3];
            [lbl setText:[NSString stringWithFormat:@"%@, Afg. kl. 15:50", [dateFormatter stringFromDate:[NSDate new]]]];
            
            lbl= (UILabel*)[cell viewWithTag:11];
            lbl= (UILabel*)[cell viewWithTag:12];
            lbl= (UILabel*)[cell viewWithTag:13];
            [lbl setText:translateString(@"Time")];
            lbl= (UILabel*)[cell viewWithTag:14];
            [lbl setText:translateString(@"shift")];
            
            lbl= (UILabel*)[cell viewWithTag:21];
            [lbl setText:translateString(@"From:")];
            lbl= (UILabel*)[cell viewWithTag:22];
            [lbl setText:translateString(@"To:")];
            lbl= (UILabel*)[cell viewWithTag:23];
            [lbl setText:[translateString(@"Time") stringByAppendingString:@":"]];
            break;
        }
        case 1:
        case 3:
        case 5:
        {
            cell= [tableView dequeueReusableCellWithIdentifier:@"CellData"];
            SMRouteTimeInfo* routeTimeInfo;
            if(times.count >=3){
                routeTimeInfo= [times objectAtIndex:indexPath.row/2];
            }
            
            SMTime* difference= [routeTimeInfo.sourceTime differenceFrom:routeTimeInfo.destTime];
            UILabel* lbl= (UILabel*)[cell viewWithTag:1];
            [lbl setText:[NSString stringWithFormat:@"%02d:%02d",routeTimeInfo.sourceTime.hour, routeTimeInfo.sourceTime.minutes]];
            lbl= (UILabel*)[cell viewWithTag:2];
            [lbl setText:[NSString stringWithFormat:@"%02d:%02d",routeTimeInfo.destTime.hour, routeTimeInfo.destTime.minutes]];
            lbl= (UILabel*)[cell viewWithTag:3];
            [lbl setText:[NSString stringWithFormat:@"%02d:%02d",difference.hour, difference.minutes]];
            lbl= (UILabel*)[cell viewWithTag:4];
            [lbl setText:@"0"];
            UIColor* bgColor;
            if(indexPath.row==1){
                bgColor= [UIColor colorWithRed:250.0/255.0 green:255.0/255.0 blue:190.0/255.0 alpha:1.0];
            }else{
                bgColor= [UIColor whiteColor];
            }
            [cell.contentView setBackgroundColor:bgColor];
            break;
        }
        case 2:
        case 4:
        {
            cell= [tableView dequeueReusableCellWithIdentifier:@"CellText"];
            UILabel* lbl= (UILabel*)[cell viewWithTag:1];
            [lbl setText:@"Long text Long text Long text Long text Long text "];
            break;
        }
        default:
            cell= nil;
    }
    cell.selectionStyle= UITableViewCellSelectionStyleNone;
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
@end
