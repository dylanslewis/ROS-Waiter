//
//  MenuDishesViewController.h
//  Waiter
//
//  Created by Dylan Lewis on 22/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <Parse/Parse.h>

@interface MenuDishesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    __weak IBOutlet UITableView *dishesTableView;
}

@property (strong, nonatomic) PFObject *currentCourse;
@property (strong, nonatomic) PFObject *currentOrder;

- (void)addOrderItemToOrderForDish:(PFObject *)dish;

- (void)addOrderItemToOrderWithDish:(PFObject *)dish withOption:(NSDictionary *)option;

@end
