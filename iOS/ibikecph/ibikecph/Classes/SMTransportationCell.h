//
//  SMTransportationCell.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMTransportationCell : UITableViewCell

@property(weak, nonatomic) IBOutlet UIButton* buttonAddressSource;
@property(weak, nonatomic) IBOutlet UIButton* buttonAddressDestination;
@property(weak, nonatomic) IBOutlet UIButton* buttonAddressInfo;
@end
