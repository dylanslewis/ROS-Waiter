//
//  MenuDishesOptionsTableViewCell.h
//  Waiter
//
//  Created by Dylan Lewis on 27/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface MenuDishesOptionsTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *quantityLabel;
@property (weak, nonatomic) IBOutlet UILabel *dishNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *alreadySeenLabel;

@property (weak, nonatomic) IBOutlet UIButton *minusButton;
@property (weak, nonatomic) IBOutlet UIButton *plusButton;

@property (weak, nonatomic) PFObject *orderItemObject;

@property (nonatomic) BOOL isEditable;

@end
