//
//  SelectDiscountItemsView.h
//  Waiter
//
//  Created by Dylan Lewis on 04/10/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "DiscountsViewController.h"

@interface SelectDiscountItemsView : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    __weak IBOutlet UITableView *orderItemsTableView;
}

@property (strong, nonatomic) PFObject *currentOrder;

@property (strong, nonatomic) NSArray *previouslySelectedItems;

@end
