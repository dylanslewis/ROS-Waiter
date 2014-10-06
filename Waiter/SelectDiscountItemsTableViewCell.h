//
//  SelectDiscountItemsTableViewCell.h
//  Waiter
//
//  Created by Dylan Lewis on 04/10/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectDiscountItemsTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *dishQuantityLabel;
@property (weak, nonatomic) IBOutlet UILabel *dishNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dishPriceLabel;

@end
