//
//  PeerViewController.h
//  Togefie
//
//  Created by Motohiro Takayama on 4/24/14.
//  Copyright (c) 2014 mootoh.net. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MCPeerID;

@interface PeerViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) MCPeerID *peerID;
@end
