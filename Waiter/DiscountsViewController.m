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
    
    [_discountAmountTextField setPlaceholder:@"amount"];
    [_discountAmountTextField setKeyboardType:UIKeyboardTypeDecimalPad];
    
    [_applyOfferCodeButton setUserInteractionEnabled:NO];
    
    [_selectItemsButton setHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveSelectedItems:) name:@"didSelectItemsToDiscount" object:nil];
    
    [discountsTableView setHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button handling

- (IBAction)didChangeDiscountCoverageControl:(id)sender {
    if ([_discountCoverageControl selectedSegmentIndex]==0) {
        [_selectItemsButton setHidden:YES];
        
        
        // Update reduction description label.
    } else {
        [_selectItemsButton setHidden:NO];
    }
}

- (IBAction)didTouchApplyDiscountButton:(id)sender {
    NSString *coverage;
    NSNumber *amount;
    NSString *type;
    
    if ([_discountCoverageControl selectedSegmentIndex]==0) {
        coverage = @"total";
    } else {
        coverage = @"partial";
    }
    
    if ([_discountTypeControl selectedSegmentIndex]==0) {
        type = @"amount";
    } else {
        type = @"percentage";
    }
    
    amount = (NSNumber *)[_discountAmountTextField text];
    
    [self applyNewDiscountToCover:coverage withType:type withAmount:amount];

    [_discountAmountTextField resignFirstResponder];
    [_discountAmountTextField setText:@""];
    [_applyDiscountButton setTitle:@"Apply Discount" forState:UIControlStateNormal];
}

- (IBAction)didTouchApplyOfferCodeButton:(id)sender {
}

- (IBAction)didTouchDeleteDiscountButton:(id)sender {
    DiscountsTableViewCell *touchedCell = (DiscountsTableViewCell *)[[sender superview] superview];
    
    PFObject *discount = [touchedCell discount];
    
    [discount deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [self getParseData];
    }];
}

#pragma mark - Notification handling

-(void)saveSelectedItems:(NSNotification *)notification {
    _selectedItems = (NSArray *)notification.object;

    NSString *discountString = [NSString stringWithFormat:@"Apply Discount to %lu Items", (unsigned long)[_selectedItems count]];
    
    [_applyDiscountButton setTitle:discountString forState:UIControlStateNormal];
}

#pragma mark - Table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_discountObjects count];
}

- (DiscountsTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"discountCell";
    
    DiscountsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    PFObject *discount = [_discountObjects objectAtIndex:[indexPath row]];
    
    cell.discount = discount;
    
    NSString *amountAndType;
    
    if ([[discount objectForKey:@"type"] isEqualToString:@"amount"]) {
        amountAndType = [NSString stringWithFormat:@"£%@", [discount objectForKey:@"amount"]];
    } else {
        amountAndType = [NSString stringWithFormat:@"%@%%", [discount objectForKey:@"amount"]];
    }
    
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
        
        NSNumber *totalNumberOfItems = [[NSNumber alloc] initWithInteger:[_selectedItems count]];
        
        discount[@"totalValueOfItems"] = totalValueOfDiscountedItems;
        discount[@"totalNumberOfItems"] = totalNumberOfItems;
    }
    
    discount[@"type"] = type;
    discount[@"amount"] = amount;
    
    
    
    // Relate this new order to the currently logged in Waiter.
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
