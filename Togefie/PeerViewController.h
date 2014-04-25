//
//  PeerViewController.h
//  Togefie
//
//  Created by Motohiro Takayama on 4/24/14.
//  Copyright (c) 2014 mootoh.net. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MCPeerID;
@class PeerViewController;

@protocol PeerViewControllerDelegate
- (void) beginSend:(PeerViewController *)pvc;
- (void) didSend:(PeerViewController *)pvc;
@end

@interface PeerViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) MCPeerID *peerID;
@property (nonatomic) BOOL hidden;
@property (weak, nonatomic) id <PeerViewControllerDelegate> delegate;

@end
