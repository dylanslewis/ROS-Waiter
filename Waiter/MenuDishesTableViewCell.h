//
//  MenuDishesTableViewCell.h
//  Waiter
//
//  Created by Dylan Lewis on 22/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface MenuDishesTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *dishNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dishPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *dishQuantityLabel;
@property (weak, nonatomic) IBOutlet UILabel *fromLabel;
@property (weak, nonatomic) IBOutlet UILabel *alreadySeenLabel;

@property (weak, nonatomic) IBOutlet UIButton *minusDishButton;
@property (weak, nonatomic) IBOutlet UIButton *addDishButton;

@property (weak, nonatomic) PFObject *dishObject;
@property (weak, nonatomic) PFObject *orderItemObject;

@property (nonatomic) BOOL isEditable;

@end
