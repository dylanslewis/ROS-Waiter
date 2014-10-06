//
//  MenuCoursesViewController.m
//  Waiter
//
//  Created by Dylan Lewis on 19/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "MenuCoursesViewController.h"
#import "MenuDishesViewController.h"
#import "CourseTableViewCell.h"
#import "UIColor+ApplicationColours.h"

@interface MenuCoursesViewController ()

@property (strong, nonatomic) NSMutableDictionary *coursesByType;

@end

@implementation MenuCoursesViewController

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // The className to query on
        self.parseClassName = @"Course";
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = NO;
        self.objectsPerPage = 25;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
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

#pragma mark - Button handling

- (IBAction)didTouchDoneButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Parse

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    // Create an array of all order items.
    _coursesByType = [[NSMutableDictionary alloc] init];
    
    // Go through the 'raw' list of order items.
    for (NSDictionary *course in self.objects) {
        // Extract course type.
        NSString *courseType=[course valueForKey:@"type"];
        
        // If we don't already have this type, add it.
        if (![[_coursesByType allKeys] containsObject:courseType]) {
            // Create an array containing the current course item object.
            NSMutableArray *courseItem = [[NSMutableArray alloc] initWithObjects:course, nil];
            
            [_coursesByType setObject:courseItem forKey:courseType];
        } else {
            // If the key (i.e. course type) already exists, add course to its array.
            NSMutableArray *courseItems = [_coursesByType valueForKey:courseType];
            [courseItems addObject:course];
            
            [_coursesByType setObject:courseItems forKey:courseType];
        }
    }
    
    [self.tableView reloadData];
}

- (void)objectsWillLoad {
    [super objectsWillLoad];
    
    // This method is called before a PFQuery is fired to get more objects
}

// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [query orderByDescending:@"type"];
    
    return query;
}

#pragma mark - Table view

- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section]==0) {
        // This means the object is a Drink, because 'D' comes before 'F' in the alphabet.
        return [self.objects objectAtIndex:[indexPath row]];
    } else {
        // This means the object is Food.
        // Get the number of objects that are 'Drink'.
        NSInteger numberOfDrinkObjects = [[_coursesByType valueForKey:@"Drink"] count];
        
        NSInteger flattenedIndex = numberOfDrinkObjects + [indexPath row];
        
        return [self.objects objectAtIndex:flattenedIndex];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_coursesByType count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Get the key for this section from the dictionary.
    NSString *key = [[_coursesByType allKeys] objectAtIndex:section];
    
    // Get the order item objects belonging to this key, and store in an array.
    NSArray *coursesForKey = [_coursesByType valueForKey:key];
    
    return [coursesForKey count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[_coursesByType allKeys] objectAtIndex:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // Code for method adapted from: http://stackoverflow.com/questions/15611374/customize-uitableview-header-section
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 18)];
    [label setFont:[UIFont systemFontOfSize:14]];
    label.textColor = [UIColor grayColor];
    
    NSString *string = [[_coursesByType allKeys] objectAtIndex:section];
    
    [label setText:string];
    [view addSubview:label];
    
    // Set background colour for header.
    [view setBackgroundColor:[UIColor whiteColor]];
    
    return view;
}

- (CourseTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"courseCell";
    
    CourseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSString *keyForSection = [[_coursesByType allKeys] objectAtIndex:[indexPath section]];
    
    PFObject *course = [[_coursesByType valueForKey:keyForSection] objectAtIndex:[indexPath row]];
    
    // Configure the cell
    cell.courseNameLabel.text = [course objectForKey:@"name"];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDishesSegue"]) {
        // Retrieve the PFObject from the cell.
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        PFObject *course=[self objectAtIndexPath:indexPath];
        
        // Pass the PFObject to the next scene.
        [[segue destinationViewController] setCurrentCourse:course];
        [[segue destinationViewController] setCurrentOrder:_orderForMenu];
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
