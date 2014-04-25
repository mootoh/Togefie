//
//  Utils.m
//  Togefie
//
//  Created by Motohiro Takayama on 4/25/14.
//  Copyright (c) 2014 mootoh.net. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (void) saveToCache:(UIImage *)image name:(NSString *)name callback:(void (^)(NSURL *))callback {
    NSData *jpgData = UIImageJPEGRepresentation(image, 1.0);
    
    // send the photo
    // Don't block the UI when writing the image to documents
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // Create a file path to our documents directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:name];
        [jpgData writeToFile:filePath atomically:YES]; // Write the file
        // Get a URL for this file resource
        NSURL *imageUrl = [NSURL fileURLWithPath:filePath];
        callback(imageUrl);
    });
}

// http://stackoverflow.com/questions/2658738/the-simplest-way-to-resize-an-uiimage
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end