//
//  SMBreakRouteViewController.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMBreakRouteViewController.h"
#import "SMSingleRouteInfo.h"

@interface SMBreakRouteViewController (){
    UIPickerView* pickerView;
    NSArray* sourceStations;
}

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation SMBreakRouteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.titleLabel setText:translateString(@"break_route_title")];

   pickerView= [[UIPickerView alloc] init];
   pickerView.delegate= self;
   pickerView.dataSource= self;
    
    [self.view addSubview:pickerView];
    pickerView.hidden= YES;

    self.tableView.separatorStyle= UITableViewCellSeparatorStyleNone;

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(self.tripRoute){
        self.tripRoute.delegate= self;
        [self.tripRoute breakRoute];
    }
    self.tripRoute.brokenRouteInfo= nil;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.row) {
        case 0:
            return 94;
        case 2:
            return 82;
        case 1:
            return 132;
        case 3:
            return 80;
    }
    
    return 52;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if ( section == 0 ) {
        return [tableView dequeueReusableCellWithIdentifier:@"breakRouteHeader"];
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 52.0f;
}

-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 4;
}

-(int)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell;
    NSString* CellId;
    switch (indexPath.row) {
        case 0:
        {
            CellId= @"SourceCell";
            cell= [tableView dequeueReusableCellWithIdentifier:CellId];
            break;
        }
        case 1:{
            CellId= @"TransportCell";
            cell= [tableView dequeueReusableCellWithIdentifier:CellId];
            break;
        }
        case 2:{
            CellId= @"DestinationCell";
            cell= [tableView dequeueReusableCellWithIdentifier:CellId];
            break;
        }
        case 3:{
            CellId= @"ButtonCell";
            cell= [tableView dequeueReusableCellWithIdentifier:CellId];
            break;
        }
        default:
            break;
    }
    
    cell.selectionStyle= UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (IBAction)onBack:(id)sender {
    [self dismiss];

}

-(void)dismiss{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

}

- (void)viewDidUnload {
    [self setTitle:nil];
    [super viewDidUnload];
}


-(IBAction)onSourceAddressButtonTap:(id)sender {
    
}

-(IBAction)onDestinationAddressButtonTap:(id)sender {
    
}

-(IBAction)onInfoTap:(id)sender{
    
}

#pragma mark - picker view

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return sourceStations.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    SMRouteStationInfo* stationInfo= [sourceStations objectAtIndex:row];
    return stationInfo.name;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    NSLog(@"Item");
}

#pragma mark - break route delegate

-(void)didStartBreakingRoute:(SMTripRoute*)route{
    
}

-(void)didFinishBreakingRoute:(SMTripRoute*)route{
//    NSLog(@"%d routes:",route.transportationRoutes.count);
//    for(SMSingleRouteInfo* routeInfo in route.transportationRoutes){
//        NSLog(@"%lf - %lf %lf",routeInfo.bikeDistance, routeInfo.distance1, routeInfo.distance2);
//    }
    
//    if(route.transportationRoutes.count > 0){
//        SMSingleRouteInfo* routeInfo= [route.transportationRoutes objectAtIndex:0];
//        
//        NSArray* endStationsSorted= [route.transportationRoutes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.sourceStation.longitude == %lf AND SELF.sourceStation.latitude == %lf",routeInfo.sourceStation.longitude, routeInfo.sourceStation.latitude]];
//        
//        NSLog(@"Start: %lf %lf", routeInfo.sourceStation.location.coordinate.latitude, routeInfo.sourceStation.location.coordinate.longitude);
//        NSLog(@"End stations:");
//        for(SMSingleRouteInfo* endRouteInfo in endStationsSorted){
//            NSLog(@"%lf - %lf %lf",endRouteInfo.bikeDistance, endRouteInfo.destStation.location.coordinate.latitude, endRouteInfo.destStation.location.coordinate.longitude);
//        }
//        if(endStationsSorted.count>0){
//            SMBrokenRouteInfo* brokenRouteInfo= [[SMBrokenRouteInfo alloc] init];
//            brokenRouteInfo.sourceStation= routeInfo.sourceStation;
//            brokenRouteInfo.destinationStation= ((SMSingleRouteInfo*)[endStationsSorted objectAtIndex:0]).destStation;
//            self.tripRoute.brokenRouteInfo= brokenRouteInfo;
//        }
//        
//    }
    
//    [self dismiss];
    
        [self dismiss];
}

-(void)didCalculateRouteDistances:(SMTripRoute*)route{
    sourceStations= [route.transportationRoutes valueForKey:@"sourceStation"];

    if(route.transportationRoutes.count > 0){
        SMSingleRouteInfo* routeInfo= [route.transportationRoutes objectAtIndex:0];
        
        NSArray* endStationsSorted= [route.transportationRoutes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.sourceStation.longitude == %lf AND SELF.sourceStation.latitude == %lf",routeInfo.sourceStation.longitude, routeInfo.sourceStation.latitude]];
        
        NSLog(@"Start: %lf %lf", routeInfo.sourceStation.location.coordinate.latitude, routeInfo.sourceStation.location.coordinate.longitude);
        NSLog(@"End stations:");
        for(SMSingleRouteInfo* endRouteInfo in endStationsSorted){
            NSLog(@"%lf - %lf %lf",endRouteInfo.bikeDistance, endRouteInfo.destStation.location.coordinate.latitude, endRouteInfo.destStation.location.coordinate.longitude);
        }
        if(endStationsSorted.count>0){
            SMBrokenRouteInfo* brokenRouteInfo= [[SMBrokenRouteInfo alloc] init];
            brokenRouteInfo.sourceStation= routeInfo.sourceStation;
            brokenRouteInfo.destinationStation= ((SMSingleRouteInfo*)[endStationsSorted objectAtIndex:0]).destStation;
            self.tripRoute.brokenRouteInfo= brokenRouteInfo;
        }
        
    }

}

-(void)didFailBreakingRoute:(SMTripRoute*)route{
    
}

-(void)displayStationViewAnimated{

}

-(void)hideStationViewAnimated{
    
}

@end
