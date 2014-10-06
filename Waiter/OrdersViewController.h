//
//  OrdersViewController.h
//  Waiter
//
//  Created by Dylan Lewis on 10/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface OrdersViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate> {
    __weak IBOutlet UICollectionView *ordersCollectionView;
}
//<UITableViewDataSource, UITableViewDelegate> {
//    __weak IBOutlet UITableView *ordersTableView;
//}

@end