//
//  AppDelegate.m
//  Waiter
//
//  Created by Dylan Lewis on 10/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import "UIColor+ApplicationColours.h"
#import "ViewOrderViewController.h"
#import "OrdersViewController.h"

@interface AppDelegate ()

@property (strong, nonatomic) UIAlertView *alertView;

@property (strong, nonatomic) PFObject *orderObject;

@end

@implementation AppDelegate
            

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Parse application credentials.
    [Parse setApplicationId:@"xmqa5fPQ9iIFnTdhj4KI9uxsbvOtqhcmTsLQNnnB"
                  clientKey:@"9o27OuesB5VcHx9RABHNGMpSSLQNTpewPf0uUEbb"];
    
    // Register for Push Notitications, if running iOS 8
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    } else {
        // Register for Push Notifications before iOS 8
        /*
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                         UIRemoteNotificationTypeAlert |
                                                         UIRemoteNotificationTypeSound)];
         */
    }

    
    // Customise the navigation bar.
    [[UINavigationBar appearance] setBarTintColor:[UIColor waiterGreenColour]];
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor whiteColor], NSForegroundColorAttributeName,
                                                           [UIFont fontWithName:@"HelveticaNeue-Light" size:21.0],
                                                           NSFontAttributeName, nil]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // Customise the tab bar.
    [[UITabBar appearance] setTintColor:[UIColor waiterGreenColour]];
    [[UITabBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       [UIFont fontWithName:@"HelveticaNeue-Light" size:11.0f], NSFontAttributeName,nil] forState:UIControlStateNormal];
    
    
    // Extract the notification data, so that users can be directed straight to the relevant order page.
    NSDictionary *notificationPayload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    
    if (notificationPayload) {
        // Create a pointer to the Order object
        NSString *orderID = [notificationPayload objectForKey:@"oID"];
        PFObject *targetOrder = [PFObject objectWithoutDataWithClassName:@"Order"
                                                                objectId:orderID];
        
        NSLog(@"Just launched: %@", targetOrder);
        
        // Fetch order object
        [targetOrder fetchIfNeededInBackgroundWithBlock:^(PFObject *orderObject, NSError *error) {
            if ([PFUser currentUser] && !error) {
                UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
                ViewOrderViewController *orderViewController = (ViewOrderViewController *)[mainStoryboard instantiateViewControllerWithIdentifier: @"ViewOrder"];
                [orderViewController setCurrentOrder:orderObject];
            }
        }];
    }
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    
    #warning Put in some error checking for logged in users.
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"user"] = [PFUser currentUser];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSString *orderID = [userInfo objectForKey:@"oID"];
    PFObject *targetOrder = [PFObject objectWithoutDataWithClassName:@"Order"
                                                            objectId:orderID];
    
    
    
    NSLog(@"THIS IS RUNNING");
    
    // Fetch order object
    [targetOrder fetchIfNeededInBackgroundWithBlock:^(PFObject *orderObject, NSError *error) {
        // Update the badge.
        PFQuery *query = [PFQuery queryWithClassName:@"Order"];
        [query whereKey:@"state" containedIn:@[@"readyToCollect", @"itemRejected"]];
        [query whereKey:@"waiterName" equalTo:orderObject[@"waiterName"]];
        [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
            [UIApplication sharedApplication].applicationIconBadgeNumber = number;
        }];

    }];
    
    [PFPush handlePush:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))handler {
    // Create empty order object
    NSString *orderID = [userInfo objectForKey:@"oID"];
    PFObject *targetOrder = [PFObject objectWithoutDataWithClassName:@"Order"
                                                            objectId:orderID];
    
    
    
    // Fetch order object
    [targetOrder fetchIfNeededInBackgroundWithBlock:^(PFObject *orderObject, NSError *error) {
        // Show orders view controller
        if (error) {
            handler(UIBackgroundFetchResultFailed);
        } else if ([PFUser currentUser]) {
            // We now need to take the user to the order page for this order object.
            
            _orderObject = orderObject;
            
            
            
            
            NSString *message = [NSString stringWithFormat:@"Dishes for Table %@ are now ready for collection", orderObject[@"tableNumber"]];
            
            [self displayBasicAlertWithTitle:@"Dishes Ready for Collection" withMessage:message];
            
            handler(UIBackgroundFetchResultNewData);
        } else {
            handler(UIBackgroundFetchResultNoData);
        }
    }];
}

#pragma mark - Alert view handling

- (void)displayBasicAlertWithTitle:(NSString *)title withMessage:(NSString *)message {
    _alertView=[[UIAlertView alloc] initWithTitle:title
                                          message:message
                                         delegate:self
                                cancelButtonTitle:@"Dismiss"
                                otherButtonTitles:@"Go to order", nil];
    [_alertView setAlertViewStyle:UIAlertViewStyleDefault];
    
    // Display the alert.
    [_alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Dishes Ready for Collection"]) {
        if (buttonIndex==1) {
            [self showViewControllerForOrder:_orderObject];
        }
    }
}

- (void)showViewControllerForOrder:(PFObject *)orderObject {
    NSLog(@"%@", _window);
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    ViewOrderViewController *controller = (ViewOrderViewController *)[mainStoryboard instantiateViewControllerWithIdentifier: @"ViewOrder"];
    [controller setCurrentOrder:orderObject];
    [self.window.rootViewController presentViewController:controller animated:YES completion:nil];

}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // Reset the badge count whenever the app is opened.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
