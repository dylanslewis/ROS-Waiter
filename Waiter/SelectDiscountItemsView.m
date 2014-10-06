//
//  SelectDiscountItemsView.m
//  Waiter
//
//  Created by Dylan Lewis on 04/10/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "SelectDiscountItemsView.h"
#import "SelectDiscountItemsTableViewCell.h"
#import "UIColor+ApplicationColours.h"

@interface SelectDiscountItemsView ()

@property (strong, nonatomic) NSArray *orderItems;
@property (strong, nonatomic) NSMutableDictionary *orderItemsByType;

@property (strong, nonatomic) NSMutableArray *selectedItems;

@end

@implementation SelectDiscountItemsView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Restore the previously selected items, if they exist.
    if (_previouslySelectedItems==nil) {
        _selectedItems = [[NSMutableArray alloc] init];
    } else {
        _selectedItems = [[NSMutableArray alloc] initWithArray:_previouslySelectedItems];
    }
    
    [self getParseData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button handling

- (IBAction)didTouchCancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTouchDoneButton:(id)sender {
    // Send the selectedItems array back to the previous scene.
    if ([_selectedItems count]>0) {
        NSArray *items = [[NSArray alloc] initWithArray:_selectedItems];
        
        // Pass the selected objects to the previous view.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didSelectItemsToDiscount" object:items];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view

- (SelectDiscountItemsTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"discountItemCell";
    
    NSString *keyForSection = [[_orderItemsByType allKeys] objectAtIndex:[indexPath section]];
    
    PFObject *orderItem = [[_orderItemsByType valueForKey:keyForSection] objectAtIndex:[indexPath row]];
    
    SelectDiscountItemsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Work out if the item has options.
    if ([[orderItem[@"option"] allKeys] count]>0) {
        // This means the order item has options.
        
        // Extract the option name.
        NSDictionary *optionKeyValuePair = [[NSDictionary alloc] initWithDictionary:orderItem[@"option"]];
        
        // Concatenate the option name string with the dish name string: Option DishName.
        NSString *concatenatedString = [NSString stringWithFormat:@"%@ %@", [[optionKeyValuePair allKeys] firstObject], [orderItem valueForKey:@"name"]];
        
        // Set basic attributes.
        NSMutableAttributedString *dishNameWithOption = [[NSMutableAttributedString alloc] initWithString:concatenatedString];
        [dishNameWithOption addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f] range:NSMakeRange(0, [dishNameWithOption length])];
        
        // Set the option name to blue.
        [dishNameWithOption addAttribute:NSForegroundColorAttributeName value:[UIColor kitchenBlueColour] range:NSMakeRange(0, [[[optionKeyValuePair allKeys] firstObject] length])];
        
        cell.dishNameLabel.attributedText = dishNameWithOption;
    } else {
        // The order item has no options.
        
        // Store the dish name in an attribtued string.
        NSMutableAttributedString *dishName = [[NSMutableAttributedString alloc] initWithString:[orderItem valueForKey:@"name"]];
        [dishName addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f] range:NSMakeRange(0, [dishName length])];
        
        cell.dishNameLabel.attributedText = dishName;
    }
    
    // Initially assume the item isn't checked.
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    // Look through the array of selected items, and update the UI to show which order items are selected.
    // THIS DOESN'T WORK!!!
    for (PFObject *selectedItem in _selectedItems) {
        if ([selectedItem isEqual:orderItem]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }

    cell.dishPriceLabel.text = [NSString stringWithFormat:@"£%@", [orderItem objectForKey:@"price"]];
    cell.dishQuantityLabel.text = [NSString stringWithFormat:@"%@ x", [orderItem objectForKey:@"quantity"]];

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *keyForSection = [[_orderItemsByType allKeys] objectAtIndex:[indexPath section]];
    PFObject *orderItem = [[_orderItemsByType valueForKey:keyForSection] objectAtIndex:[indexPath row]];
    
    // Add the item to the selected items array, or remove if it is already present.
    if ([_selectedItems containsObject:orderItem]) {
        [_selectedItems removeObject:orderItem];
    } else {
        NSLog(@"%@", orderItem);
        [_selectedItems addObject:orderItem];
    }
    
    [orderItemsTableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_orderItemsByType count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Get the key for this section from the dictionary.
    NSString *key = [[_orderItemsByType allKeys] objectAtIndex:section];
    
    // Get the order item objects belonging to this key, and store in an array.
    NSArray *orderItemsForKey = [_orderItemsByType valueForKey:key];
    
    return [orderItemsForKey count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[_orderItemsByType allKeys] objectAtIndex:section];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // Code for method adapted from: http://stackoverflow.com/questions/15611374/customize-uitableview-header-section
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 18)];
    [label setFont:[UIFont systemFontOfSize:14]];
    label.textColor = [UIColor grayColor];
    
    NSString *string = [[_orderItemsByType allKeys] objectAtIndex:section];
    
    [label setText:string];
    [view addSubview:label];
    
    // Set background colour for header.
    [view setBackgroundColor:[UIColor whiteColor]];
    
    return view;
}

#pragma mark - Parse

- (void)getParseData {
    // Get order items belonging to this order.
    PFQuery *getOrderItems = [PFQuery queryWithClassName:@"OrderItem"];
    [getOrderItems whereKey:@"forOrder" equalTo:_currentOrder];
    
    [getOrderItems findObjectsInBackgroundWithBlock:^(NSArray *orderItems, NSError *error) {
        if (!error) {
            // Create an array of all order items.
            _orderItems = [[NSArray alloc] initWithArray:orderItems];
            _orderItemsByType = [[NSMutableDictionary alloc] init];
            
            // Go through the 'raw' list of order items.
            for (NSDictionary *orderItem in _orderItems) {
                // Extract the current item's course.
                NSString *itemType=[orderItem valueForKey:@"type"];
                
                // If we don't already have this course, add it.
                if (![[_orderItemsByType allKeys] containsObject:itemType]) {
                    // Create an array containing the current order item object.
                    NSMutableArray *orderItemsForType = [[NSMutableArray alloc] initWithObjects:orderItem, nil];
                    
                    [_orderItemsByType setObject:orderItemsForType forKey:itemType];
                } else {
                    // If the key (i.e. course) already exists, add this order item to its array.
                    NSMutableArray *orderItemsForType = [_orderItemsByType valueForKey:itemType];
                    [orderItemsForType addObject:orderItem];
                    
                    [_orderItemsByType setObject:orderItemsForType forKey:itemType];
                }
            }
        }
        
        [orderItemsTableView reloadData];
    }];
}

@end
