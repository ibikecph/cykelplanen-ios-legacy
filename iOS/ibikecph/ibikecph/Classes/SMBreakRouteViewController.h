//
//  SMBreakRouteViewController.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMTripRoute.h"

@interface SMBreakRouteViewController : UITableViewController<UIPickerViewDelegate, UIPickerViewDataSource, SMBreakRouteDelegate>

@property (weak, nonatomic) IBOutlet UIButton *buttonSourceAddress;
@property (weak, nonatomic) IBOutlet UIButton *buttonDestinationAddress;
@property(nonatomic, strong) SMTripRoute* route;
@property(nonatomic, strong) SMRoute* fullRoute;
@end
