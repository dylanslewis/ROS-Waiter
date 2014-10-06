//
//  MenuCoursesViewController.h
//  Waiter
//
//  Created by Dylan Lewis on 19/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <Parse/Parse.h>

@interface MenuCoursesViewController : PFQueryTableViewController

@property (strong, nonatomic) PFObject *orderForMenu;

@end
