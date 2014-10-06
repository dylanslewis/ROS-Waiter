//
//  OrderItemTableViewCell.h
//  Waiter
//
//  Created by Dylan Lewis on 10/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OrderItemTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *orderItemQuantityLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderItemNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderItemPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderItemStateLabel;

@end
