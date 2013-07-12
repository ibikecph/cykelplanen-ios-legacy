//
//  SMReminderTableViewCell.m
//  I Bike CPH
//
//  Created by Igor Jerković on 7/12/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMReminderTableViewCell.h"

@interface SMReminderTableViewCell()
@property (weak, nonatomic) IBOutlet UILabel *day;
@property (weak, nonatomic) IBOutlet UISwitch *reminderSwitch;
@end

@implementation SMReminderTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupWithTitle:(NSString*)title {
    [self.day setText:title];
}

@end
