//
//  DiscountsViewController.h
//  Waiter
//
//  Created by Dylan Lewis on 04/10/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface DiscountsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    __weak IBOutlet UITableView *discountsTableView;
}

@property (strong, nonatomic) PFObject *currentOrder;

@property (strong, nonatomic) NSArray *selectedItems;

@end
