//
//  Utils.h
//  Togefie
//
//  Created by Motohiro Takayama on 4/25/14.
//  Copyright (c) 2014 mootoh.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

+ (void) saveToCache:(UIImage *)image name:(NSString *)name callback:(void (^)(NSURL *))callback;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end