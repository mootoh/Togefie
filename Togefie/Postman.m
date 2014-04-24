//
//  Postman.m
//  Togefie
//
//  Created by Motohiro Takayama on 4/22/14.
//  Copyright (c) 2014 mootoh.net. All rights reserved.
//

#import "Postman.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface Postman ()
@property (nonatomic) MCAdvertiserAssistant *advertiserAssistant;
@property (nonatomic) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic) MCNearbyServiceBrowser *browser;
@property (nonatomic) NSDate *advertiseStartedAt;
@property (nonatomic) MCPeerID *peerID;
@end

@implementation Postman

- (id) init {
    self = [super init];
    if (self) {
        self.nickname = [UIDevice currentDevice].name;

        self.peerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];

        self.session = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionOptional];
        self.session.delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nicknameChanged:) name:k_NICKNAME_CHANGED object:nil];
    }
    return self;
}

- (void) nicknameChanged:(NSNotification *)notification {
    NSDictionary *dict = notification.userInfo;
    NSLog(@"nickname changed to: %@", dict[@"nickname"]);
    [[NSUserDefaults standardUserDefaults] setObject:dict[@"nickname"] forKey:@"nickname"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Advertiser

- (void) startAdvertise {
    self.advertiseStartedAt = [NSDate date];
    NSDictionary *discoveryInfo = @{@"timestamp": [NSString stringWithFormat:@"%lf", [self.advertiseStartedAt timeIntervalSince1970]]};

    self.advertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:k_SERVICE_TYPE discoveryInfo:discoveryInfo session:self.session];
    [self.advertiserAssistant start];
}

#pragma mark - Browser

- (void) startBrowse {
    MCNearbyServiceBrowser *browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:k_SERVICE_TYPE];
    browser.delegate = self;
    [browser startBrowsingForPeers];
    self.browser = browser;
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if ([peerID.displayName isEqualToString:[UIDevice currentDevice].name]) {
        NSLog(@"skipping same device");
        return;
    }


    double me = [[NSString stringWithFormat:@"%lf", [self.advertiseStartedAt timeIntervalSince1970]] doubleValue];
    double other = [info[@"timestamp"] doubleValue];

    if (other > me) {
        NSLog(@"found peer %@ started the advertising later from this. Skip it", peerID.displayName);
        return;
    }

    for (MCPeerID *connectedPeer in self.session.connectedPeers) {
        if ([connectedPeer.displayName isEqualToString:peerID.displayName]) {
            NSLog(@"%@ already connected, skip", peerID.displayName);
            return;
        }
    }

    [browser invitePeer:peerID toSession:self.session withContext:nil timeout:0];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark - MCSessionDelegate methods

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    NSLog(@"state changed: %@", [self stringForPeerConnectionState:state]);
    if (state == MCSessionStateConnected)
        [[NSNotificationCenter defaultCenter] postNotificationName:k_PEER_JOINED object:nil userInfo:@{@"nickname": peerID.displayName}];
    else if (state == MCSessionStateNotConnected) {
        [[NSNotificationCenter defaultCenter] postNotificationName:k_PEER_LEFT object:nil userInfo:@{@"nickname": peerID.displayName}];
    }
}

// MCSession Delegate callback when receiving data from a peer in a given session
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSLog(@"received data");
}

// MCSession delegate callback when we start to receive a resource from a peer in a given session
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSLog(@"Start receiving resource [%@] from peer %@ with progress [%@]", resourceName, peerID.displayName, progress);
}

// MCSession delegate callback when a incoming resource transfer ends (possibly with error)
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    if (error) {
        NSLog(@"failed in receiving resource: %@", error);
        return;
    }
    NSLog(@"finish receiving resource: %@", resourceName);

    [[NSNotificationCenter defaultCenter] postNotificationName:k_IMAGE_RECEIVED object:nil userInfo:@{@"url": localURL}];
}

// Streaming API not utilized in this sample code
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Received data over stream with name %@ from peer %@", streamName, peerID.displayName);
}

// Helper method for human readable printing of MCSessionState.  This state is per peer.
- (NSString *)stringForPeerConnectionState:(MCSessionState)state
{
    switch (state) {
        case MCSessionStateConnected:
            return @"Connected";
            
        case MCSessionStateConnecting:
            return @"Connecting";
            
        case MCSessionStateNotConnected:
            return @"Not Connected";
    }
}

- (void) sendPhoto:(NSURL *)url {
    NSLog(@"sending photo.......");
    NSProgress *progress;

    for (MCPeerID *peerID in self.session.connectedPeers) {
        progress = [self.session sendResourceAtURL:url withName:[url lastPathComponent] toPeer:peerID withCompletionHandler:^(NSError *error) {
            // Implement this block to know when the sending resource transfer completes and if there is an error.
            if (error) {
                NSLog(@"Send resource to peer [%@] completed with Error [%@]", peerID.displayName, error);
            }
            else {
                NSLog(@"in progress... ");
            }
        }];
        
    }
}

- (NSProgress *) sendPhoto:(NSURL *)url to:(MCPeerID *)peerID {
    NSLog(@"sending photo to %@...", peerID.displayName);
    
    return [self.session sendResourceAtURL:url withName:[url lastPathComponent] toPeer:peerID withCompletionHandler:^(NSError *error) {
        // Implement this block to know when the sending resource transfer completes and if there is an error.
        if (error) {
            NSLog(@"Send resource to peer [%@] completed with Error [%@]", peerID.displayName, error);
        }
        else {
            NSLog(@"photo sent to %@", peerID.displayName);
        }
    }];
}

@end