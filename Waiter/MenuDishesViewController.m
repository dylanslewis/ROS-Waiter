//
//  MenuDishesViewController.m
//  Waiter
//
//  Created by Dylan Lewis on 22/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "MenuDishesViewController.h"
#import "MenuDishesTableViewCell.h"
#import "DishOptionsViewController.h"
#import "MenuDishesOptionsTableViewCell.h"
#import "UIColor+ApplicationColours.h"

@interface MenuDishesViewController ()

@property (strong, nonatomic) NSArray *orderItemArray;
@property (strong, nonatomic) NSMutableArray *customisedOrderItems;

@property (strong, nonatomic) MenuDishesTableViewCell *touchedCell;

@property (strong, nonatomic) NSMutableArray *objects;

@end

@implementation MenuDishesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set the title to the current course name.
    self.title = [_currentCourse objectForKey:@"name"];
    
    // Listen for changes to the order.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getParseData) name:@"addedItemToOrder" object:nil];
    
    [self getParseData];
}

- (void)viewDidAppear:(BOOL)animated {
    // Get the current user.
    PFUser *user=[PFUser currentUser];
    
    // If there is no user logged in, return to the login screen.
    if (!user) {
        [self performSegueWithIdentifier:@"logoutUserSegue" sender:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setCurrentCourse:(PFObject *)currentCourse {
    _currentCourse = currentCourse;
}

- (void)setCurrentOrder:(PFObject *)currentOrder {
    _currentOrder = currentOrder;
}

#pragma mark - Button handling

- (IBAction)didTouchDoneButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)plusDishButtonTouched:(id)sender {
    // Get the cell that the button was touched on.
    _touchedCell = (MenuDishesTableViewCell *)[[sender superview] superview];
    
    PFObject *object = [_touchedCell dishObject];
    
    if ([[object[@"options"] allKeys] count]==0) {
        // If the item has already been ordered, increment the quantity.
        if (_touchedCell.hasBeenOrdered) {
            PFObject *orderItem = [_touchedCell orderItemObject];
            
            orderItem[@"quantity"] = [NSNumber numberWithInt:[[orderItem valueForKey:@"quantity"] intValue] + 1];
            
            [orderItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [self getParseData];
            }];
        } else {
            // If the item hasn't been ordered yet, create a new orderItem object.
            [self addOrderItemToOrderForDish:[_touchedCell dishObject]];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addedItemToOrder" object:nil];
    } else {
        // The dish has various options, so we present them.
        [self performSegueWithIdentifier:@"selectOptionSegue" sender:nil];
    }
}

- (IBAction)minusDishButtonTouched:(id)sender {
    // Get the cell that was just touched.
    _touchedCell = (MenuDishesTableViewCell *)[[sender superview] superview];
    
    // Safety check.
    if (_touchedCell.hasBeenOrdered) {
        PFObject *orderItem = [_touchedCell orderItemObject];
        
        // If the quantity is one, delete the object.
        if ([[orderItem valueForKey:@"quantity"] isEqual:@1]) {
            [orderItem deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [self getParseData];
            }];
            
            ////
            // Delete any discounts associated with this item.
            ////
            
        } else {
            // Decrement the quantity.
            orderItem[@"quantity"] = [NSNumber numberWithInt:[[orderItem valueForKey:@"quantity"] intValue] - 1];
            
            [orderItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [self getParseData];
            }];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addedItemToOrder" object:nil];
    }
}

- (IBAction)optionPlusButtonTouched:(id)sender {
    // This happens when the user touches the 'plus' of an option, as opposed to an Order Item. Increment the quantity.
    
    // Get the cell that the button was touched on.
    _touchedCell = (MenuDishesTableViewCell *)[[sender superview] superview];
    
    PFObject *orderItem = [_touchedCell orderItemObject];
    
    orderItem[@"quantity"] = [NSNumber numberWithInt:[[orderItem valueForKey:@"quantity"] intValue] + 1];
    
    [orderItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [self getParseData];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"addedItemToOrder" object:nil];
}

- (IBAction)optionMinusButtonTouched:(id)sender {
    // If the user sets the quantity to zero for this option, delete it from the order.
    _touchedCell = (MenuDishesTableViewCell *)[[sender superview] superview];
    
    // Safety check.
    PFObject *orderItem = [_touchedCell orderItemObject];
    
    // If the quantity is one, delete the object.
    if ([[orderItem valueForKey:@"quantity"] isEqual:@1]) {
        [orderItem deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self getParseData];
        }];
        
        // Delete any discounts associated with this item.

    } else {
        // Decrement the quantity.
        orderItem[@"quantity"] = [NSNumber numberWithInt:[[orderItem valueForKey:@"quantity"] intValue] - 1];
        
        [orderItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self getParseData];
        }];
    }
    
    // Update View Order UI.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"addedItemToOrder" object:nil];
}


#pragma mark - Parse

- (void)addOrderItemToOrderForDish:(PFObject *)dish {
    PFObject *orderItem = [PFObject objectWithClassName:@"OrderItem"];
    orderItem[@"quantity"]=@1;
    
    // Relate this dish order to the dish and order objects.
    orderItem[@"whichDish"] = dish;
    orderItem[@"name"] = [dish valueForKey:@"name"];
    orderItem[@"type"] = [dish valueForKey:@"type"];
    orderItem[@"forOrder"] = _currentOrder;
    orderItem[@"price"] = [dish valueForKey:@"price"];
    orderItem[@"state"] = @"new";
    orderItem[@"tableNumber"] = _currentOrder[@"tableNumber"];
    
    orderItem[@"course"] = [_currentCourse valueForKey:@"name"];
    
    // Add ACL permissions for added security.
    PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
    [orderItem setACL:acl];
    
    [orderItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // Refetch the order items.
        [self getParseData];
        
        // Tell the View Order scene to reload its data.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addedItemToOrder" object:nil];
    }];
}

// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (void)getParseData {
    PFQuery *query = [PFQuery queryWithClassName:@"Dish"];
    [query whereKey:@"ofCourse" equalTo:_currentCourse];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [query orderByAscending:@"name"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *orderItems, NSError *error) {
        // Get the already ordered items for this course.
        [self getOrderItems];
        
        // Store the retrieved objects locally.
        _objects = [[NSMutableArray alloc] initWithArray:orderItems];
    }];
}

- (void)getOrderItems {
    _orderItemArray = nil;
    _customisedOrderItems = nil;
    
    PFQuery *getOrderItems = [PFQuery queryWithClassName:@"OrderItem"];
    [getOrderItems whereKey:@"forOrder" equalTo:_currentOrder];
    [getOrderItems whereKey:@"course" equalTo:[_currentCourse valueForKey:@"name"]];
    
    [getOrderItems findObjectsInBackgroundWithBlock:^(NSArray *orderItems, NSError *error) {
        if (!error) {
            // Create an array of all order items for this course.
            _orderItemArray = [[NSArray alloc] initWithArray:orderItems];
            
            _customisedOrderItems = [[NSMutableArray alloc] init];
            
            #warning slight bug where it adds two entries of customised objects after updating quantity.
            
            // Store all customised items in a separate array.
            for (PFObject *orderItem in _orderItemArray) {
                // If the order item is customised...
                if ([[orderItem valueForKey:@"option"] count] > 0) {
                    [_customisedOrderItems addObject:orderItem];
                    
                    NSInteger currentIndex = 0;
                    
                    // Go through each of the dish objects for this course.
                    for (PFObject *dish in _objects) {
                        currentIndex++;
                        
                        // If the current dish object matches the current order item object...
                        if ([dish[@"name"] isEqualToString:orderItem[@"name"]]) {
                            // Add the customised order item into the array, at the parent dish object position + 1
                            [_objects insertObject:orderItem atIndex:currentIndex];
                            
                            break;
                        }
                    }
                }
            }
            
            // Update table.
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"dishCell";
    static NSString *OptionCellIdentifier = @"dishOptionCell";
    
    // There are three posibilities for cells in this table:
    // - Dish object: an item on the menu that hasn't been ordered, shown in green.
    // - Order Item object: an item on the menu that HAS been ordered, shown in blue
    // - Order Item Option: an option of a Dish that has been ordered, also shown in blue.
    
    // Get the object from the array.
    PFObject *currentObject = [_objects objectAtIndex:[indexPath row]];
    
    // Check if this is a dish object or an order item object.
    if (currentObject[@"quantity"] > 0) {
        // This is a pure option cell, that shows no dish name, just the option name (indented).
        MenuDishesOptionsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:OptionCellIdentifier];
        
        // Update the dish name label.
        NSMutableAttributedString *dishString = [[NSMutableAttributedString alloc] initWithString:[[currentObject[@"option"] allKeys] firstObject]];
        [dishString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f] range:NSMakeRange(0, [dishString length])];
        
        // Set the cell's values.
        cell.dishOptionNameLabel.attributedText = dishString;
        cell.priceLabel.text = [NSString stringWithFormat:@"£%@", [currentObject[@"option"] valueForKey:cell.dishOptionNameLabel.text]];
        cell.quantityLabel.text = [NSString stringWithFormat:@"%@ x", currentObject[@"quantity"]];
        
        cell.orderItemObject = currentObject;
        
        return cell;
    } else {
        // This is a dish cell.
        MenuDishesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        [cell.minusDishButton setEnabled:NO];
        
        // Store the object.
        cell.dishObject = [_objects objectAtIndex:indexPath.row];
        
        NSMutableAttributedString *dishString = [[NSMutableAttributedString alloc] initWithString:[cell.dishObject valueForKey:@"name"]];
        [dishString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:18.0f] range:NSMakeRange(0, [dishString length])];
        
        // Check to see if this dish, or its options, have been ordered.
        for (PFObject *orderItem in _orderItemArray) {
            if ([orderItem[@"name"] isEqualToString:[dishString string]]) {
                [dishString addAttribute:NSForegroundColorAttributeName value:[UIColor kitchenBlueColour] range:NSMakeRange(0, [dishString length])];
            }
        }
        
        // Configure the cell
        cell.dishNameLabel.attributedText = dishString;
        cell.dishQuantityLabel.text = @"";
        
        // Check if the Dish has options.
        if ([[cell.dishObject[@"options"] allKeys] count]==0) {
            // This dish cell doesn't have options.
            cell.dishPriceLabel.text = [NSString stringWithFormat:@"£%@", [cell.dishObject valueForKey:@"price"]];
            [cell.fromLabel setHidden:YES];
            
            // Look to see if an Order Item object appears for this dish.
            for (PFObject *orderItem in _orderItemArray) {
                if ([[orderItem valueForKey:@"name"] isEqual:[cell.dishObject valueForKey:@"name"]]) {
                    // This means the item has been ordered, so we need to update the corresponding labels.
                    cell.dishQuantityLabel.text = [NSString stringWithFormat:@"%@ x", [orderItem valueForKey:@"quantity"]];
                    
                    cell.orderItemObject = orderItem;
                    cell.hasBeenOrdered = YES;
                    [cell.minusDishButton setEnabled:YES];
                    
                    break;
                }
            }
        } else {
            // This dish has options.
            [cell.fromLabel setHidden:NO];
            
            NSDictionary *options = [[NSDictionary alloc] initWithDictionary:cell.dishObject[@"options"]];
            
            NSNumber *lowestPrice = @-1;
            
            // Find the lowest priced option.
            for (NSString *option in [options allKeys]) {
                NSNumber *currentOptionPrice = [options valueForKey:option];
                
                if ([lowestPrice doubleValue] == -1) {
                    lowestPrice = currentOptionPrice;
                } else if ([currentOptionPrice doubleValue] < [lowestPrice doubleValue]) {
                    lowestPrice = currentOptionPrice;
                }
            }
            
            cell.dishPriceLabel.text = [NSString stringWithFormat:@"£%@", lowestPrice];;
        }
        
        return cell;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_objects count];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"selectOptionSegue"]) {
        // Retrieve the PFObject from the cell.
        PFObject *dish=[_touchedCell dishObject];
        
        // Pass the PFObject to the next scene.
        DishOptionsViewController *vc = (DishOptionsViewController *)[[segue destinationViewController] topViewController];
        [vc setCurrentDish:dish];
        [vc setCurrentCourse:_currentCourse];
        [vc setCurrentOrder:_currentOrder];
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    // This stops the button automatically logging out the user, without checking confirmation.
    if ([identifier isEqualToString:@"logoutUserSegue"]) {
        return NO;
    } else if ([identifier isEqualToString:@"selectOptionSegue"]) {
        return NO;
    }
    return YES;
}


@end
