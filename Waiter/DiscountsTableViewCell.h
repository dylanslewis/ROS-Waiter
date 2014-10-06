//
//  DiscountsTableViewCell.h
//  Waiter
//
//  Created by Dylan Lewis on 04/10/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface DiscountsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *offerDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *offerReductionAmountLabel;
@property (weak, nonatomic) IBOutlet UIButton *deleteDiscountButton;

@property (weak, nonatomic) PFObject *discount;

@end
