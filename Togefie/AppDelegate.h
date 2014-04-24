//
//  AppDelegate.h
//  Togefie
//
//  Created by Motohiro Takayama on 4/21/14.
//  Copyright (c) 2014 mootoh.net. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Postman;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) Postman *postman;

@end
