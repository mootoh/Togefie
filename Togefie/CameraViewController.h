//
//  CameraViewController.h
//  Togefie
//
//  Created by Motohiro Takayama on 4/22/14.
//  Copyright (c) 2014 mootoh.net. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "PeerViewController.h"

@interface CameraViewController : UIImagePickerController <UIImagePickerControllerDelegate, MCNearbyServiceAdvertiserDelegate, PeerViewControllerDelegate>

@property (nonatomic) UIImageView *previewView;

- (void)didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context withSession:(MCSession *)session invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler;

@end