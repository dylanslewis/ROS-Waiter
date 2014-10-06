//
//  ReservationsViewController.h
//  Waiter
//
//  Created by Dylan Lewis on 21/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ReservationsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    __weak IBOutlet UITableView *reservationsTableView;
}

@end
