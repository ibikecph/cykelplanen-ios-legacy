//
//  SMCyLwFirstTimeIntro.m
//  Cykelsuperstierne
//
//  Created by Rasko Gojkovic on 6/27/13.
//  Copyright (c) 2013 Rasko Gojkovic. All rights reserved.
//

#import "SMCyLwFirstTimeIntro.h"

@interface SMCyLwFirstTimeIntro ()
@property (weak, nonatomic) IBOutlet UIButton *btnExitGuide;

@end

@implementation SMCyLwFirstTimeIntro

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onExit:(UIButton *)sender {
    [self performSegueWithIdentifier:@"firstTimeIntroToMap" sender:self];
}
- (void)viewDidUnload {
    [self setBtnExitGuide:nil];
    [super viewDidUnload];
}
@end
