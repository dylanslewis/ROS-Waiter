//
//  LoginViewController.m
//  Manager
//
//  Created by Dylan Lewis on 08/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "LoginViewController.h"
#import <Parse/Parse.h>

@interface LoginViewController ()

// Text fields
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

// Buttons
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

// Alerts
@property (strong, nonatomic) UIAlertView *alertView;

@end

@implementation LoginViewController

#pragma mark - Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Fix the keyboard and text entry types.
    [_usernameField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [_passwordField setSecureTextEntry:YES];
    
    // Hide the spinner at first.
    [[self spinner] setHidden:YES];
    [_loginButton setHidden:NO];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Button handling

- (IBAction)didTouchLoginButton:(id)sender {
    // Extract the user-entered data.
    NSString *username=[_usernameField text];
    NSString *password=[_passwordField text];
    
    // Attempt to login.
    [self loginUserWithUsername:username withPassword:password];
}


#pragma mark - Alert view handling

- (void)displayBasicAlertWithTitle:(NSString *)title withMessage:(NSString *)message {
    _alertView=[[UIAlertView alloc] initWithTitle:title
                                          message:message
                                         delegate:self
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil];
    [_alertView setAlertViewStyle:UIAlertViewStyleDefault];
    
    // Display the alert.
    [_alertView show];
}


#pragma mark - Parse

- (void)loginUserWithUsername:(NSString *)username withPassword:(NSString *)password {
    NSString *errorTitle=@"";
    NSString *errorMessage=@"";
    
    BOOL localErrorsPresent=YES;
    
    // Deal with local errors.
    if ([self isEmptyString:username]) {
        errorTitle=@"Username not entered";
        errorMessage=@"Please enter your username";
    } else if ([self isEmptyString:password]) {
        errorTitle=@"Password not entered";
        errorMessage=@"Please enter your password";
    } else {
        localErrorsPresent=NO;
    }
    
    // If there are no local errors, try to login the user.
    if (!localErrorsPresent) {
        // Temporarily disable user actions.
        [_usernameField setUserInteractionEnabled:NO];
        [_passwordField setUserInteractionEnabled:NO];
        
        // Dismiss the keyboard.
        [_usernameField resignFirstResponder];
        [_passwordField resignFirstResponder];
        
        // Start the spinner and hide the 'login' button.
        [_spinner startAnimating];
        [_loginButton setHidden:YES];
        
        [PFUser logInWithUsernameInBackground:username password:password
                                        block:^(PFUser *user, NSError *error) {
                                            NSString *errorTitle=@"";
                                            NSString *errorMessage=@"";
                                            
                                            // Hide the spinner.
                                            [_spinner stopAnimating];
                                            
                                            if (user) {
                                                // Login was successful.
                                                // Store the user as the current user, so they don't have to login again.
                                                PFUser *currentUser = [PFUser currentUser];
                                                
                                                if (currentUser) {
                                                    [self performSegueWithIdentifier:@"loginUser" sender:nil];
                                                } else {
                                                    // show the signup or login screen
                                                }
                                            } else {
                                                // The login failed.
                                                NSString *errorCode=[NSString stringWithFormat:@"%@", [[error userInfo] valueForKey:@"code"]];
                                                
                                                // Deal with unknown errors.
                                                if (![errorCode isEqualToString:@""]) {
                                                    errorTitle = @"Unknown error";
                                                    errorMessage = [[error userInfo] valueForKey:@"error"];
                                                }
                                                
                                                // Deal with invalid credentials.
                                                if ([errorCode isEqualToString:@"101"]) {
                                                    errorTitle = @"Invalid credentials";
                                                    errorMessage = @"Please check your username and password and try again.";
                                                }
                                                
                                                // Display an alert detailing any errors.
                                                if (![errorMessage isEqualToString:@""]) {
                                                    [self displayBasicAlertWithTitle:errorTitle withMessage:errorMessage];
                                                }
                                                
                                                // Re-enable user interaction.
                                                [_usernameField setUserInteractionEnabled:YES];
                                                [_passwordField setUserInteractionEnabled:YES];
                                                
                                                // Re-display the signup button.
                                                [_loginButton setHidden:NO];
                                            }
                                        }];
    } else {
        [self displayBasicAlertWithTitle:errorTitle withMessage:errorMessage];
    }
}


#pragma mark - Basic operations

- (BOOL)isEmptyString:(NSString *)string {
    // Method copied from: http://stackoverflow.com/questions/3436173/nsstring-is-empty
    // Returns YES if the string is nil or equal to @""
    // Note that [string length] == 0 can be false when [string isEqualToString:@""] is true, because these are Unicode strings.
    
    if (((NSNull *) string == [NSNull null]) || (string == nil) ) {
        return YES;
    }
    string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([string isEqualToString:@""]) {
        return YES;
    }
    
    return NO;
}


#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    // This stops the button automatically logging in the user, without checking credentials.
    if ([identifier isEqualToString:@"loginUser"]) {
        return NO;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
