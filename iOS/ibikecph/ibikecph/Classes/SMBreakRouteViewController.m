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
@interface SMBreakRouteViewController (){
    NSArray* sourceStations;
    NSArray* destinationStations;
    NSArray* pickerModel;
    SMAddressPickerView* addressPickerView;
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
//            cell= [tableView dequeueReusableCellWithIdentifier:CellId];
            SMTransportationCell* tCell= [tableView dequeueReusableCellWithIdentifier:CellId];
            [tCell.buttonAddressSource setTitle:self.sourceStation.name forState:UIControlStateNormal];
            [tCell.buttonAddressSource setTitle:self.sourceStation.name forState:UIControlStateHighlighted];
            [tCell.buttonAddressDestination setTitle:self.destinationStation.name forState:UIControlStateNormal];
            [tCell.buttonAddressDestination setTitle:self.destinationStation.name forState:UIControlStateHighlighted];
            return tCell;
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
    [addressPickerView displayAnimated];
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
    if(addressPickerView.addressType==AddressTypeSource)
        return ((SMSingleRouteInfo*)[pickerModel objectAtIndex:row]).sourceStation.name;
    else if(addressPickerView.addressType==AddressTypeDestination)
        return ((SMSingleRouteInfo*)[pickerModel objectAtIndex:row]).destStation.name;
    
    return @"";
}

-(void)addressView:(SMAddressPickerView*)pAddressPickerView didSelectItemAtIndex:(int)index forAddressType:(AddressType)pAddressType{
    NSAssert(pAddressType!=AddressTypeUndefined, @"Address type is undefined");
    if(pAddressType==AddressTypeDestination){
        SMSingleRouteInfo* routeInfo= [destinationStations objectAtIndex:index];
        self.destinationStation= routeInfo.destStation;
    }else if(pAddressType==AddressTypeSource){
        SMSingleRouteInfo* routeInfo= [self.tripRoute.transportationRoutes objectAtIndex:index];
        self.sourceStation= routeInfo.sourceStation;
    }
}


#pragma mark - break route delegate

-(void)didStartBreakingRoute:(SMTripRoute*)route{
    
}

-(void)didFinishBreakingRoute:(SMTripRoute*)route{
 /*
    NSLog(@"%d routes:",route.transportationRoutes.count);
    for(SMSingleRouteInfo* routeInfo in route.transportationRoutes){
        NSLog(@"%lf - %lf %lf",routeInfo.bikeDistance, routeInfo.distance1, routeInfo.distance2);
    }
// /*
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
*/
    
    [self dismiss];
    

}

-(void)didCalculateRouteDistances:(SMTripRoute*)route{
    sourceStations= route.transportationRoutes;

    if(route.transportationRoutes.count > 0){
        SMSingleRouteInfo* routeInfo= [route.transportationRoutes objectAtIndex:0];
        
        self.sourceStation= routeInfo.sourceStation;
        
        destinationStations= [self endStationsForSourceStation:routeInfo.sourceStation];

        routeInfo=[destinationStations objectAtIndex:0];
        self.destinationStation= routeInfo.destStation;
        
//        NSLog(@"Start: %lf %lf", routeInfo.sourceStation.location.coordinate.latitude, routeInfo.sourceStation.location.coordinate.longitude);
//        NSLog(@"End stations:");
//        for(SMSingleRouteInfo* endRouteInfo in destinationStations){
//            NSLog(@"%lf - %lf %lf",endRouteInfo.bikeDistance, endRouteInfo.destStation.location.coordinate.latitude, endRouteInfo.destStation.location.coordinate.longitude);
//        }
//        if(endStationsSorted.count>0){

//        }
        
    }else{
        // TODO: handle no routes found
    }
    
    [self.tableView reloadData];
}

-(NSArray*)endStationsForSourceStation:(SMStationInfo*)pSourceStation{
    return [self.tripRoute.transportationRoutes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.sourceStation.longitude == %lf AND SELF.sourceStation.latitude == %lf",pSourceStation.longitude, pSourceStation.latitude]];
}

-(void)didFailBreakingRoute:(SMTripRoute*)route{
    
}

-(void)displayStationViewAnimated{

}

-(void)hideStationViewAnimated{
    
}

#pragma mark - getters and setters

-(void)setSourceStation:(SMStationInfo *)pSourceStation{
    _sourceStation= pSourceStation;
//    [self.buttonAddressSource.titleLabel setText:pSourceStation.name];
    [self.tableView reloadData];
}

-(void)setDestinationStation:(SMStationInfo *)pDestinationStation{
    _destinationStation= pDestinationStation;
//    [self.buttonAddressSource.titleLabel setText:pDestinationStation.name];
    [self.tableView reloadData];
}

@end
