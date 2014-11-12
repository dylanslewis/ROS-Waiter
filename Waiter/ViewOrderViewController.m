//
//  ViewOrderViewController.m
//  Waiter
//
//  Created by Dylan Lewis on 10/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "ViewOrderViewController.h"
#import "OrderItemTableViewCell.h"
#import "MenuCoursesViewController.h"
#import "UIColor+ApplicationColours.h"
#import "DiscountsViewController.h"

@interface ViewOrderViewController ()

@property (weak, nonatomic) IBOutlet UILabel *orderTableNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderTotalPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *previousOrderTotalPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *collectDishesLabel;


@property (weak, nonatomic) IBOutlet UIButton *discountsButton;
@property (weak, nonatomic) IBOutlet UIButton *collectDishesButton;

@property (strong, nonatomic) NSArray *orderItemsArray;
@property (strong, nonatomic) NSNumber *totalBill;

@property (strong, nonatomic) PFObject *currentDiscountedItem;

@property (strong, nonatomic) NSMutableDictionary *orderItemSections;

@end

@implementation ViewOrderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    // Update the labels.
    if (_currentOrder) {
        _orderTableNumberLabel.text = [_currentOrder objectForKey:@"tableNumber"];
        _orderTotalPriceLabel.text = [NSString stringWithFormat:@"£%@", [_currentOrder objectForKey:@"totalPrice"]];
    }
    
    [_previousOrderTotalPriceLabel setHidden:YES];
    [_collectDishesButton setHidden:YES];
    [_collectDishesLabel setHidden:YES];
    
    // Listen to updates for Order Items
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getParseData) name:@"addedItemToOrder" object:nil];
    
    // Listen to updates to Discounts.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getParseData) name:@"updatedDiscounts" object:nil];
    
    // Get Order information.
    [self getParseData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button handling

- (IBAction)didTouchGenerateBillButton:(id)sender {
    // Clear the cache at this point.
    [self showEmail];
}

- (IBAction)didTouchCancelOrderButton:(id)sender {
    // Clear the cache at this point. //
    
    [self deleteOrderItemAndDiscountObjectsForOrder:_currentOrder];
    
    [_currentOrder deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"orderChange" object:nil];
            
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            NSString *tableNumberString = [NSString stringWithFormat:@"table%@", _currentOrder[@"tableNumber"]];
            [currentInstallation removeObject:tableNumberString forKey:@"channels"];
            [currentInstallation saveInBackground];
            
            [self.navigationController popViewControllerAnimated:TRUE];
        }
    }];
}

- (IBAction)didTouchCollectDishesButton:(id)sender {
    // Mark all the 'ready' items as 'collected'
    [self didCollectAllItemsForOrder:_currentOrder];
}


#pragma mark - Email
- (void)showEmail {
    // All email code adapted from http://www.appcoda.com/ios-programming-101-send-email-iphone-app/
    
    // Create the Email's items in a String.
    NSString *emailTitle = [NSString stringWithFormat:@"Restaurant Order Reciept"];
    NSMutableString *orderItems = [[NSMutableString alloc] init];
    for (PFObject *orderItem in _orderItemsArray) {
        [orderItems appendString:[NSString stringWithFormat:@"%@x %@ £%@\n", orderItem[@"quantity"], orderItem[@"name"], orderItem[@"price"]]];
    }
    
    // Create the contents of the email.
    NSString *messageBody = [NSString stringWithFormat:@"Dear Customer, \n\n Thank you for eating at our restaurant. \n\n\n Here's what you ordered: \n%@ Total: £%@ \n\n We hope to see you again soon, \n\n Yours sincerely,", orderItems, _currentOrder[@"totalPrice"]];
    NSArray *toRecipents = [NSArray arrayWithObject:@"dylanslewis@me.com"];
    
    // Set Strings to the MailCompose object.
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];
    
    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];
    
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    _currentOrder[@"state"] = @"paid";
    [_currentOrder saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"orderChange" object:nil];
        
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        NSString *tableNumberString = [NSString stringWithFormat:@"table%@", _currentOrder[@"tableNumber"]];
        [currentInstallation removeObject:tableNumberString forKey:@"channels"];
        [currentInstallation saveInBackground];
        
        [self dismissViewControllerAnimated:YES completion:NULL];
        [self.navigationController popViewControllerAnimated:TRUE];
    }];
}


#pragma mark - Parse

- (void)getParseData {
    // Get order items for this order.
    PFQuery *getOrderItems = [PFQuery queryWithClassName:@"OrderItem"];
    [getOrderItems whereKey:@"forOrder" equalTo:_currentOrder];
    
    [getOrderItems findObjectsInBackgroundWithBlock:^(NSArray *orderItems, NSError *error) {
        if (!error) {
            // Update the order state.
            [self setOrderStateForOrder:_currentOrder];
            
            // Create an array of all order items.
            _orderItemsArray = [[NSArray alloc] initWithArray:orderItems];
            _orderItemSections = [[NSMutableDictionary alloc] init];
            
            // Reset the total bill amount.
            _totalBill = @0;
            
            // Go through the 'raw' list of order items.
            for (NSDictionary *orderItem in _orderItemsArray) {
                // Extract the current item's course.
                NSString *courseName=[orderItem valueForKey:@"course"];
                
                NSNumber *currentOrderItemPrice = [[NSNumber alloc] initWithFloat:[orderItem[@"price"] floatValue] * [orderItem[@"quantity"] floatValue]];
                
                // Add the current total bill to the (current item price * quantity).
                _totalBill = [[NSNumber alloc] initWithFloat:[currentOrderItemPrice floatValue] + [_totalBill floatValue]];
                
                // Group all drinks together.
                if ([orderItem[@"type"] isEqualToString:@"Drink"]) {
                    courseName = @"Drinks";
                } else if ([orderItem[@"state"] isEqualToString:@"ready"]) {
                    courseName = [NSString stringWithFormat:@"%@ ready to collect", courseName];
                    
                    [_collectDishesLabel setHidden:NO];
                    [_collectDishesButton setHidden:NO];
                } else if ([orderItem[@"state"] isEqualToString:@"rejected"]) {
                    courseName = [NSString stringWithFormat:@"Rejected %@", [courseName lowercaseString]];
                }
                
                // If we don't already have this course, add it.
                if (![[_orderItemSections allKeys] containsObject:courseName]) {
                    // Create an array containing the current order item object.
                    NSMutableArray *orderItemsForCourse = [[NSMutableArray alloc] initWithObjects:orderItem, nil];
                    
                    [_orderItemSections setObject:orderItemsForCourse forKey:courseName];
                } else {
                    // If the key (i.e. course) already exists, add this order item to its array.
                    NSMutableArray *orderItemsForCourse = [_orderItemSections valueForKey:courseName];
                    [orderItemsForCourse addObject:orderItem];
                    
                    [_orderItemSections setObject:orderItemsForCourse forKey:courseName];
                }

                // Check if this item is the nearest item to completion.
                NSDate *currentDate = [NSDate date];
                NSDate *closestCompletionDate = (NSDate *)_currentOrder[@"closestCompletionDate"];
                NSDate *completionDate = (NSDate *)orderItem[@"estimatedCompletionTime"];
                
                // If the current date is later on than the currently set cloests completion date, set the closest completion date to be this item, initially.
                if (completionDate != nil) {
                    if ([currentDate compare:closestCompletionDate] == NSOrderedDescending) {
                        _currentOrder[@"closestCompletionDate"] = completionDate;
                        [_currentOrder saveInBackground];
                    } else {
                        if ([closestCompletionDate compare:completionDate] == NSOrderedDescending) {
                            _currentOrder[@"closestCompletionDate"] = completionDate;
                            [_currentOrder saveInBackground];
                        }
                    }
                }
            }
            
            // Display the order price label.
            _orderTotalPriceLabel.text = [NSString stringWithFormat:@"£%@", _totalBill];
            
            // Download discount objects.
            [self getDiscounts];
        }
        
        // Reload the table.
        [orderItemsTableView reloadData];
    }];
}

- (void)setOrderStateForOrder:(PFObject *)order {
    // Get all the items belonging to this order.
    PFQuery *getOrderItems = [PFQuery queryWithClassName:@"OrderItem"];
    [getOrderItems whereKey:@"forOrder" equalTo:order];
    [getOrderItems findObjectsInBackgroundWithBlock:^(NSArray *orderItems, NSError *error) {
        if (!error) {
            NSInteger noOfItems=0;
            NSInteger noOfCollectedItems=0;
            NSInteger noOfAcceptedItems=0;
            NSInteger noOfRejectedItems=0;
            NSInteger noOfReadyItems=0;
            
            // Go through each of the order items and update the count variables.
            for (PFObject *orderItem in orderItems) {
                noOfItems++;
                if ([orderItem[@"state"] isEqualToString:@"collected"]) {
                    noOfCollectedItems++;
                } else if ([orderItem[@"state"] isEqualToString:@"accepted"]) {
                    noOfAcceptedItems++;
                } else if ([orderItem[@"state"] isEqualToString:@"rejected"]) {
                    noOfRejectedItems++;
                } else if ([orderItem[@"state"] isEqualToString:@"ready"]) {
                    noOfReadyItems++;
                }
            }
            
            NSString *state;
            
            // Go through each of the variables, and try and assign the most dominant item state to the whole order.
            if (noOfReadyItems>0) {
                state = @"readyToCollect";
            } else if (noOfRejectedItems>0) {
                state = @"itemRejected";
            } else if (noOfAcceptedItems>0) {
                state = @"estimatesSet";
            } else if (noOfCollectedItems>0) {
                state = @"itemsCollected";
            } else if (noOfItems>0) {
                state = @"itemsOrdered";
            } else {
                state = @"new";
            }
            
            order[@"state"] = state;
            [order saveInBackground];
        }
    }];
}

- (void)deleteOrderItemAndDiscountObjectsForOrder:(PFObject *)order {
    // Delete all objects associated with this Order.
    PFQuery *getOrderItems = [PFQuery queryWithClassName:@"OrderItem"];
    [getOrderItems whereKey:@"forOrder" equalTo:order];
    
    PFQuery *getDiscountItems = [PFQuery queryWithClassName:@"Discount"];
    [getDiscountItems whereKey:@"forOrder" equalTo:order];
    
    [getOrderItems findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        for (PFObject *orderItem in objects) {
            [orderItem deleteInBackground];
        }
    }];
    
    [getDiscountItems findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        for (PFObject *discount in objects) {
            [discount deleteInBackground];
        }
    }];
}

- (void)didCollectAllItemsForOrder:(PFObject *)order {
    // Delete all objects associated with this Order.
    PFQuery *getReadyItems = [PFQuery queryWithClassName:@"OrderItem"];
    [getReadyItems whereKey:@"forOrder" equalTo:order];
    [getReadyItems whereKey:@"state" equalTo:@"ready"];
    
    [getReadyItems findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        for (PFObject *orderItem in objects) {
            orderItem[@"state"] = @"collected";
            [orderItem saveInBackground];
        }
        [self getParseData];
    }];
}

- (void)getDiscounts {
    PFQuery *getDiscountItems = [PFQuery queryWithClassName:@"Discount"];
    [getDiscountItems whereKey:@"forOrder" equalTo:_currentOrder];
    
    // This will ensure all 'partial' discounts are applied before 'total' discounts.
    [getDiscountItems orderByAscending:@"coverage"];
    
    [getDiscountItems findObjectsInBackgroundWithBlock:^(NSArray *discountItems, NSError *error) {
        if (!error) {
            if ([discountItems count]==0) {
                [_previousOrderTotalPriceLabel setHidden:YES];
                [_discountsButton setTitle:@"Discounts" forState:UIControlStateNormal];
                
                // Update order variables.
                _currentOrder[@"totalPrice"] = _totalBill;
                [_currentOrder saveInBackground];
            } else {
                [self calculateDiscountsForBill:_totalBill withDiscounts:discountItems];
                [_discountsButton setTitle:[NSString stringWithFormat:@"Discounts (%lu)", (unsigned long)[discountItems count]] forState:UIControlStateNormal];
            }
        }
    }];
}

- (void)setCurrentOrder:(PFObject *)currentOrder {
    _currentOrder = currentOrder;
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_orderItemSections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Get the key for this section from the dictionary.
    NSString *key = [[_orderItemSections allKeys] objectAtIndex:section];
    
    // Get the order item objects belonging to this key, and store in an array.
    NSArray *orderItemsForKey = [_orderItemSections valueForKey:key];
    
    return [orderItemsForKey count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[_orderItemSections allKeys] objectAtIndex:section];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // Code for method adapted from: http://stackoverflow.com/questions/15611374/customize-uitableview-header-section
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 18)];
    [label setFont:[UIFont systemFontOfSize:14]];
    NSString *string = [[_orderItemSections allKeys] objectAtIndex:section];
    
    if ([string containsString:@"Rejected"]) {
        label.textColor = [UIColor managerRedColour];
    } else if ([string containsString:@"ready to collect"]) {
        label.textColor = [UIColor waiterGreenColour];
    } else {
        label.textColor = [UIColor grayColor];
    }
    
    
    [label setText:string];
    [view addSubview:label];
    
    // Set background colour for header.
    [view setBackgroundColor:[UIColor whiteColor]];

    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"orderItemCell";
    
    NSString *keyForSection = [[_orderItemSections allKeys] objectAtIndex:[indexPath section]];
    
    PFObject *orderItem = [[_orderItemSections valueForKey:keyForSection] objectAtIndex:[indexPath row]];

    OrderItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSAttributedString *dishAttributedString, *quantityAttributedString, *priceAttributedString, *stateAttributedString;
    
    if ([[orderItem[@"option"] allKeys] count]>0) {
        // Item has option.
        
        // Extract the option name.
        NSDictionary *optionKeyValuePair = [[NSDictionary alloc] initWithDictionary:orderItem[@"option"]];
        
        // Concatenate the option name string with the dish name string: Option DishName.
        NSString *concatenatedString = [NSString stringWithFormat:@"%@ %@", [[optionKeyValuePair allKeys] firstObject], [orderItem valueForKey:@"name"]];
        
        // Create the string
        dishAttributedString = [self createAttributedStringWithText:concatenatedString withColour:[UIColor waiterGreenColour] withFontSize:20];
        
        // Change the option name to blue.
        [self changeString:dishAttributedString toColour:[UIColor kitchenBlueColour] forRange:NSMakeRange(0, [[[optionKeyValuePair allKeys] firstObject] length])];
    } else {
        // Item does not have options.
        
        // Store the dish name in an attribtued string.
        dishAttributedString = [self createAttributedStringWithText:[orderItem valueForKey:@"name"] withColour:[UIColor waiterGreenColour] withFontSize:20];
    }
    
    // Create the price and quantity strings.
    priceAttributedString = [self createAttributedStringWithText:[NSString stringWithFormat:@"£%@", [orderItem objectForKey:@"price"]] withColour:[UIColor blackColor] withFontSize:14];
    quantityAttributedString = [self createAttributedStringWithText:[NSString stringWithFormat:@"%@ x", [orderItem objectForKey:@"quantity"]] withColour:[UIColor blackColor] withFontSize:18];
    
    NSString *stateString;
    UIColor *stateColour;
    
    if ([orderItem[@"state"] isEqualToString:@"delivered"]) {
        stateString = @"delivered";
        stateColour = [UIColor kitchenBlueColour];
    } else if ([orderItem[@"state"] isEqualToString:@"accepted"]) {
        int timeUntilCompletion = [self timeUntilDate:(NSDate *)orderItem[@"estimatedCompletionTime"]];
        
        if (timeUntilCompletion<1) {
            stateString = @"due";
        } else {
            NSString *minString;
            if (timeUntilCompletion==1) {
                minString = @"min";
            } else {
                minString = @"mins";
            }
            
            stateString = [NSString stringWithFormat:@"%d %@", timeUntilCompletion, minString];
        }
        
        stateColour = [UIColor waiterGreenColour];
    } else if ([orderItem[@"state"] isEqualToString:@"rejected"]) {
        stateString = @"rejected";
        stateColour = [UIColor managerRedColour];
        
        // Set the colour of all other cell elements to red.
        dishAttributedString = [self changeString:dishAttributedString toColour:stateColour forRange:NSMakeRange(0, [dishAttributedString length])];
        quantityAttributedString = [self changeString:quantityAttributedString toColour:stateColour forRange:NSMakeRange(0, [quantityAttributedString length])];
        priceAttributedString = [self changeString:priceAttributedString toColour:stateColour forRange:NSMakeRange(0, [priceAttributedString length])];
    } else if ([orderItem[@"state"] isEqualToString:@"ready"]) {
        stateString = @"ready";
        stateColour = [UIColor waiterGreenColour];
    } else if ([orderItem[@"state"] isEqualToString:@"collected"]) {
        stateString = @"collected";
        stateColour = [UIColor lightGrayColor];
        
        // Set the colour of all other cell elements to red.
        dishAttributedString = [self changeString:dishAttributedString toColour:stateColour forRange:NSMakeRange(0, [dishAttributedString length])];
        quantityAttributedString = [self changeString:quantityAttributedString toColour:stateColour forRange:NSMakeRange(0, [quantityAttributedString length])];
        priceAttributedString = [self changeString:priceAttributedString toColour:stateColour forRange:NSMakeRange(0, [priceAttributedString length])];
    } else {
        [cell.stateView setHidden:YES];
        [cell.orderItemStateLabel setHidden:YES];
    }
    
    if (![cell.stateView isHidden]) {
        stateAttributedString = [self createAttributedStringWithText:stateString withColour:stateColour withFontSize:12];
    }
    
    // Apply the attributed strings to the labels.
    [cell.orderItemNameLabel setAttributedText:dishAttributedString];
    [cell.orderItemQuantityLabel setAttributedText:quantityAttributedString];
    [cell.orderItemPriceLabel setAttributedText:priceAttributedString];
    [cell.orderItemStateLabel setAttributedText:stateAttributedString];
    
    // Set the state label colour.
    [cell.stateView setBackgroundColor:stateColour];
    
    return cell;
}

#pragma mark - Other

- (NSAttributedString *)createAttributedStringWithText:(NSString *)text withColour:(UIColor *)colour withFontSize:(float)size {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Light" size:size] range:NSMakeRange(0, [text length])];
    [attributedString addAttribute:NSForegroundColorAttributeName value:colour range:NSMakeRange(0, [text length])];
    
    return attributedString;
}

- (NSAttributedString *)changeString:(NSAttributedString *)attributedString toColour:(UIColor *)colour forRange:(NSRange)range {
    NSMutableAttributedString *mutableAttributedString = (NSMutableAttributedString *)attributedString;
    [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:colour range:range];
    
    return (NSAttributedString *)mutableAttributedString;
}

#pragma mark - Calculations

- (int)timeUntilDate:(NSDate *)date {
    // Work out the time until date.
    NSDate *currentDate = [NSDate date];
    NSTimeInterval secondsBetween = [date timeIntervalSinceDate:currentDate];
    int numberOfMinutes = secondsBetween / 60;
    
    // Increment numberOfMinutes so that '0 mins' appears as '1 min'.
    numberOfMinutes++;
    
    return numberOfMinutes;
}

- (void)calculateDiscountsForBill:(NSNumber *)subtotalBill withDiscounts:(NSArray *)discounts {
    NSNumber *newBillPrice = subtotalBill;
    NSNumber *discountAmount;
    NSNumber *percentage;
    
    // Look through all the discount objects.
    for (PFObject *discount in discounts) {
        NSNumber *totalValueOfItemsBeforeDiscount;
        
        // Work out the coverage of the discount.
        if ([[discount valueForKey:@"coverage"] isEqualToString:@"total"]) {
            // This discount covers the whole bill.
            totalValueOfItemsBeforeDiscount = newBillPrice;
        } else {
            // This discount applies to selected items.
            totalValueOfItemsBeforeDiscount = discount[@"totalValueOfItems"];
        }
        
        // Work out the type of discount, amount or percentage.
        if ([[discount valueForKey:@"type"] isEqualToString:@"amount"]) {
            // This is an amount deduction.
            discountAmount = [discount valueForKey:@"amount"];
            
            if ([[discount valueForKey:@"coverage"] isEqualToString:@"partial"]) {
                // If the discount applies to several items, multiply the number of items being discounted by the discount amount.
                NSNumber *numberOfDiscountedItems = [discount valueForKey:@"totalNumberOfItems"];
                
                discountAmount = [[NSNumber alloc] initWithFloat:([numberOfDiscountedItems floatValue] * [discountAmount floatValue])];
            }
        } else {
            // This is a percentage deduction.
            percentage = [discount valueForKey:@"amount"];
            percentage = @([percentage floatValue] / 100);

            // Calculate the percentage discounted multiplied by the total value to be discounted.
            discountAmount = [[NSNumber alloc] initWithFloat:([totalValueOfItemsBeforeDiscount floatValue] * [percentage floatValue])];
        }

        // Deduct the calculated discount amount from the current bill price.
        newBillPrice = [[NSNumber alloc] initWithFloat:[newBillPrice floatValue] - [discountAmount floatValue]];
    }
    
    // Update labels.
    [_orderTotalPriceLabel setText:[NSString stringWithFormat:@"£%@", newBillPrice]];
    [_previousOrderTotalPriceLabel setHidden:NO];
    
    _currentOrder[@"totalPrice"] = newBillPrice;
    [_currentOrder saveInBackground];
    
    NSNumber *priceDifference = @([_totalBill floatValue] - [newBillPrice floatValue]);
    
    // Show the original total price and the amount of deductions applied.
    NSMutableAttributedString *billCalculationString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"£%@ - £%@", _totalBill, priceDifference]];
    [billCalculationString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Thin" size:14.0f] range:NSMakeRange(0, [billCalculationString length])];
    
    [_previousOrderTotalPriceLabel setAttributedText:billCalculationString];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showMenuSegue"]) {
        // Pass the PFObject to the next scene.
        MenuCoursesViewController *vc = (MenuCoursesViewController *)[[segue destinationViewController] topViewController];
        [vc setOrderForMenu:_currentOrder];
    } else if ([[segue identifier] isEqualToString:@"manageDiscounts"]) {
        DiscountsViewController *vc = [segue destinationViewController];
        [vc setCurrentOrder:_currentOrder];
    }
}

@end
