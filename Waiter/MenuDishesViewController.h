//
//  MenuDishesViewController.h
//  Waiter
//
//  Created by Dylan Lewis on 22/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <Parse/Parse.h>

@interface MenuDishesViewController : UITableViewController

@property (strong, nonatomic) PFObject *currentCourse;
@property (strong, nonatomic) PFObject *currentOrder;

@end
