//
//  Postman.h
//  Togefie
//
//  Created by Motohiro Takayama on 4/22/14.
//  Copyright (c) 2014 mootoh.net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "CameraViewController.h"

@interface Postman : NSObject <MCSessionDelegate, MCNearbyServiceBrowserDelegate>

@property (nonatomic) NSString *nickname;
@property (nonatomic) MCSession *session;
@property (nonatomic) CameraViewController *cameraViewController; // FIXME

- (void) startAdvertise:(id <MCNearbyServiceAdvertiserDelegate>)advertiserDelegate;
- (void) startBrowse;

- (void) sendPhoto:(NSURL *)url;
- (NSProgress *) sendPhoto:(NSURL *)url to:(MCPeerID *)peerID;

@end