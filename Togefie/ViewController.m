//
//  ViewController.m
//  Togefie
//
//  Created by Motohiro Takayama on 4/21/14.
//  Copyright (c) 2014 mootoh.net. All rights reserved.
//

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
@property (nonatomic) UIImagePickerController *cameraUI;
@property (nonatomic) MCAdvertiserAssistant *advertiserAssistant;
@property (nonatomic) MCSession *session;
@property (nonatomic) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic) MCNearbyServiceBrowser *browser;
@property (nonatomic) UIImageView *previewView;
@end

#define k_SERVICE_TYPE @"togefie-service"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

#if TARGET_IPHONE_SIMULATOR
    [self startAdvertise];
#else
    [self startAdvertise];
    [self showCamera];
    //    [self startBrowse];
    [self startBrowseInCamera];
#endif
}

- (void) startAdvertise {
    MCPeerID *peerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
    self.session = [[MCSession alloc] initWithPeer:peerID securityIdentity:nil encryptionPreference:MCEncryptionOptional];
    self.session.delegate = self;

#if 0
    MCNearbyServiceAdvertiser *advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:peerID discoveryInfo:nil serviceType:k_SERVICE_TYPE];
    advertiser.delegate = self;
    [advertiser startAdvertisingPeer];
    self.advertiser = advertiser;
#else
    MCAdvertiserAssistant *assistant = [[MCAdvertiserAssistant alloc] initWithServiceType:k_SERVICE_TYPE discoveryInfo:nil session:self.session];
    assistant.delegate = self;
    [assistant start];
    self.advertiserAssistant = assistant;
#endif // 1
}

#if 0
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser
didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context
 invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}
#endif // 0

- (void) startBrowse {
    MCPeerID *peerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];

    self.session = [[MCSession alloc] initWithPeer:peerID securityIdentity:nil encryptionPreference:MCEncryptionOptional];
    // Set ourselves as the MCSessionDelegate
    self.session.delegate = self;

    // Instantiate and present the MCBrowserViewController
    MCBrowserViewController *browserViewController = [[MCBrowserViewController alloc] initWithServiceType:k_SERVICE_TYPE session:self.session];
    
	browserViewController.delegate = self;
    browserViewController.minimumNumberOfPeers = kMCSessionMinimumNumberOfPeers;
    browserViewController.maximumNumberOfPeers = kMCSessionMaximumNumberOfPeers;
    
    [self presentViewController:browserViewController animated:NO completion:nil];
/*
    MCNearbyServiceBrowser *browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerID serviceType:k_SERVICE_TYPE];
    browser.delegate = self;
    [browser startBrowsingForPeers];
    self.browser = browser;
 */
}

- (void) startBrowseInCamera {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    MCPeerID *peerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
    
    self.session = [[MCSession alloc] initWithPeer:peerID securityIdentity:nil encryptionPreference:MCEncryptionOptional];
    // Set ourselves as the MCSessionDelegate
    self.session.delegate = self;
    
     MCNearbyServiceBrowser *browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerID serviceType:k_SERVICE_TYPE];
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
    [browser invitePeer:peerID toSession:self.session withContext:nil timeout:0];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void) showCamera {
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    if (! [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSLog(@"camera not available");
        return;
    }

    cameraUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    cameraUI.allowsEditing = NO;
    cameraUI.showsCameraControls = NO;
    cameraUI.delegate = self;
    self.cameraUI = cameraUI;

    UIButton *shutterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [shutterButton setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
    [shutterButton addTarget:self action:@selector(shoot) forControlEvents:UIControlEventTouchUpInside];
    shutterButton.frame = CGRectMake(160, 320, 66, 66);
    shutterButton.center = CGPointMake(self.view.center.x, 500);
    [cameraUI.view addSubview:shutterButton];

    UIButton *settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingButton setImage:[UIImage imageNamed:@"setting"] forState:UIControlStateNormal];
    [settingButton addTarget:self action:@selector(shoot) forControlEvents:UIControlEventTouchUpInside];
    settingButton.frame = CGRectMake(320-66, 12, 66, 66);
    [cameraUI.view addSubview:settingButton];

    [self presentViewController:cameraUI animated:NO completion:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cameraIsReady:)
                                                 name:AVCaptureSessionDidStartRunningNotification object:nil];
}

- (void)cameraIsReady:(NSNotification *)notification
{
    NSLog(@"Camera is ready...");
}

- (void) shoot {
    [self.cameraUI takePicture];
}

#pragma mark MCBrowserViewControllerDelegate

// Override this method to filter out peers based on application specific needs
- (BOOL)browserViewController:(MCBrowserViewController *)browserViewController shouldPresentNearbyPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return YES;
}

// Override this to know when the user has pressed the "done" button in the MCBrowserViewController
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [browserViewController dismissViewControllerAnimated:YES completion:^() {
        [self showCamera];
    }];
}

// Override this to know when the user has pressed the "cancel" button in the MCBrowserViewController
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation ViewController (CameraDelegateMethods)

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSLog(@"did cancel");
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"captured");
    
    // show a dialog to choose a peer to send the photo

    if (self.previewView) {
        [self.previewView removeFromSuperview];
        self.previewView = nil;
    }

    // Save the new image to the cache directory
    UIImage *imageToSave = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    UIImageView *preview = [[UIImageView alloc] initWithImage:imageToSave];
    preview.userInteractionEnabled = YES;
    preview.frame = CGRectMake(0, 0, picker.view.frame.size.width, 426);
    [picker.view addSubview:preview];
    
    UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPhoto:)];
    [preview addGestureRecognizer:pgr];

    self.previewView = preview;
    
    // user will choose the photo is good or dispose it
    return;
}

- (void) panPhoto:(UIGestureRecognizer *)gestureRecognizer
{
    NSLog(@"preview photo panned");
    
    UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer *)gestureRecognizer;
    CGPoint translation = [recognizer translationInView:self.cameraUI.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x,
                                         recognizer.view.center.y + translation.y);

    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGFloat finalX = recognizer.view.center.x;
        CGFloat finalY = -900;

        CGPoint velocity = [recognizer velocityInView:self.cameraUI.view];
        if (velocity.y > 0) {
            finalY = 900*2;
            [self sendPhoto:self.previewView.image];
        }

        // Check here for the position of the view when the user stops touching the screen
        // Set "CGFloat finalX" and "CGFloat finalY", depending on the last position of the touch
        // Use this to animate the position of your view to where you want
        [UIView animateWithDuration: 1
                              delay: 0
                            options: UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             CGPoint finalPoint = CGPointMake(finalX, finalY);
                             recognizer.view.center = finalPoint;
                         }
                         completion:^(BOOL finished) {
                             // TODO: remove the preview view here
                         }];
        return;
    }

    [recognizer setTranslation:CGPointMake(0, 0) inView:self.cameraUI.view];
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

- (void) sendPhoto:(UIImage *)image
{
    UIImage *smallerImage = [ViewController imageWithImage:image scaledToSize:CGSizeMake(320, 240)];
    NSData *pngData = UIImageJPEGRepresentation(smallerImage, 1.0);
    
    // send the photo
    // Don't block the UI when writing the image to documents
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // We only handle a still image
        
        // Create a unique file name
        NSDateFormatter *inFormat = [NSDateFormatter new];
        [inFormat setDateFormat:@"yyMMdd-HHmmss"];
        NSString *imageName = [NSString stringWithFormat:@"image-%@.JPG", [inFormat stringFromDate:[NSDate date]]];
        // Create a file path to our documents directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:imageName];
        [pngData writeToFile:filePath atomically:YES]; // Write the file
        // Get a URL for this file resource
        NSURL *imageUrl = [NSURL fileURLWithPath:filePath];
        
        // Send the resource to the remote peers and get the resulting progress transcript
        NSProgress *progress;
        // Loop on connected peers and send the image to each
        for (MCPeerID *peerID in self.session.connectedPeers) {
            progress = [self.session sendResourceAtURL:imageUrl withName:[imageUrl lastPathComponent] toPeer:peerID withCompletionHandler:^(NSError *error) {
                // Implement this block to know when the sending resource transfer completes and if there is an error.
                if (error) {
                    NSLog(@"Send resource to peer [%@] completed with Error [%@]", peerID.displayName, error);
                }
                else {
                    NSLog(@"in progress... ");
                }
            }];
            
        }
    });
}

- (void)createSession:(NSString *)displayName
{
    MCPeerID *peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    // Create the session that peers will be invited/join into.  You can provide an optinal security identity for custom authentication.  Also you can set the encryption preference for the session.
    self.session = [[MCSession alloc] initWithPeer:peerID securityIdentity:nil encryptionPreference:MCEncryptionRequired];
    // Set ourselves as the MCSessionDelegate
    self.session.delegate = self;

    MCNearbyServiceAdvertiser *advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:peerID discoveryInfo:nil serviceType:k_SERVICE_TYPE];
    advertiser.delegate = self;
    [advertiser startAdvertisingPeer];
}

#pragma mark - MCSessionDelegate methods

// Override this method to handle changes to peer session state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"state changed: %@", [self stringForPeerConnectionState:state]);
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
    NSLog(@"finish receiving resource name");
//    UIImageView *imageView = [self.view viewWithTag:7];
    NSData *data = [NSData dataWithContentsOfURL:localURL];
    UIImage *image = [UIImage imageWithData:data];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [self.cameraUI.view addSubview:imageView];
    [self.view layoutSubviews];
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

@end