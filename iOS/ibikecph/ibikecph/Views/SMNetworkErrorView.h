//
//  SMNetworkErrorView.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 06/06/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

@interface SMNetworkErrorView : UIView

@property (weak, nonatomic) IBOutlet UILabel *warningText;

+ (CGSize)getSize;
+ (SMNetworkErrorView*) getFromNib;


@end
