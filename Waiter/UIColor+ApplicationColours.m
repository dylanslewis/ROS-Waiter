//
//  UIColor+ApplicationColours.m
//  Waiter
//
//  Created by Dylan Lewis on 01/10/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "UIColor+ApplicationColours.h"

@implementation UIColor (ApplicationColours)

+ (UIColor *) waiterGreenColour {
    UIColor *lightGreen = [UIColor colorWithRed:0.078 green:0.404 blue:0.204 alpha:1.0];
    return lightGreen;
}

+ (UIColor *) managerRedColour {
    UIColor *lightGreen = [UIColor colorWithRed:0.663 green:0.118 blue:0.137 alpha:1.0];
    return lightGreen;
}

+ (UIColor *) kitchenBlueColour {
    UIColor *lightGreen = [UIColor colorWithRed:0 green:0.478 blue:1 alpha:1];
    return lightGreen;
}

@end
