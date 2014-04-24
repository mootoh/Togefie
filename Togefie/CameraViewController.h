//
//  CameraViewController.h
//  Togefie
//
//  Created by Motohiro Takayama on 4/22/14.
//  Copyright (c) 2014 mootoh.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CameraViewController : UIImagePickerController <UIImagePickerControllerDelegate>

@property (nonatomic) UIImageView *previewView;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end