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

@property (strong, nonatomic) MenuDishesTableViewCell *touchedCell;
@property (strong, nonatomic) MenuDishesOptionsTableViewCell *touchedOptionCell;

@property (strong, nonatomic) NSMutableDictionary *orderedItemsAndQuantities;
@property (strong, nonatomic) NSMutableArray *nonAcceptedDishOrderItems;

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

    if (_touchedCell.isEditable) {
        // This means the previously ordered item hasn't been accepted by the kitchen yet, so we can change its quantity.
        
        PFObject *orderItem = [_touchedCell orderItemObject];
        
        orderItem[@"quantity"] = [NSNumber numberWithInt:[[orderItem valueForKey:@"quantity"] intValue] + 1];
        
        [orderItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self getParseData];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"addedItemToOrder" object:nil];
        }];
    } else {
        // The dish has either not been ordered yet or it has already been accepted by the kitchen, so we must make a new object.
        
        PFObject *dish = [_touchedCell dishObject];
        
        [dish fetchIfNeededInBackgroundWithBlock:^(PFObject *dishObject, NSError *error) {
            // Check if the dish has options.
            if ([[dishObject[@"options"] allKeys] count]==0) {
                // If the item has already been ordered, increment the quantity.
                
                [self addOrderItemToOrderForDish:dishObject];
            } else {
                // The dish has various options, so present them.
                
                [self performSegueWithIdentifier:@"selectOptionSegue" sender:nil];
            }
        }];
    }
}

- (IBAction)minusDishButtonTouched:(id)sender {
    // Get the cell that was just touched.
    _touchedCell = (MenuDishesTableViewCell *)[[sender superview] superview];
    
    if (_touchedCell.isEditable) {
        // The cell is editable, so we can decrement the quantity.
        
        PFObject *orderItem = [_touchedCell orderItemObject];
        
        // If the quantity is one, delete the object.
        if ([[orderItem valueForKey:@"quantity"] isEqual:@1]) {
            [orderItem deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [self getParseData];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"addedItemToOrder" object:nil];
            }];
        } else {
            // Decrement the quantity.
            orderItem[@"quantity"] = [NSNumber numberWithInt:[[orderItem valueForKey:@"quantity"] intValue] - 1];
            
            [orderItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [self getParseData];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"addedItemToOrder" object:nil];
            }];
        }
    }
}

- (IBAction)optionPlusButtonTouched:(id)sender {
    // This happens when the user touches the 'plus' of an option, as opposed to an Order Item. Increment the quantity.
    
    // Get the cell that the button was touched on.
    _touchedOptionCell = (MenuDishesOptionsTableViewCell *)[[sender superview] superview];
    
    PFObject *orderItem = [_touchedOptionCell orderItemObject];
    
    if (_touchedOptionCell.isEditable) {
        // This means the previously ordered item hasn't been accepted by the kitchen yet, so we can change its quantity.
        
        orderItem[@"quantity"] = [NSNumber numberWithInt:[[orderItem valueForKey:@"quantity"] intValue] + 1];
        
        [orderItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self getParseData];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"addedItemToOrder" object:nil];
        }];
    } else {
        // The optioned dish has already been accepted, so we must make a new object.
        
        PFObject *dish = orderItem[@"whichDish"];
        
        [dish fetchIfNeededInBackgroundWithBlock:^(PFObject *dishObject, NSError *error) {
            [self addOrderItemToOrderWithDish:dishObject withOption:orderItem[@"option"]];
        }];

    }
}

- (IBAction)optionMinusButtonTouched:(id)sender {
    // If the user sets the quantity to zero for this option, delete it from the order.
    _touchedOptionCell = (MenuDishesOptionsTableViewCell *)[[sender superview] superview];
    
    if (_touchedOptionCell.isEditable) {
        // The cell is editable, so we can decrement the quantity.
        
        PFObject *orderItem = [_touchedOptionCell orderItemObject];
        
        // Safety check that this item can be edited.
        if ([orderItem[@"state"] isEqualToString:@"new"] || [orderItem[@"state"] isEqualToString:@"delivered"]) {
            // If the quantity is one, delete the object.
            if ([[orderItem valueForKey:@"quantity"] isEqual:@1]) {
                [orderItem deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [self getParseData];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"addedItemToOrder" object:nil];
                }];
            } else {
                // Decrement the quantity.
                orderItem[@"quantity"] = [NSNumber numberWithInt:[[orderItem valueForKey:@"quantity"] intValue] - 1];
                
                [orderItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [self getParseData];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"addedItemToOrder" object:nil];
                }];
            }
        }
    }
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

- (void)addOrderItemToOrderWithDish:(PFObject *)dish withOption:(NSDictionary *)option {
    // The Option hasn't been ordered before, so create the object.
    PFObject *orderItem = [PFObject objectWithClassName:@"OrderItem"];
    orderItem[@"quantity"]=@1;
    
    // Relate this dish order to the dish and order objects.
    orderItem[@"whichDish"] = dish;
    orderItem[@"name"] = [dish valueForKey:@"name"];
    orderItem[@"type"] = [dish valueForKey:@"type"];
    orderItem[@"forOrder"] = _currentOrder;
    orderItem[@"option"] = option;
    orderItem[@"price"] = [[option allValues] firstObject];
    orderItem[@"state"] = @"new";
    orderItem[@"tableNumber"] = _currentOrder[@"tableNumber"];
    
    orderItem[@"course"] = [_currentCourse valueForKey:@"name"];
    
    // Add ACL permissions for added security.
    PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
    [orderItem setACL:acl];
    
    [orderItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
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
        // Store the retrieved objects locally.
        _objects = [[NSMutableArray alloc] initWithArray:orderItems];
        
        // Get the already ordered items for this course.
        [self getOrderItems];
    }];
}

- (void)getOrderItems {
    _orderItemArray = nil;
    
    PFQuery *getOrderItems = [PFQuery queryWithClassName:@"OrderItem"];
    [getOrderItems whereKey:@"forOrder" equalTo:_currentOrder];
    [getOrderItems whereKey:@"course" equalTo:[_currentCourse valueForKey:@"name"]];
    
    [getOrderItems findObjectsInBackgroundWithBlock:^(NSArray *orderItems, NSError *error) {
        if (!error) {
            // Create an array of all order items for this course.
            _orderItemArray = [[NSArray alloc] initWithArray:orderItems];
            _orderedItemsAndQuantities = [[NSMutableDictionary alloc] init];
            _nonAcceptedDishOrderItems = [[NSMutableArray alloc] init];
            
            #warning slight bug where it adds two entries of customised objects after updating quantity.
            
            // Go through each ordered item object.
            for (PFObject *orderItem in _orderItemArray) {
                // Check if this is a non-accepted (i.e. editable) order item.
                if ([orderItem[@"state"] isEqualToString:@"new"] || [orderItem[@"state"] isEqualToString:@"delivered"]) {
                    [_nonAcceptedDishOrderItems addObject:orderItem];
                }
                
                NSString *fullItemName = [self fullDishNameWithOptionForOrderItem:orderItem];
                
                // Calculate the total quantity of each ordered item.
                if ([[_orderedItemsAndQuantities allKeys] containsObject:fullItemName]) {
                    // This means more than one order item exists for this combination of option and dish name.
                    
                    NSInteger currentQuantity = [[_orderedItemsAndQuantities valueForKey:fullItemName] integerValue];
                    NSInteger newQuantity = currentQuantity + [orderItem[@"quantity"] integerValue];
                    NSNumber *quantity = [[NSNumber alloc] initWithInteger:newQuantity];
                    
                    [_orderedItemsAndQuantities removeObjectForKey:fullItemName];
                    [_orderedItemsAndQuantities setObject:quantity forKey:fullItemName];
                } else {
                    // This is the first occurence of this option and dish name, so add the quantity to the dictionary..
                    [_orderedItemsAndQuantities setObject:orderItem[@"quantity"] forKey:fullItemName];
                    
                    // Insert this orderItem object into the _objects array, right after its parent Dish object.
                    NSInteger currentIndex = 0;
                    
                    // Go through each of the dish objects for this course.
                    for (PFObject *dish in _objects) {
                        currentIndex++;
                        
                        // If the current dish object matches the current order item object...
                        if ([dish[@"name"] isEqualToString:orderItem[@"name"]]) {
                            // Add the customised order item into the array, at the parent dish object position + 1
                            [_objects insertObject:orderItem atIndex:currentIndex];
                            
                            // If the dish has no options, given that we know it has been ordered, replace it in the array with the order item object.
                            if ([[dish[@"options"] allKeys] count]==0) {
                                [_objects removeObject:dish];
                            }
                            
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
    
    // There are four possibilities for cells in this table:
    // - ORDER ITEM with OPTIONS: a dish with options has been ordered, and this cell represents the ordered option. (blue, indented text)
    // - ORDER ITEM without OPTIONS: a plain dish that has no options has been ordered. (blue, unindented text).
    // - DISH with OPTIONS: a dish that has not been ordered (green, unindented text).
    // - DISH without OPTIONS: a dish that has not been ordered that will display options upon ordering.
    
    // Get the object from the array.
    PFObject *currentObject = [_objects objectAtIndex:[indexPath row]];
    
    // Check if this is a Dish object or an Order Item object (only Order Item objects will have an estimatedCompletionTime).
    if ([[currentObject allKeys] containsObject:@"tableNumber"]) {
        // ORDER ITEM CELL
        
        // Work out whether the Order Item is editable or not.
        BOOL isEditable = NO;
        NSInteger editableQuantity = 0;
        NSInteger alreadySeenQuantity = 0;
        NSInteger totalQuantityForDish = 0;
        
        // Use the concatenated dish name to get the total quantity (total ordered, new + accepted) of this dish option.
        NSString *fullDishName = [self fullDishNameWithOptionForOrderItem:currentObject];
        totalQuantityForDish = [[_orderedItemsAndQuantities valueForKey:fullDishName] integerValue];
        
        // See if there is a current order item (i.e. editable) for this dish.
        for (PFObject *orderItem in _nonAcceptedDishOrderItems) {
            NSString *fullDishNameForOrderItem = [self fullDishNameWithOptionForOrderItem:orderItem];
            
            if ([fullDishNameForOrderItem isEqualToString:fullDishName]) {
                // This means the current quantity can be edited.
                isEditable = YES;
                
                // Store the quantity of dishes that are editable (haven't been accepted by the kitchen).
                editableQuantity = [orderItem[@"quantity"] integerValue];
                
                // Set the order item object attatched to this cell be the one which can be edited.
                currentObject = orderItem;
                
                break;
            }
        }
        
        // Calculate the number of dishes that the kitchen has already seen.
        alreadySeenQuantity = totalQuantityForDish  - editableQuantity;
        
        // Work out if this is a pure Dish Order Item or an Optioned Dish Order Item.
        if (currentObject[@"option"]) {
            // ORDER ITEM CELL with OPTIONS
            
            MenuDishesOptionsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:OptionCellIdentifier];
            
            // Update the dish name label.
            NSMutableAttributedString *dishString = [[NSMutableAttributedString alloc] initWithString:[[currentObject[@"option"] allKeys] firstObject]];
            [dishString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f] range:NSMakeRange(0, [dishString length])];
            
            // Set basic variables.
            cell.dishNameLabel.attributedText = dishString;
            cell.priceLabel.text = [NSString stringWithFormat:@"£%@", [currentObject[@"option"] valueForKey:cell.dishNameLabel.text]];
            cell.orderItemObject = currentObject;
            cell.isEditable = isEditable;
            
            // Hide the already seen label if no dishes have been accepted yet.
            if (alreadySeenQuantity==0) {
                [cell.alreadySeenLabel setHidden:YES];
            }
            
            // Display labels depending on whether or not the dish is editable.
            if (isEditable) {
                [cell.quantityLabel setHidden:NO];
                [cell.minusButton setEnabled:YES];
                cell.quantityLabel.text = [NSString stringWithFormat:@"%ld x", (long)editableQuantity];
                cell.alreadySeenLabel.text = [NSString stringWithFormat:@"+ %ld already accepted (%ld total)", alreadySeenQuantity, totalQuantityForDish];
            } else {
                [cell.quantityLabel setHidden:YES];
                [cell.minusButton setEnabled:NO];
                cell.alreadySeenLabel.text = [NSString stringWithFormat:@"%ld already accepted", totalQuantityForDish];
            }
            
            return cell;
        } else {
            // ORDER ITEM CELL without OPTIONS
            
            MenuDishesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            NSMutableAttributedString *dishString = [[NSMutableAttributedString alloc] initWithString:currentObject[@"name"]];
            [dishString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:18.0f] range:NSMakeRange(0, [dishString length])];
            [dishString addAttribute:NSForegroundColorAttributeName value:[UIColor kitchenBlueColour] range:NSMakeRange(0, [dishString length])];
            
            // Set basic variables.
            cell.dishNameLabel.attributedText = dishString;
            cell.dishPriceLabel.text = [NSString stringWithFormat:@"£%@", currentObject[@"price"]];
            cell.dishObject = currentObject[@"whichDish"];
            cell.orderItemObject = currentObject;
            cell.isEditable = isEditable;
            [cell.fromLabel setHidden:YES];
            
            // Hide the already seen label if no dishes have been accepted yet.
            if (alreadySeenQuantity==0) {
                [cell.alreadySeenLabel setHidden:YES];
            }
                        
            // Display labels and buttons depending on whether or not the dish is editable.
            if (isEditable) {
                [cell.dishQuantityLabel setHidden:NO];
                cell.dishQuantityLabel.text = [NSString stringWithFormat:@"%ld x", (long)editableQuantity];
                cell.alreadySeenLabel.text = [NSString stringWithFormat:@"+ %ld already accepted (%ld total)", alreadySeenQuantity, totalQuantityForDish];
            } else {
                [cell.dishQuantityLabel setHidden:YES];
                [cell.minusDishButton setEnabled:NO];
                cell.alreadySeenLabel.text = [NSString stringWithFormat:@"%ld already accepted", totalQuantityForDish];
            }

            return cell;
        }
    } else {
        // DISH CELL
        
        MenuDishesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        NSMutableAttributedString *dishString = [[NSMutableAttributedString alloc] initWithString:currentObject[@"name"]];
        [dishString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:18.0f] range:NSMakeRange(0, [dishString length])];
        
        // Set basic variables.
        cell.dishNameLabel.attributedText = dishString;
        cell.dishObject = currentObject;
        cell.isEditable = NO;
        [cell.dishQuantityLabel setHidden:YES];
        [cell.alreadySeenLabel setHidden:YES];
        [cell.minusDishButton setEnabled:NO];
        
        // Check if the Dish has options.
        if ([[cell.dishObject[@"options"] allKeys] count]==0) {
            // DISH CELL without OPTIONS
            
            cell.dishPriceLabel.text = [NSString stringWithFormat:@"£%@", [cell.dishObject valueForKey:@"price"]];
            [cell.fromLabel setHidden:YES];
        } else {
            // This DISH CELL with OPTIONS
            
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

#pragma mark - Other

- (NSString *)fullDishNameWithOptionForOrderItem:(PFObject *)orderItem {
    // If the order item is customised, concatenate the option name with the dish name.
    if ([[orderItem valueForKey:@"option"] count] > 0) {
        NSString *optionName = [[orderItem[@"option"] allKeys] firstObject];
        return [NSString stringWithFormat:@"%@ %@", optionName, orderItem[@"name"]];
    } else {
        return orderItem[@"name"];
    }
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
