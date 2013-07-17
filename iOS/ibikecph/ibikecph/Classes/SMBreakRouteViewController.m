//
//  SMBreakRouteViewController.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMBreakRouteViewController.h"
#import "SMSingleRouteInfo.h"

#import "SMTransportationCell.h"
#import "SMBikeWaypointCell.h"
#import "SMBreakRouteHeader.h"
#import "SMBreakRouteButtonCell.h"
#import "SMGeocoder.h"

@interface SMBreakRouteViewController (){
    NSArray* sourceStations;
    NSArray* destinationStations;
    NSArray* pickerModel;
    SMAddressPickerView* addressPickerView;
}

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) NSMutableArray* stationNames;
@property (strong, nonatomic) NSMutableArray* destStationNames;

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
    
    self.tableView.separatorStyle= UITableViewCellSeparatorStyleNone;

    // initialize AddressPickerView
    addressPickerView= [[SMAddressPickerView alloc] initWithFrame:self.view.bounds];
    addressPickerView.pickerView.delegate= addressPickerView;
    addressPickerView.pickerView.dataSource= self;
    addressPickerView.delegate= self;
    
    [self.view addSubview:addressPickerView];
    CGRect frm= addressPickerView.frame;
    frm.origin.y= self.view.frame.size.height;
    addressPickerView.frame= frm;
    
    if(self.tripRoute){
        self.tripRoute.delegate= self;
        
        double startTime = CACurrentMediaTime();
        [self.tripRoute breakRoute];
        double endTime = CACurrentMediaTime();
        NSLog(@"BREAK ROUTE time: %4.1fms", endTime - startTime);
    }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
    if(!sourceStations || sourceStations.count==0){
        UIAlertView* noRouteAlertView= [[UIAlertView alloc] initWithTitle:@"No route" message:@"Route cannot be broken" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [noRouteAlertView show];
    }
    
    [self.tableView reloadData];

   
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
        SMBreakRouteHeader* header = [tableView dequeueReusableCellWithIdentifier:@"breakRouteHeader"];
        [header.title setText:translateString(@"break_route_header_title")];
        [header.title sizeToFit];
        CGRect frame = header.title.frame;
        CGRect newFrame = header.routeDistance.frame;
        newFrame.origin.x = frame.origin.x + frame.size.width + 0;
        
        NSString* routeDistance = [NSString stringWithFormat:@"%4.1f km", self.tripRoute.fullRoute.estimatedRouteDistance / 1000.0];
        
        [header.routeDistance setText:routeDistance];
        [header.routeDistance setFrame:newFrame];
        return header;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 42.0f;
}

-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 4;
}

-(int)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString* CellId;
    switch (indexPath.row) {
        case 0:
        {
            CellId= @"SourceCell";
            SMBikeWaypointCell* wpCell= [tableView dequeueReusableCellWithIdentifier:CellId];
            [wpCell setupWithString:self.sourceName];
            
            float fDistance = 0;
            int fTime = 0;
            SMRoute* route = [self.tripRoute.brokenRoutes objectAtIndex:0];
            if ( route ) {
                fDistance = route.estimatedRouteDistance / 1000.0;
                fTime = route.estimatedTimeForRoute / 60;
            }
            NSString* distance = [NSString stringWithFormat:@"%4.1f km  %d min.", fDistance, fTime];
            [wpCell.labelDistance setText:distance];
            
            return wpCell;
            break;
        }
        case 1:{
            CellId= @"TransportCell";
            SMTransportationCell* tCell= [tableView dequeueReusableCellWithIdentifier:CellId];
            tCell.selectionStyle= UITableViewCellSelectionStyleNone;
//            [tCell.buttonAddressSource setTitle:self.sourceStation.name forState:UIControlStateNormal];
//            [tCell.buttonAddressSource setTitle:self.sourceStation.name forState:UIControlStateHighlighted];
//            [tCell.buttonAddressDestination setTitle:self.destinationStation.name forState:UIControlStateNormal];
//            [tCell.buttonAddressDestination setTitle:self.destinationStation.name forState:UIControlStateHighlighted];
            
            CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(self.sourceStation.latitude, self.sourceStation.longitude); 
            [SMGeocoder reverseGeocode:coord completionHandler:^(NSDictionary *response, NSError *error) {
                NSString* streetName = [response objectForKey:@"title"];
                if ([streetName isEqualToString:@""]) {
                    streetName = [NSString stringWithFormat:@"%f, %f", coord.latitude, coord.longitude];
                }
                [tCell.buttonAddressSource setTitle:streetName forState:UIControlStateNormal];
            }];
            
            coord = CLLocationCoordinate2DMake(self.destinationStation.latitude, self.destinationStation.longitude);
            [SMGeocoder reverseGeocode:coord completionHandler:^(NSDictionary *response, NSError *error) {
                NSString* streetName = [response objectForKey:@"title"];
                if ([streetName isEqualToString:@""]) {
                    streetName = [NSString stringWithFormat:@"%f, %f", coord.latitude, coord.longitude];
                }
                [tCell.buttonAddressDestination setTitle:streetName forState:UIControlStateNormal];
            }];
            
            return tCell;
            break;
        }
        case 2:{
            CellId= @"DestinationCell";
            SMBikeWaypointCell* wpCell= [tableView dequeueReusableCellWithIdentifier:CellId];
            [wpCell setupWithString:self.destinationName];
            [wpCell.labelAddressBottom setText:@"Some address here"];
                    
            float fDistance = 0;
            int fTime = 0;
            SMRoute* route = [self.tripRoute.brokenRoutes objectAtIndex:MIN(1, [self.tripRoute.brokenRoutes count]-1)];
            if ( route ) {
                fDistance = route.estimatedRouteDistance / 1000.0;
                fTime = route.estimatedTimeForRoute / 60;
            }
            NSString* distance = [NSString stringWithFormat:@"%4.1f km  %d min.", fDistance, fTime];
            [wpCell.labelDistance setText:distance];
            
            return wpCell;
            break;
        }
        case 3:{
            CellId= @"ButtonCell";
            SMBreakRouteButtonCell* cell= [tableView dequeueReusableCellWithIdentifier:CellId];
            [cell.btnBreakRoute setTitle:translateString(@"break_route_title") forState:UIControlStateNormal];

            return cell;
            break;
        }
        default:
            break;
    }
    
    return nil;
}

-(NSString*)formatAddressComponent:(NSString*)comp{
    NSString* trimmed= [comp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    int i = 0;
    
    while ((i < [trimmed length])
           && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[trimmed characterAtIndex:i]]) {
        i++;
    }
    return [trimmed substringFromIndex:i];
}

- (IBAction)onBack:(id)sender {
    [self dismiss];

}

-(void)dismiss{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{}

- (void)viewDidUnload {
    [self setTitle:nil];
    [self setButtonAddressSource:nil];
    [self setButtonAddressDestination:nil];
    [super viewDidUnload];
}


-(IBAction)onSourceAddressButtonTap:(id)sender {
    [self displayAddressViewWithAddressType:AddressTypeSource model:sourceStations];
}

-(void)displayAddressViewWithAddressType:(AddressType)pAddressType model:(NSArray*)pModel{
    addressPickerView.addressType= pAddressType;
    pickerModel= pModel;
    
    if ( addressPickerView.addressType == AddressTypeSource ) {
        
        self.stationNames = nil;
        self.stationNames = [[NSMutableArray alloc] init];
        
        __block int counter = 0;
        
        // Get names of stations
        NSLog(@"Route info: %d", [pickerModel count]);
        for (SMSingleRouteInfo* routeInfo in pickerModel) {
            NSLog(@"STATION NAMES");
            CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(routeInfo.sourceStation.latitude, routeInfo.sourceStation.longitude);
            [SMGeocoder reverseGeocode:coord completionHandler:^(NSDictionary *response, NSError *error) {
                NSString* streetName = [response objectForKey:@"title"];
                NSLog(@"Station NAME: %@", streetName);
                if ([streetName isEqualToString:@""]) {
                    streetName = [NSString stringWithFormat:@"%f, %f", coord.latitude, coord.longitude];
                }
                [self.stationNames addObject:streetName];
                counter++;
                
                if (counter >= [pickerModel count]) {
                    [addressPickerView displayAnimated];
                }
            }];
            
        }
    } else if ( addressPickerView.addressType == AddressTypeDestination ) {
        self.destStationNames = nil;
        self.destStationNames = [[NSMutableArray alloc] init];
        
        __block int counter = 0;
        
        // Get names of stations
        NSLog(@"Route info: %d", [pickerModel count]);
        for (SMSingleRouteInfo* routeInfo in pickerModel) {
            NSLog(@"STATION NAMES");
            CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(routeInfo.destStation.latitude, routeInfo.destStation.longitude);
            [SMGeocoder reverseGeocode:coord completionHandler:^(NSDictionary *response, NSError *error) {
                NSString* streetName = [response objectForKey:@"title"];
                NSLog(@"Station NAME: %@", streetName);
                if ([streetName isEqualToString:@""]) {
                    streetName = [NSString stringWithFormat:@"%f, %f", coord.latitude, coord.longitude];
                }
                [self.destStationNames addObject:streetName];
                counter++;
                
                if (counter >= [pickerModel count]) {
                    [addressPickerView displayAnimated];
                }
            }];
            
        }
    }
}

-(IBAction)onDestinationAddressButtonTap:(id)sender {
    
    [self displayAddressViewWithAddressType:AddressTypeDestination model:[self endStationsForSourceStation:self.sourceStation]];
}


-(IBAction)onInfoTap:(id)sender{
    
}

#pragma mark - picker view

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return pickerModel.count;
}

- (IBAction)onBreakRoute:(id)sender {
    SMBrokenRouteInfo* brokenRouteInfo= [[SMBrokenRouteInfo alloc] init];
    brokenRouteInfo.sourceStation= self.sourceStation;;
    brokenRouteInfo.destinationStation= self.destinationStation;
    self.tripRoute.brokenRouteInfo= brokenRouteInfo;
}

-(NSString*)addressView:(SMAddressPickerView *)pAddressPickerView titleForRow:(int)row{
    if ( addressPickerView.addressType==AddressTypeSource ) {
        if ( [self.stationNames count] > row )
            return [self.stationNames objectAtIndex:row];
        else
            return @"0";
    }
    else if ( addressPickerView.addressType==AddressTypeDestination ) {
        //return ((SMSingleRouteInfo*)[pickerModel objectAtIndex:row]).destStation.name;
        if ( [self.destStationNames count] > row )
            return [self.destStationNames objectAtIndex:row];
        else
            return @"0";
    }
    
    return @"";
}

-(void)addressView:(SMAddressPickerView*)pAddressPickerView didSelectItemAtIndex:(int)index forAddressType:(AddressType)pAddressType{
    NSAssert(pAddressType!=AddressTypeUndefined, @"Address type is undefined");
    if(pAddressType==AddressTypeDestination){
        SMSingleRouteInfo* routeInfo= [destinationStations objectAtIndex:index];
        self.destinationStation= routeInfo.destStation;
        
    }else if(pAddressType==AddressTypeSource){
        SMSingleRouteInfo* routeInfo= [sourceStations objectAtIndex:index];
        self.sourceStation= routeInfo.sourceStation;
        
        // TODO: test
        BOOL found= NO;
        NSArray* arr= [sourceStations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.sourceStation == %@",self.sourceStation]];
        for(SMSingleRouteInfo* ri in arr){
            if(ri.destStation==self.destinationStation){
                found= YES;
                break;
            }
        }
        if(!found){
            destinationStations= [self endStationsForSourceStation:routeInfo.sourceStation];
            self.destinationStation= routeInfo.destStation;
        }
    }
    [self.tableView reloadData];
}


#pragma mark - break route delegate

-(void)didStartBreakingRoute:(SMTripRoute*)route{}

-(void)didFinishBreakingRoute:(SMTripRoute*)route{
    [self.tableView reloadData];
     
    [self dismiss];

}

-(void)didFailBreakingRoute:(SMTripRoute*)route{
    
}

-(void)didCalculateRouteDistances:(SMTripRoute*)route{


    NSMutableArray* stations= [NSMutableArray new];
    
    for(SMSingleRouteInfo* routeInfo in route.transportationRoutes){
        if(![stations containsObject:routeInfo]){
            [stations addObject:routeInfo];
        }
    }
    
    sourceStations= [NSArray arrayWithArray:stations];
    
    if(route.transportationRoutes.count > 0){
        SMSingleRouteInfo* routeInfo= [route.transportationRoutes objectAtIndex:0];
        
        self.sourceStation= routeInfo.sourceStation;
        
        destinationStations= [self endStationsForSourceStation:routeInfo.sourceStation];

        routeInfo=[destinationStations objectAtIndex:0];
        self.destinationStation= routeInfo.destStation;
        
    }else{
        // no routes found
        // this is handled in the viewDidAppear since the view might not be visible at this point, therefore it cannot be dismissed

    }

    [self.tableView reloadData];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [self dismiss];
}

-(NSArray*)endStationsForSourceStation:(SMStationInfo*)pSourceStation{
    return [self.tripRoute.transportationRoutes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.sourceStation.longitude == %lf AND SELF.sourceStation.latitude == %lf",pSourceStation.longitude, pSourceStation.latitude]];
}



#pragma mark - getters and setters

-(void)setSourceStation:(SMStationInfo *)pSourceStation{
    _sourceStation= pSourceStation;

}

-(void)setDestinationStation:(SMStationInfo *)pDestinationStation{
    _destinationStation= pDestinationStation;
}

@end
