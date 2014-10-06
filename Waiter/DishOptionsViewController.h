//
//  DishOptionsViewController.h
//  Waiter
//
//  Created by Dylan Lewis on 26/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <Parse/Parse.h>

@interface DishOptionsViewController : UITableViewController

@property (strong, nonatomic) PFObject *currentDish;
@property (strong, nonatomic) PFObject *currentCourse;
@property (strong, nonatomic) PFObject *currentOrder;

@end
