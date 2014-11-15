//
//  ReservationsViewController.m
//  Waiter
//
//  Created by Dylan Lewis on 21/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "ReservationsViewController.h"

@interface ReservationsViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addReservationButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *historyButton;

@property (strong, nonatomic) UIAlertView *alertView;

@property (strong, nonatomic) NSArray *reservationsArray;

@end

@implementation ReservationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initially hide the table view, until objects are retrieved.
    [reservationsTableView setHidden:YES];
    
    [self getParseData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getParseData {
    PFQuery *getReservations = [PFQuery queryWithClassName:@"Reservation"];
    
    [getReservations findObjectsInBackgroundWithBlock:^(NSArray *reservations, NSError *error) {
        if (!error) {
            _reservationsArray = [[NSArray alloc] initWithArray:reservations];
        }
                
        // Only show the table view if there are objects to display.
        if ([_reservationsArray count]) {
            [reservationsTableView setHidden:NO];
            [reservationsTableView reloadData];
        } else {
            [reservationsTableView setHidden:YES];
        }
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_reservationsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"reservationCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    //PFObject *reservation = [_reservationsArray objectAtIndex:indexPath.row];
    
    // Configure the cell
    cell.textLabel.text = @"Example reservation";
    
    return cell;
}

@end
