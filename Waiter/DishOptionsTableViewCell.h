//
//  DishOptionsTableViewCell.h
//  Waiter
//
//  Created by Dylan Lewis on 26/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface DishOptionsTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *optionNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *optionPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *dishOptionQuantityLabel;

@property (nonatomic) BOOL hasBeenOrdered;

@property (weak, nonatomic) IBOutlet UIButton *selectOptionButton;

@property (weak, nonatomic) PFObject *orderItemObject;

@end
