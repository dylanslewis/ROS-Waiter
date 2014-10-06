//
//  OrdersViewController.m
//  Waiter
//
//  Created by Dylan Lewis on 10/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "OrdersViewController.h"
#import "ViewOrderViewController.h"
#import "OrdersCollectionViewCell.h"

@interface OrdersViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addOrderButton;

@property (strong, nonatomic) PFObject *currentWaiter;

@property (strong, nonatomic) UIAlertView *alertView;

@property (strong, nonatomic) NSString *className;

@property (strong, nonatomic) NSArray *ordersArray;

@end

@implementation OrdersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set the class name for this View.
    _className = @"Order";
    
    // Initially hide the table view, until objects are retrieved.
    [ordersCollectionView setHidden:YES];
    [ordersCollectionView setAllowsMultipleSelection:NO];
    
    // Initially disable the add order button, until we know we have a waiter logged in.
    [_addOrderButton setEnabled:NO];
    
    // Listen to updates about the current waiter.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUIForWaiter) name:@"newWaiterLoggedIn" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getParseData) name:@"orderChange" object:nil];
    
    [self updateUIForWaiter];
}

- (void)updateUIForWaiter {
    // Get the currently logged in Waiter's ID.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *currentWaiterID = [defaults valueForKey:@"currentWaiterID"];
    
    // Get the current waiter's object, and update UI.
    if (currentWaiterID) {
        PFQuery *query = [PFQuery queryWithClassName:@"Waiter"];
        [query getObjectInBackgroundWithId:currentWaiterID
                                     block:^(PFObject *waiterObject, NSError *error) {
                                         if (!error) {
                                             _currentWaiter = waiterObject;
                                             
                                             self.title = [NSString stringWithFormat:@"%@'s Orders", [_currentWaiter valueForKey:@"firstName"]];
                                             
                                             [_addOrderButton setEnabled:YES];
                                             
                                             // Once we have confirmed there is a logged in waiter, get their orders.
                                             [self getParseData];
                                         }
                                     }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getParseData {
    PFQuery *getOrders = [PFQuery queryWithClassName:_className];
    [getOrders whereKey:@"forWaiter" equalTo:_currentWaiter];
    [getOrders whereKey:@"state" notEqualTo:@"paid"];
    
    [getOrders findObjectsInBackgroundWithBlock:^(NSArray *orders, NSError *error) {
        if (!error) {
            _ordersArray = [[NSArray alloc] initWithArray:orders];
        } else {
            NSLog(@"%@", error);
        }
        
        // Only show the table view if there are objects to display.
        if ([_ordersArray count]) {
            [ordersCollectionView setHidden:NO];
            [ordersCollectionView reloadData];
        } else {
            [ordersCollectionView setHidden:YES];
        }
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_ordersArray count];
}

- (void)viewDidAppear:(BOOL)animated {
    // Get the current user.
    PFUser *user=[PFUser currentUser];
    
    // If there is no user logged in, return to the login screen.
    if (!user) {
        [self performSegueWithIdentifier:@"logoutUserSegue" sender:nil];
    }
}

#pragma mark - Button handling

- (IBAction)touchCreateOrderButton:(id)sender {    
    [self displayTextInputAlertWithTitle:@"Create new order" withMessage:@"Enter the table number for this order" withPlaceholder:@"table number"];
}


#pragma mark - Alert view handling

- (void)displayTextInputAlertWithTitle:(NSString *)title withMessage:(NSString *)message withPlaceholder:(NSString *)placeholder {
    _alertView=[[UIAlertView alloc] initWithTitle:title
                                          message:message
                                         delegate:self
                                cancelButtonTitle:@"Cancel"
                                otherButtonTitles:@"Create", nil];
    [_alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    
    UITextField *textField = [_alertView textFieldAtIndex:0];
    textField.placeholder = placeholder;
    
    // Validate inputs: only allow numbers.
    textField.keyboardType = UIKeyboardTypeNumberPad;
    
    // Display the alert.
    [_alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Create new order"]) {
        if (buttonIndex==1) {
            // Create the new order with the current time as orderDate.
            NSString *tableNumber = [_alertView textFieldAtIndex:0].text;
            
            [self createNewOrderWithTableNumber:tableNumber];
        }
    }
}


#pragma mark - Parse

- (void)createNewOrderWithTableNumber:(NSString *)tableNumber {
    PFObject *order = [PFObject objectWithClassName:_className];
    order[@"tableNumber"]=tableNumber;
    order[@"state"]=@"new";
    order[@"totalPrice"]=@0.00;
     
    // Relate this new order to the currently logged in Waiter.
    order[@"forWaiter"] = _currentWaiter;
    
    // Add ACL permissions for added security.
    PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
    [order setACL:acl];
    
    [order saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // Refresh the table when the object is done saving.
        [self getParseData];
        
        [self performSegueWithIdentifier:@"showOrderDetailsSegue" sender:order];
    }];
}


#pragma mark - Table view

- (OrdersCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"tableCell";
    
    PFObject *order = [_ordersArray objectAtIndex:indexPath.row];
    
    // Configure the cell
    OrdersCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        
    // Configure the cell
    cell.tableNumberLabel.text = [NSString stringWithFormat:@"%@", [order valueForKey:@"tableNumber"]];
    cell.orderStateLabel.text = @"order state";
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PFObject *object = [_ordersArray objectAtIndex:indexPath.row];
        [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self getParseData];
        }];
    }
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showOrderDetailsSegue"]) {
        // Retrieve the PFObject from the cell.
        PFObject *order;

        NSString *senderClass = [NSString stringWithFormat:@"%@", [sender class]];
        
        // Check if this is a segue performed automatically (by just creating the order object) or a manual transition.
        if ([senderClass isEqualToString:@"PFObject"]) {
            order = (PFObject *)sender;
        } else {
            NSIndexPath *indexPath = [[ordersCollectionView indexPathsForSelectedItems] firstObject];
            order=[_ordersArray objectAtIndex:indexPath.row];
        }
        
        // Pass the PFObject to the next scene.
        [[segue destinationViewController] setCurrentOrder:order];
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    // This stops the button automatically logging out the user, without checking confirmation.
    if ([identifier isEqualToString:@"logoutUserSegue"]) {
        return NO;
    }
    return YES;
}

@end