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

@property (strong, nonatomic) NSMutableDictionary *alreadyOrderedOptions;
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
    
    if ([touchedCell hasBeenOrdered]) {
        [self incrementQuantityOfOrderItem:touchedCell.orderItemObject];
    } else {
        NSString *selectedOptionName = touchedCell.optionNameLabel.text;
        
        NSDictionary *option = [[NSDictionary alloc] initWithObjectsAndKeys:[_options valueForKey:selectedOptionName], selectedOptionName, nil];
        
        [self addOrderItemToOrderWithOption:option];
    }
}

#pragma mark - Table view

- (DishOptionsTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"optionCell";
    
    DishOptionsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Store the option name in an attribtued string.
    NSMutableAttributedString *optionName = [[NSMutableAttributedString alloc] initWithString:[_optionNames objectAtIndex:indexPath.row]];
    [optionName addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f] range:NSMakeRange(0, [optionName length])];

    // Configure the cell
    cell.optionPriceLabel.text = [NSString stringWithFormat:@"£%@", [_options valueForKey:[_optionNames objectAtIndex:indexPath.row]]];
    
    // Check whether or not this option has been ordered already.
    if ([[_alreadyOrderedOptions allKeys] containsObject:[optionName string]]) {
        cell.hasBeenOrdered = YES;
        
        for (PFObject *orderedItem in _orderedObjects) {
            NSDictionary *option = orderedItem[@"option"];
            
            if ([[[option allKeys] firstObject] isEqualToString:[optionName string]]) {
                cell.orderItemObject = orderedItem;
                
                break;
            }
        }
        
        // Show the quantity.
        [cell.dishOptionQuantityLabel setHidden:NO];
        cell.dishOptionQuantityLabel.text = [NSString stringWithFormat:@"%@ x", [_alreadyOrderedOptions valueForKey:[optionName string]]];
        
        // Make the text blue.
        [optionName addAttribute:NSForegroundColorAttributeName value:[UIColor kitchenBlueColour] range:NSMakeRange(0, [optionName length])];
        
        cell.optionNameLabel.attributedText = optionName;
    } else {
        cell.hasBeenOrdered = NO;
        
        [cell.dishOptionQuantityLabel setHidden:YES];
        
        cell.optionNameLabel.attributedText = optionName;
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
    PFObject *orderItem = [PFObject objectWithClassName:@"OrderItem"];
    orderItem[@"quantity"]=@1;
    
    // Relate this dish order to the dish and order objects.
    orderItem[@"whichDish"] = _currentDish;
    orderItem[@"name"] = [_currentDish valueForKey:@"name"];
    orderItem[@"type"] = [_currentDish valueForKey:@"type"];
    orderItem[@"forOrder"] = _currentOrder;
    orderItem[@"option"] = option;
    orderItem[@"price"] = [[option allValues] firstObject];
    
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
            _alreadyOrderedOptions = [[NSMutableDictionary alloc] init];
            _orderedObjects = [[NSArray alloc] initWithArray:orderItems];
            
            for (PFObject *orderItem in orderItems) {
                NSDictionary *optionKeyValuePair = [[NSDictionary alloc] initWithDictionary:orderItem[@"option"]];
                [_alreadyOrderedOptions setObject:orderItem[@"quantity"] forKey:[[optionKeyValuePair allKeys] firstObject]];
            }
            
            [self.tableView reloadData];
        }
    }];
}

@end
