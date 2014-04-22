//
//  ViewController.h
//  Togefie
//
//  Created by Motohiro Takayama on 4/21/14.
//  Copyright (c) 2014 mootoh.net. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCAdvertiserAssistantDelegate>

@end

@interface ViewController (MultipeerConnection)

- (void)createSession:(NSString *)displayName;

@end