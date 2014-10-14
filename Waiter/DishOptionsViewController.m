//
//  DishOptionsViewController.m
//  Waiter
//
//  Created by Dylan Lewis on 26/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "DishOptionsViewController.h"
#import "DishOptionsTableViewCell.h"
#import "UIColor+ApplicationColours.h"

@interface DishOptionsViewController ()

@property (strong, nonatomic) NSDictionary *options;

@property (strong, nonatomic) NSMutableArray *nonAcceptedDishOrderItems;
@property (strong, nonatomic) NSMutableDictionary *orderedOptionsAndQuantities;
@property (strong, nonatomic) NSArray *orderedObjects;

@property (strong, nonatomic) NSArray *optionNames;

@end

@implementation DishOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self getOrderItems];
    
    self.title = _currentDish[@"name"];
    
    // Store the dish's options in a dictionary.
    _options = [[NSDictionary alloc] initWithDictionary:_currentDish[@"options"]];
    
    // Extract the different option names from the dictionary.
    _optionNames = [[NSArray alloc] initWithArray:[_options allKeys]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button handling

- (IBAction)didTouchCancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTouchSelectOptionButton:(id)sender {
    DishOptionsTableViewCell *touchedCell = (DishOptionsTableViewCell *)[[sender superview] superview];
    
    PFObject *orderItem = [touchedCell orderItemObject];
    
    // Check if the item has been ordered already, and that that item hasn't been seen by the kitchen.
    if (touchedCell.isEditable) {
        [self incrementQuantityOfOrderItem:orderItem];
    } else {
        NSString *selectedOptionName = touchedCell.optionNameLabel.text;
        NSDictionary *option = [[NSDictionary alloc] initWithObjectsAndKeys:[_options valueForKey:selectedOptionName], selectedOptionName, nil];
        
        [self addOrderItemToOrderWithOption:option];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Make this select the option too.
}

#pragma mark - Table view

- (DishOptionsTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"optionCell";
    
    DishOptionsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSString *option = [_optionNames objectAtIndex:indexPath.row];
    
    // Store the option name in an attribtued string.
    NSMutableAttributedString *optionName = [[NSMutableAttributedString alloc] initWithString:option];
    [optionName addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f] range:NSMakeRange(0, [optionName length])];
    
    // If the option has been ordered, set the text colour to blue.
    if ([[_orderedOptionsAndQuantities allKeys] containsObject:option]) {
        [optionName addAttribute:NSForegroundColorAttributeName value:[UIColor kitchenBlueColour] range:NSMakeRange(0, [optionName length])];
    }
    
    // Work out whether the Order Item is editable or not.
    BOOL isEditable = NO;
    NSInteger editableQuantity = 0;
    NSInteger alreadySeenQuantity = 0;
    NSInteger totalQuantityForDish = 0;
    
    // Use the option name to get the total quantity (total ordered, new + accepted) of this option.
    totalQuantityForDish = [[_orderedOptionsAndQuantities valueForKey:option] integerValue];
    
    // See if there is a current order item (i.e. editable) for this dish.
    for (PFObject *orderItem in _nonAcceptedDishOrderItems) {
        NSDictionary *optionKeyValuePair = [[NSDictionary alloc] initWithDictionary:orderItem[@"option"]];
        NSString *optionNameForOrderItem = [[optionKeyValuePair allKeys] firstObject];
        
        if ([optionNameForOrderItem isEqualToString:option]) {
            // This means the current quantity can be edited.
            isEditable = YES;
            
            // Store the quantity of dishes that are editable (haven't been accepted by the kitchen).
            editableQuantity = [orderItem[@"quantity"] integerValue];
            
            // Set the order item object attatched to this cell be the one which can be edited.
            cell.orderItemObject = orderItem;
            
            break;
        }
    }
    
    // Calculate the number of dishes that the kitchen has already seen.
    alreadySeenQuantity = totalQuantityForDish  - editableQuantity;
    
    // Set basic variables.
    cell.optionNameLabel.attributedText = optionName;
    cell.optionPriceLabel.text = [NSString stringWithFormat:@"£%@", [_options valueForKey:option]];
    cell.isEditable = isEditable;
    
    // Hide the already seen label if no dishes have been accepted yet.
    if (alreadySeenQuantity==0) {
        [cell.alreadySeenLabel setHidden:YES];
    } else {
        [cell.alreadySeenLabel setHidden:NO];
    }
    
    // Display labels depending on whether or not the dish is editable.
    if (isEditable) {
        [cell.dishOptionQuantityLabel setHidden:NO];
        cell.dishOptionQuantityLabel.text = [NSString stringWithFormat:@"%ld x", (long)editableQuantity];
        cell.alreadySeenLabel.text = [NSString stringWithFormat:@"+ %ld already accepted (%ld total)", alreadySeenQuantity, totalQuantityForDish];
    } else {
        [cell.dishOptionQuantityLabel setHidden:YES];
        cell.alreadySeenLabel.text = [NSString stringWithFormat:@"%ld already accepted", totalQuantityForDish];
    }

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_optionNames count];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

#pragma mark - Parse

- (void)addOrderItemToOrderWithOption:(NSDictionary *)option {
    // The Option hasn't been ordered before, so create the object.
    PFObject *orderItem = [PFObject objectWithClassName:@"OrderItem"];
    orderItem[@"quantity"]=@1;
    
    // Relate this dish order to the dish and order objects.
    orderItem[@"whichDish"] = _currentDish;
    orderItem[@"name"] = [_currentDish valueForKey:@"name"];
    orderItem[@"type"] = [_currentDish valueForKey:@"type"];
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
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)incrementQuantityOfOrderItem:(PFObject *)orderedItem {
    // The item has already been ordered, so just update the quantity.
    orderedItem[@"quantity"] = [NSNumber numberWithInt:[[orderedItem valueForKey:@"quantity"] intValue] + 1];
    
    [orderedItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // Tell the View Order scene to reload its data.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addedItemToOrder" object:nil];
                
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)getOrderItems {
    PFQuery *getOrderItems = [PFQuery queryWithClassName:@"OrderItem"];
    [getOrderItems whereKey:@"forOrder" equalTo:_currentOrder];
    [getOrderItems whereKey:@"course" equalTo:[_currentCourse valueForKey:@"name"]];
    [getOrderItems whereKey:@"name" equalTo:[_currentDish valueForKey:@"name"]];
    
    [getOrderItems findObjectsInBackgroundWithBlock:^(NSArray *orderItems, NSError *error) {
        if (!error) {
            // Create an array of all order items for this course.
            _orderedOptionsAndQuantities = [[NSMutableDictionary alloc] init];
            _nonAcceptedDishOrderItems = [[NSMutableArray alloc] init];
            
            for (PFObject *orderItem in orderItems) {
                NSDictionary *optionKeyValuePair = [[NSDictionary alloc] initWithDictionary:orderItem[@"option"]];
                NSString *optionName = [[optionKeyValuePair allKeys] firstObject];
                
                // Check if this is a non-accepted (i.e. editable) order item.
                if ([orderItem[@"state"] isEqualToString:@"new"] || [orderItem[@"state"] isEqualToString:@"delivered"]) {
                    [_nonAcceptedDishOrderItems addObject:orderItem];
                }
                
                // Calculate the total quantity of each ordered option.
                if ([[_orderedOptionsAndQuantities allKeys] containsObject:optionName]) {
                    // This means more than one order item exists for this option.
                    
                    NSInteger currentQuantity = [[_orderedOptionsAndQuantities valueForKey:optionName] integerValue];
                    NSInteger newQuantity = currentQuantity + [orderItem[@"quantity"] integerValue];
                    NSNumber *quantity = [[NSNumber alloc] initWithInteger:newQuantity];
                    
                    [_orderedOptionsAndQuantities removeObjectForKey:optionName];
                    [_orderedOptionsAndQuantities setObject:quantity forKey:optionName];
                } else {
                    // This is the first occurence of this option and dish name, so add the quantity to the dictionary..
                    [_orderedOptionsAndQuantities setObject:orderItem[@"quantity"] forKey:optionName];
                }
            }
            
            [self.tableView reloadData];
        }
    }];
}


@end
