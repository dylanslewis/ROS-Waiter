//
//  WaiterTests.m
//  WaiterTests
//
//  Created by Dylan Lewis on 10/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <Parse/Parse.h>
#import "LoginViewController.h"
#import "WaiterViewController.h"
#import "OrdersViewController.h"
#import "MenuDishesViewController.h"
#import "DiscountsViewController.h"
#import "ViewOrderViewController.h"

@interface WaiterTests : XCTestCase

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;

@property (strong, nonatomic) NSMutableArray *createdObjects;

@end

@implementation WaiterTests

- (void)setUp {
    [super setUp];
    
    _username = @"dylan";
    _password = @"password";
    
    _createdObjects = [[NSMutableArray alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    // Delete all created objects.
    for (PFObject *object in _createdObjects) {
        // Delete the object.
        [object deleteInBackground];
        
        // Remove from the array.
        [_createdObjects removeObject:object];
    }
}

#pragma mark - Parse

- (PFQuery *)queryForObjectWithClassName:className withName:name {
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"name" equalTo:name];
    
    return query;
}

#pragma mark - Login

- (void)testLogin {
    LoginViewController *loginController = [[LoginViewController alloc] init];
    [loginController loginUserWithUsername:_username withPassword:_password];
    
    // Test the success of the login.
    PFUser *user = [PFUser currentUser];
    
    if ([user.username isEqualToString:_username]) {
        XCTAssert(YES, @"Login success");
    } else {
        XCTAssert(NO, @"Login fail");
    }
}

- (void)testWaiterLogin {
    // Please note that due to the Waiter app not having the functionality to create a Waiter, this test's success depends on the existence of the waiter "Dylan Lewis".
    
    WaiterViewController *waiterController = [[WaiterViewController alloc] init];
    
    NSString *firstName = @"Dylan";
    NSString *surname = @"Lewis";
    
    // Check if the waiter has been stored on the database and can be retrieved.
    PFQuery *query = [PFQuery queryWithClassName:@"Waiter"];
    [query whereKey:@"firstName" equalTo:firstName];
    [query whereKey:@"surname" equalTo:surname];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        __block PFObject *currentWaiter = [objects firstObject];
        
        // Extract the object ID from the waiter (the thing that's used to log in waiters).
        NSString *selectedWaiterObjectID = currentWaiter.objectId;
        
        // Login the waiter.
        [waiterController loginWaiterWithObjectID:selectedWaiterObjectID];
        
        // Check the currently logged in waiter.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *loggedInWaiterID = [defaults valueForKey:@"currentWaiterID"];
        if ([loggedInWaiterID isEqualToString:selectedWaiterObjectID]) {
            XCTAssert(YES, @"Waiter login success");
        } else {
            XCTAssert(NO, @"Waiter login fail");
        }
    }];
}

#pragma mark - Orders

- (void)testCreateOrder {
    // Please note that this test requires the Waiter "Dylan Lewis" to exist.
    
    OrdersViewController *ordersController = [[OrdersViewController alloc] init];
    
    NSString *firstName = @"Dylan";
    NSString *surname = @"Lewis";
    
    NSString *tableNumber = @"999";
    
    // Login the waiter.
    PFQuery *query = [PFQuery queryWithClassName:@"Waiter"];
    [query whereKey:@"firstName" equalTo:firstName];
    [query whereKey:@"surname" equalTo:surname];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        __block PFObject *currentWaiter = [objects firstObject];

        // Assign the waiter to the view controller.
        [ordersController setCurrentWaiter:currentWaiter];
        
        // Create the new order.
        [ordersController createNewOrderWithTableNumber:tableNumber];
        
        PFQuery *query = [PFQuery queryWithClassName:@"Order"];
        [query whereKey:@"tableNumber" equalTo:tableNumber];
        [query whereKey:@"forWaiter" equalTo:currentWaiter];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            __block PFObject *createdOrder = [objects firstObject];
            
            [_createdObjects addObject:createdOrder];
            
            if ([createdOrder[@"tableNumber"] isEqualToString:tableNumber] && [createdOrder[@"forWaiter"] isEqual:currentWaiter] && [createdOrder[@"state"] isEqualToString:@"new"] && [createdOrder[@"totalPrice"] isEqualToNumber:@0.00]) {
                XCTAssert(YES, @"Order created successfully");
            } else if (![createdOrder[@"tableNumber"] isEqualToString:tableNumber]) {
                XCTAssert(NO, @"Order table number not correct");
            } else if (![createdOrder[@"forWaiter"] isEqual:currentWaiter]) {
                XCTAssert(NO, @"Order waiter is incorrect");
            } else if (![createdOrder[@"state"] isEqualToString:@"new"]) {
                XCTAssert(NO, @"Order state is incorrect");
            } else if (![createdOrder[@"totalPrice"] isEqualToNumber:@0.00]) {
                XCTAssert(NO, @"Order initial price is incorrect");
            } else {
                XCTAssert(NO, @"Order creation failed");
            }
        }];
    }];
}

- (void)testAddItemToOrder {
    // Please note that because Waiter cannot add items to the menu, this test requires the existence of the "Mains" course and the "Carbonara" dish.
    
    OrdersViewController *ordersController = [[OrdersViewController alloc] init];
    MenuDishesViewController *dishesController = [[MenuDishesViewController alloc] init];
    
    NSString *firstName = @"Dylan";
    NSString *surname = @"Lewis";
    
    NSString *tableNumber = @"999";
    
    NSString *courseName = @"Mains";
    NSString *dishName = @"Carbonara";
    
    // Login the waiter.
    PFQuery *query = [PFQuery queryWithClassName:@"Waiter"];
    [query whereKey:@"firstName" equalTo:firstName];
    [query whereKey:@"surname" equalTo:surname];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        __block PFObject *currentWaiter = [objects firstObject];
        
        // Assign the waiter to the view controller.
        [ordersController setCurrentWaiter:currentWaiter];
        
        // Create the new order.
        [ordersController createNewOrderWithTableNumber:tableNumber];
        
        PFQuery *query = [PFQuery queryWithClassName:@"Order"];
        [query whereKey:@"tableNumber" equalTo:tableNumber];
        [query whereKey:@"forWaiter" equalTo:currentWaiter];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            __block PFObject *createdOrder = [objects firstObject];

            [_createdObjects addObject:createdOrder];
            
            // Retrieve the Course we're using for this test.
            PFQuery *query = [self queryForObjectWithClassName:@"Course" withName:courseName];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                __block PFObject *currentCourse = [objects firstObject];
                
                // Retrieve the Dish we want to add to the order.
                PFQuery *query = [self queryForObjectWithClassName:@"Dish" withName:dishName];
                [query whereKey:@"ofCourse" equalTo:currentCourse];
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    __block PFObject *currentDish = [objects firstObject];
                    
                    // Set the current order and course for the view controller.
                    [dishesController setCurrentOrder:createdOrder];
                    [dishesController setCurrentCourse:currentCourse];
                    
                    // Add the item to the order.
                    [dishesController addOrderItemToOrderForDish:currentDish];
                    
                    // Retrieve the Order's items.
                    PFQuery *query = [PFQuery queryWithClassName:@"OrderItem"];
                    [query whereKey:@"forOrder" equalTo:createdOrder];
                    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        __block PFObject *retrievedOrderItem = [objects firstObject];
                        
                        [_createdObjects addObject:retrievedOrderItem];
                        
                        if ([retrievedOrderItem[@"name"] isEqualToString:dishName] && [retrievedOrderItem[@"quantity"] isEqualToNumber:@1] && [retrievedOrderItem[@"whichDish"] isEqual:currentDish] && [retrievedOrderItem[@"course"] isEqualToString:currentCourse[@"name"]] && [retrievedOrderItem[@"state"] isEqualToString:@"new"] && [retrievedOrderItem[@"tableNumber"] isEqualToString:tableNumber]) {
                            XCTAssert(YES, @"Order item successfully added to order");
                        } else if (![retrievedOrderItem[@"name"] isEqualToString:dishName]) {
                            XCTAssert(NO, @"Order item name is incorrect");
                        } else if (![retrievedOrderItem[@"quantity"] isEqualToNumber:@1]) {
                            XCTAssert(NO, @"Order item quantity is incorrect");
                        } else if (![retrievedOrderItem[@"whichDish"] isEqual:currentDish]) {
                            XCTAssert(NO, @"Order item linked Dish is wrong");
                        } else if (![retrievedOrderItem[@"course"] isEqualToString:currentCourse[@"name"]]) {
                            XCTAssert(NO, @"Order item course is wrong");
                        } else if (![retrievedOrderItem[@"state"] isEqualToString:@"new"]) {
                            XCTAssert(NO, @"Order item state is wrong");
                        } else if (![retrievedOrderItem[@"tableNumber"] isEqualToString:tableNumber]) {
                            XCTAssert(NO, @"Order item table number is wrong");
                        } else {
                            XCTAssert(NO, @"Order item created unsuccessfully");
                        }
                    }];
                }];
            }];
        }];
    }];
}

- (void)testApplyOptionedItemToOrder {
    // Please note that because Waiter cannot add items to the menu, this test requires the existence of the "Mains" course and the "Carbonara" dish.
    
    OrdersViewController *ordersController = [[OrdersViewController alloc] init];
    MenuDishesViewController *dishesController = [[MenuDishesViewController alloc] init];
    
    NSString *firstName = @"Dylan";
    NSString *surname = @"Lewis";
    
    NSString *tableNumber = @"999";
    
    NSString *courseName = @"Mains";
    NSString *dishName = @"Sirloin Steak";
    
    NSString *optionName = @"Rare";
    NSNumber *optionPrice = @11.99;
    
    // Create the dicitonary of options.
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:optionPrice, optionName, nil];
    
    // Login the waiter.
    PFQuery *query = [PFQuery queryWithClassName:@"Waiter"];
    [query whereKey:@"firstName" equalTo:firstName];
    [query whereKey:@"surname" equalTo:surname];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        __block PFObject *currentWaiter = [objects firstObject];
        
        // Assign the waiter to the view controller.
        [ordersController setCurrentWaiter:currentWaiter];
        
        // Create the new order.
        [ordersController createNewOrderWithTableNumber:tableNumber];
        
        PFQuery *query = [PFQuery queryWithClassName:@"Order"];
        [query whereKey:@"tableNumber" equalTo:tableNumber];
        [query whereKey:@"forWaiter" equalTo:currentWaiter];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            __block PFObject *createdOrder = [objects firstObject];
            
            [_createdObjects addObject:createdOrder];
            
            // Retrieve the Course we're using for this test.
            PFQuery *query = [self queryForObjectWithClassName:@"Course" withName:courseName];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                __block PFObject *currentCourse = [objects firstObject];
                
                // Retrieve the Dish we want to add to the order.
                PFQuery *query = [self queryForObjectWithClassName:@"Dish" withName:dishName];
                [query whereKey:@"ofCourse" equalTo:currentCourse];
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    __block PFObject *currentDish = [objects firstObject];
                    
                    // Set the current order and course for the view controller.
                    [dishesController setCurrentOrder:createdOrder];
                    [dishesController setCurrentCourse:currentCourse];
                    
                    // Add the item to the order.
                    [dishesController addOrderItemToOrderWithDish:currentDish withOption:options];
                    
                    // Retrieve the Order's items.
                    PFQuery *query = [PFQuery queryWithClassName:@"OrderItem"];
                    [query whereKey:@"forOrder" equalTo:createdOrder];
                    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        __block PFObject *retrievedOrderItem = [objects firstObject];
                        
                        [_createdObjects addObject:retrievedOrderItem];
                        
                        if ([retrievedOrderItem[@"name"] isEqualToString:dishName] && [retrievedOrderItem[@"quantity"] isEqualToNumber:@1] && [retrievedOrderItem[@"whichDish"] isEqual:currentDish] && [retrievedOrderItem[@"course"] isEqualToString:currentCourse[@"name"]] && [retrievedOrderItem[@"state"] isEqualToString:@"new"] && [retrievedOrderItem[@"tableNumber"] isEqualToString:tableNumber] && [retrievedOrderItem[@"options"] isEqual:options]) {
                            XCTAssert(YES, @"Order item successfully added to order");
                        } else if (![retrievedOrderItem[@"name"] isEqualToString:dishName]) {
                            XCTAssert(NO, @"Order item name is incorrect");
                        } else if (![retrievedOrderItem[@"quantity"] isEqualToNumber:@1]) {
                            XCTAssert(NO, @"Order item quantity is incorrect");
                        } else if (![retrievedOrderItem[@"whichDish"] isEqual:currentDish]) {
                            XCTAssert(NO, @"Order item linked Dish is wrong");
                        } else if (![retrievedOrderItem[@"course"] isEqualToString:currentCourse[@"name"]]) {
                            XCTAssert(NO, @"Order item course is wrong");
                        } else if (![retrievedOrderItem[@"state"] isEqualToString:@"new"]) {
                            XCTAssert(NO, @"Order item state is wrong");
                        } else if (![retrievedOrderItem[@"tableNumber"] isEqualToString:tableNumber]) {
                            XCTAssert(NO, @"Order item table number is wrong");
                        } else if (![retrievedOrderItem[@"options"] isEqual:options]) {
                            XCTAssert(NO, @"Order item options are is wrong");
                        } else {
                            XCTAssert(NO, @"Order item created unsuccessfully");
                        }
                    }];
                }];
            }];
        }];
    }];
}

- (void)testApplyDiscountToOrder {
    // Please note that this test requires the Waiter "Dylan Lewis" to exist. The estimated price is based on the price of "Carbonara" - £1.
    
    OrdersViewController *ordersController = [[OrdersViewController alloc] init];
    MenuDishesViewController *dishesController = [[MenuDishesViewController alloc] init];
    DiscountsViewController *discountsController = [[DiscountsViewController alloc] init];
    ViewOrderViewController *viewOrderController = [[ViewOrderViewController alloc] init];
    
    NSString *firstName = @"Dylan";
    NSString *surname = @"Lewis";
    
    NSString *tableNumber = @"999";
    
    NSString *courseName = @"Mains";
    NSString *dishName = @"Carbonara";
    
    NSString *discountCoverage = @"total";
    NSString *discountType = @"amount";
    NSNumber *discountAmount = @1;
    NSNumber *estimatedTotalPrice = @6.99;
    
    // Login the waiter.
    PFQuery *query = [PFQuery queryWithClassName:@"Waiter"];
    [query whereKey:@"firstName" equalTo:firstName];
    [query whereKey:@"surname" equalTo:surname];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        __block PFObject *currentWaiter = [objects firstObject];
        
        // Assign the waiter to the view controller.
        [ordersController setCurrentWaiter:currentWaiter];
        
        // Create the new order.
        [ordersController createNewOrderWithTableNumber:tableNumber];
        
        PFQuery *query = [PFQuery queryWithClassName:@"Order"];
        [query whereKey:@"tableNumber" equalTo:tableNumber];
        [query whereKey:@"forWaiter" equalTo:currentWaiter];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            __block PFObject *createdOrder = [objects firstObject];
            
            [_createdObjects addObject:createdOrder];
            
            // Retrieve the Course we're using for this test.
            PFQuery *query = [self queryForObjectWithClassName:@"Course" withName:courseName];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                __block PFObject *currentCourse = [objects firstObject];
                
                // Retrieve the Dish we want to add to the order.
                PFQuery *query = [self queryForObjectWithClassName:@"Dish" withName:dishName];
                [query whereKey:@"ofCourse" equalTo:currentCourse];
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    __block PFObject *currentDish = [objects firstObject];
                    
                    // Set the current order and course for the view controller.
                    [dishesController setCurrentOrder:createdOrder];
                    [dishesController setCurrentCourse:currentCourse];
                    
                    // Add the item to the order.
                    [dishesController addOrderItemToOrderForDish:currentDish];
                    
                    // Apply the discount to the order.
                    [discountsController applyNewDiscountToCover:discountCoverage withType:discountType withAmount:discountAmount];
                    
                    // Assign the Order object to the Order controller.
                    [viewOrderController setCurrentOrder:createdOrder];
                    
                    // Download the Order items, which will in turn download and apply all discounts.
                    [viewOrderController getParseData];
                    
                    // Refetch the Order object, so that we can examine the totalPrice.
                    [createdOrder fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                        createdOrder = object;
                        
                        if ([createdOrder[@"totalPrice"] isEqualToNumber:estimatedTotalPrice]) {
                            XCTAssert(YES, @"Discount successfully added to order");
                        } else {
                            XCTAssert(NO, @"Discount failed to be added to order");
                        }
                    }];
                }];
            }];
        }];
    }];
}

- (void)testApplyDiscountToItem {
    // Please note that this test requires the Waiter "Dylan Lewis" to exist. The estimated price is based on the price of "Carbonara" - £1.
    
    OrdersViewController *ordersController = [[OrdersViewController alloc] init];
    MenuDishesViewController *dishesController = [[MenuDishesViewController alloc] init];
    DiscountsViewController *discountsController = [[DiscountsViewController alloc] init];
    ViewOrderViewController *viewOrderController = [[ViewOrderViewController alloc] init];
    
    NSString *firstName = @"Dylan";
    NSString *surname = @"Lewis";
    
    NSString *tableNumber = @"999";
    
    NSString *courseName = @"Mains";
    NSString *dishName = @"Carbonara";
    
    NSString *discountCoverage = @"total";
    NSString *discountType = @"partial";
    NSNumber *discountAmount = @1;
    NSNumber *estimatedTotalPrice = @6.99;
    
    // Login the waiter.
    PFQuery *query = [PFQuery queryWithClassName:@"Waiter"];
    [query whereKey:@"firstName" equalTo:firstName];
    [query whereKey:@"surname" equalTo:surname];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        __block PFObject *currentWaiter = [objects firstObject];
        
        // Assign the waiter to the view controller.
        [ordersController setCurrentWaiter:currentWaiter];
        
        // Create the new order.
        [ordersController createNewOrderWithTableNumber:tableNumber];
        
        PFQuery *query = [PFQuery queryWithClassName:@"Order"];
        [query whereKey:@"tableNumber" equalTo:tableNumber];
        [query whereKey:@"forWaiter" equalTo:currentWaiter];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            __block PFObject *createdOrder = [objects firstObject];
            
            [_createdObjects addObject:createdOrder];
            
            // Retrieve the Course we're using for this test.
            PFQuery *query = [self queryForObjectWithClassName:@"Course" withName:courseName];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                __block PFObject *currentCourse = [objects firstObject];
                
                // Retrieve the Dish we want to add to the order.
                PFQuery *query = [self queryForObjectWithClassName:@"Dish" withName:dishName];
                [query whereKey:@"ofCourse" equalTo:currentCourse];
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    __block PFObject *currentDish = [objects firstObject];
                    
                    // Set the current order and course for the view controller.
                    [dishesController setCurrentOrder:createdOrder];
                    [dishesController setCurrentCourse:currentCourse];
                    
                    // Add the item to the order.
                    [dishesController addOrderItemToOrderForDish:currentDish];
                    
                    // Retrieve the Order Item we created.
                    PFQuery *query = [self queryForObjectWithClassName:@"OrderItem" withName:dishName];
                    [query whereKey:@"forOrder" equalTo:createdOrder];
                    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        __block PFObject *retrievedOrderItem = [objects firstObject];
                        
                        // Include the Order Item we created in the selected Items array.
                        [[discountsController selectedItems] addObject:retrievedOrderItem];
                        
                        // Apply the discount to the order.
                        [discountsController applyNewDiscountToCover:discountCoverage withType:discountType withAmount:discountAmount];
                        
                        // Assign the Order object to the Order controller.
                        [viewOrderController setCurrentOrder:createdOrder];
                        
                        // Download the Order items, which will in turn download and apply all discounts.
                        [viewOrderController getParseData];
                        
                        // Refetch the Order object, so that we can examine the totalPrice.
                        [createdOrder fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                            createdOrder = object;
                            
                            if ([createdOrder[@"totalPrice"] isEqualToNumber:estimatedTotalPrice]) {
                                XCTAssert(YES, @"Discount successfully added to order");
                            } else {
                                XCTAssert(NO, @"Discount failed to be added to order");
                            }
                        }];
                    }];
                }];
            }];
        }];
    }];
}

@end