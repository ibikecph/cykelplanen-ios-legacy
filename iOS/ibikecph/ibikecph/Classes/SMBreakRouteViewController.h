//
//  SMBreakRouteViewController.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMTripRoute.h"
#import "SMStationPickerView.h"
@interface SMBreakRouteViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, SMBreakRouteDelegate>

@property (weak, nonatomic) IBOutlet UITableView* tableView;

@property(nonatomic, strong) SMTripRoute* tripRoute;
@property(nonatomic, strong) SMRoute* fullRoute;

@end
