//
//  SMLoadStationsView.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/22/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMLoadStationsView : UIView

@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

-(void)setup;
@end
