//
//  ViewOrderViewController.h
//  Waiter
//
//  Created by Dylan Lewis on 10/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <Parse/Parse.h>

@interface ViewOrderViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate> {
    __weak IBOutlet UITableView *orderItemsTableView;
}

@property (strong, nonatomic) PFObject *currentOrder;

@end
