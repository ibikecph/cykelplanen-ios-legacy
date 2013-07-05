//
//  SMBreakRouteViewController.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMBreakRouteViewController.h"

@interface SMBreakRouteViewController (){
    UIPickerView* pickerView;
    NSArray* pickerModel;
}

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
    
    pickerView= [[UIPickerView alloc] init];
    pickerView.delegate= self;
    pickerView.dataSource= self;
    
    [self.view addSubview:pickerView];
    pickerView.hidden= YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}

-(int)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (void)viewDidUnload {
    [self setButtonSourceAddress:nil];
    [self setButtonDestinationAddress:nil];
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
    return pickerModel.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [pickerModel objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    NSLog(@"Item");
}

#pragma mark - break route delegate

-(void)didStartBreakingRoute:(SMTripRoute*)route{
    
}

-(void)didFinishBreakingRoute:(SMTripRoute*)route{
    
}

-(void)didFailBreakingRoute:(SMTripRoute*)route{
    
}

@end
