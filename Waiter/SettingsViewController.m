//
//  SettingsViewController.m
//  Manager
//
//  Created by Dylan Lewis on 09/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "SettingsViewController.h"


@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *restaurantNameLabel;

@property (weak, nonatomic) IBOutlet UIButton *logoutWaiterButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutRestaurantButton;

@end

@implementation SettingsViewController

@synthesize logoutWaiterButton=_logoutWaiterButton;

#pragma mark - Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Get the current user.
    PFUser *user=[PFUser currentUser];
    
    if (user) {
        // If a user is logged in, display their credentials.
        _usernameLabel.text = user.username;
        _restaurantNameLabel.text = [user valueForKey:@"restaurant"];
    }
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

- (IBAction)didTouchLogOutWaiterButton:(id)sender {
}

- (IBAction)didTouchLogOutRestaurantButton:(id)sender {
    // Logout the current user and return to the login screen.
    [PFUser logOut];
    
    [self performSegueWithIdentifier:@"logoutUserSegue" sender:nil];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    // This stops the button automatically logging out the user, without checking confirmation.
    if ([identifier isEqualToString:@"logoutUserSegue"]) {
        return NO;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
