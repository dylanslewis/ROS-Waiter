//
//  DiscountsViewController.m
//  Waiter
//
//  Created by Dylan Lewis on 04/10/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "DiscountsViewController.h"
#import "DiscountsTableViewCell.h"
#import "SelectDiscountItemsView.h"
#import <Parse/Parse.h>

@interface DiscountsViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *discountCoverageControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *discountTypeControl;

@property (weak, nonatomic) IBOutlet UITextField *discountAmountTextField;

@property (weak, nonatomic) IBOutlet UIButton *selectItemsButton;
@property (weak, nonatomic) IBOutlet UIButton *applyDiscountButton;
@property (weak, nonatomic) IBOutlet UIButton *applyOfferCodeButton;

@property (strong, nonatomic) NSArray *discountObjects;

@end

@implementation DiscountsViewController

#pragma mark - Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self getParseData];
    
    // Update placeholders.
    [_discountAmountTextField setKeyboardType:UIKeyboardTypeDecimalPad];
    
    [_applyOfferCodeButton setUserInteractionEnabled:NO];
    
    [_selectItemsButton setHidden:YES];
    
    // Listen to updates about selected items to discount.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveSelectedItems:) name:@"didSelectItemsToDiscount" object:nil];
    
    [discountsTableView setHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button handling

- (IBAction)didChangeDiscountCoverageControl:(id)sender {
    // Hide or show the select items button, depending on the coverage option set.
    if ([_discountCoverageControl selectedSegmentIndex]==0) {
        [_selectItemsButton setHidden:YES];
    } else {
        [_selectItemsButton setHidden:NO];
    }
}

- (IBAction)didTouchApplyDiscountButton:(id)sender {
    NSString *coverage;
    NSNumber *amount;
    NSString *type;
    
    // Extract the coverage of the disccount.
    if ([_discountCoverageControl selectedSegmentIndex]==0) {
        coverage = @"total";
    } else {
        coverage = @"partial";
    }
    
    // Extract the type of discount.
    if ([_discountTypeControl selectedSegmentIndex]==0) {
        type = @"amount";
    } else {
        type = @"percentage";
    }
    
    // Get the amount from the text field.
    amount = (NSNumber *)[_discountAmountTextField text];
    
    [self applyNewDiscountToCover:coverage withType:type withAmount:amount];

    // Reset fields.
    [_discountAmountTextField resignFirstResponder];
    [_discountAmountTextField setText:@""];
    [_applyDiscountButton setTitle:@"Apply Discount" forState:UIControlStateNormal];
}

- (IBAction)didTouchApplyOfferCodeButton:(id)sender {
}

- (IBAction)didTouchDeleteDiscountButton:(id)sender {
    // Delete the discount of the current cell.
    DiscountsTableViewCell *touchedCell = (DiscountsTableViewCell *)[[sender superview] superview];
    
    PFObject *discount = [touchedCell discount];
    
    [discount deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // Update data.
        [self getParseData];
    }];
}

#pragma mark - Notification handling

-(void)saveSelectedItems:(NSNotification *)notification {
    _selectedItems = (NSArray *)notification.object;

    NSString *discountString = [NSString stringWithFormat:@"Apply Discount to %lu Items", (unsigned long)[_selectedItems count]];

    // Update the button to show the user how many items are having a discount applied to them.
    [_applyDiscountButton setTitle:discountString forState:UIControlStateNormal];
}

#pragma mark - Table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_discountObjects count];
}

- (DiscountsTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"discountCell";
    
    DiscountsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Get the discount object from the array.
    PFObject *discount = [_discountObjects objectAtIndex:[indexPath row]];
    
    cell.discount = discount;
    
    NSString *amountAndType;
    
    // Create the appropriate string, depending on the type of discount.
    if ([[discount objectForKey:@"type"] isEqualToString:@"amount"]) {
        amountAndType = [NSString stringWithFormat:@"£%@", [discount objectForKey:@"amount"]];
    } else {
        amountAndType = [NSString stringWithFormat:@"%@%%", [discount objectForKey:@"amount"]];
    }
    
    // Concatenate the amountAndType string to a string describing the coverage of the discount;.
    if ([[discount objectForKey:@"coverage"] isEqualToString:@"total"]) {
        cell.offerDescriptionLabel.text = [NSString stringWithFormat:@"%@ discount on the total bill", amountAndType];
    } else {
        NSArray *discountedItems = (NSArray *)[discount objectForKey:@"discountedItems"];
    
        cell.offerDescriptionLabel.text = [NSString stringWithFormat:@"%@ discount on %lu items", amountAndType, (unsigned long)[discountedItems count]];
    }
    
    
    return cell;
}


#pragma mark - Parse

- (void)applyNewDiscountToCover:(NSString *)coverage withType:(NSString *)type withAmount:(NSNumber *)amount {
    // Create a new discount for this Order.
    PFObject *discount = [PFObject objectWithClassName:@"Discount"];
    
    discount[@"coverage"] = coverage;
    
    // If the discount applies to items, attatch the items' information to the bill.
    if ([coverage isEqualToString:@"partial"]) {
        discount[@"discountedItems"] = [[NSArray alloc] initWithArray:_selectedItems];
        
        NSNumber *totalValueOfDiscountedItems = @0;
        
        // Calculate the total value of all the items included in this discount.
        for (PFObject *item in _selectedItems) {
            NSNumber *currentItemValue = [[NSNumber alloc] initWithFloat:([item[@"price"] floatValue] * [item[@"quantity"] floatValue])];
            
            totalValueOfDiscountedItems = [[NSNumber alloc] initWithFloat:([totalValueOfDiscountedItems floatValue] + [currentItemValue floatValue])];
        }
        
        // Get the total number of items that this discount applies to. Maybe change this to multiply by quantity?
        NSNumber *totalNumberOfItems = [[NSNumber alloc] initWithInteger:[_selectedItems count]];
        
        discount[@"totalValueOfItems"] = totalValueOfDiscountedItems;
        discount[@"totalNumberOfItems"] = totalNumberOfItems;
    }
    
    discount[@"type"] = type;
    discount[@"amount"] = amount;
    
    // Relate this new discount to the current Order.
    discount[@"forOrder"] = _currentOrder;
    
    // Add ACL permissions for added security.
    PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
    [discount setACL:acl];
    
    [discount saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // Refresh the table when the object is done saving.
        [self getParseData];
    }];
}

- (void)getParseData {
    PFQuery *getOrderItems = [PFQuery queryWithClassName:@"Discount"];
    [getOrderItems whereKey:@"forOrder" equalTo:_currentOrder];
    
    [getOrderItems findObjectsInBackgroundWithBlock:^(NSArray *discountItems, NSError *error) {
        if (!error) {
            // Create an array of all order items.
            _discountObjects = [[NSArray alloc] initWithArray:discountItems];
            
            if ([_discountObjects count]>0) {
                [discountsTableView setHidden:NO];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updatedDiscounts" object:nil];
        }
        
        [discountsTableView reloadData];
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"selectDiscountItems"]) {
        // Pass the PFObject to the next scene.
        SelectDiscountItemsView *vc = (SelectDiscountItemsView *)[[segue destinationViewController] topViewController];
        
        [vc setCurrentOrder:_currentOrder];
        [vc setPreviouslySelectedItems:_selectedItems];
    }
}

@end
