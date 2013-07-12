//
//  SMCyReminderVC.m
//  Cykelsuperstierne
//
//  Created by Rasko on 6/26/13.
//  Copyright (c) 2013 Rasko Gojkovic. All rights reserved.
//

#import "SMCyLwReminderVC.h"
#import "SMReminder.h"
//#import "SMCySettings.h"

@interface SMCyLwReminderVC ()

@end

@implementation SMCyLwReminderVC

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
    
    // Set tint color for switches
    UIColor* orange = [UIColor colorWithRed:232.0f/255.0f green:123.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
    [self.swMonday setOnTintColor:orange];
    [self.swTuesday setOnTintColor:orange];
    [self.swWednesday setOnTintColor:orange];
    [self.swThursday setOnTintColor:orange];
    [self.swFriday setOnTintColor:orange];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveReminder:(UIButton *)sender {
    SMReminder * reminder = [SMReminder sharedInstance];

    [reminder setReminder:self.swMonday.isOn forDay:DayMonday];
    [reminder setReminder:self.swTuesday.isOn forDay:DayTuesday];
    [reminder setReminder:self.swWednesday.isOn forDay:DayWednesday];
    [reminder setReminder:self.swThursday.isOn forDay:DayThursday];
    [reminder setReminder:self.swFriday.isOn forDay:DayFriday];
    
    [reminder save];
    
    [self goToNextView];
}

- (IBAction)skip:(UIButton *)sender {
    [self goToNextView];
}

- (void) goToNextView{
    [self performSegueWithIdentifier:@"goToFavorites" sender:self];
}
@end
