//
//  CameraViewController.m
//  Togefie
//
//  Created by Motohiro Takayama on 4/22/14.
//  Copyright (c) 2014 mootoh.net. All rights reserved.
//

#import "CameraViewController.h"
#import "SettingViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AppDelegate.h"
#import "Postman.h"
#import "PeerViewController.h"
#import "Utils.h"

static const int k_RETAKE_BUTTON_TAG = 19;

@interface CameraViewController ()
@property (nonatomic) UIImageView *receivedView;
@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    AppDelegate *ad = [UIApplication sharedApplication].delegate;
    [ad.postman startAdvertise:self];
    [ad.postman startBrowse];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageReceived:) name:k_IMAGE_RECEIVED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peerJoined:) name:k_PEER_JOINED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peerLeft:) name:k_PEER_LEFT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profileImageReceived:) name:k_PROFILE_IMAGE_RECEIVED object:nil];

    if (! [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSLog(@"camera not available");

        UIButton *settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [settingButton setImage:[UIImage imageNamed:@"setting"] forState:UIControlStateNormal];
        [settingButton addTarget:self action:@selector(gotoSetting) forControlEvents:UIControlEventTouchUpInside];
        settingButton.frame = CGRectMake(320-66, 12, 66, 66);
        [self.view addSubview:settingButton];
        return;
    }

    self.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    self.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.allowsEditing = NO;
    self.showsCameraControls = NO;
    self.delegate = self;
    
    UIView *overlayView = [[UIView alloc] initWithFrame:self.view.frame];
    overlayView.alpha = 1.0;
    overlayView.backgroundColor = [UIColor clearColor];
    self.cameraOverlayView = overlayView;
    
    UIButton *shutterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [shutterButton setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
    [shutterButton addTarget:self action:@selector(shoot) forControlEvents:UIControlEventTouchUpInside];
    shutterButton.frame = CGRectMake(160, 320, 66, 66);
//    shutterButton.center = CGPointMake(self.view.center.x, 500);
    shutterButton.center = CGPointMake(self.view.center.x, 400);
    [overlayView addSubview:shutterButton];
    
    UIButton *settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingButton setImage:[UIImage imageNamed:@"setting"] forState:UIControlStateNormal];
    [settingButton addTarget:self action:@selector(gotoSetting) forControlEvents:UIControlEventTouchUpInside];
    settingButton.frame = CGRectMake(320-66, 12, 66, 66);
    [overlayView addSubview:settingButton];

    UIImageView *receivedView = [[UIImageView alloc] initWithFrame:self.view.frame];
    receivedView.hidden = YES;
    receivedView.userInteractionEnabled = YES;
    [overlayView addSubview:receivedView];
    self.receivedView = receivedView;
/*
    UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(receivedViewPanned)];
    [receivedView addGestureRecognizer:pgr];
 */
    UIButton *dismissReceivedImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [dismissReceivedImageButton setImage:[UIImage imageNamed:@"retake"] forState:UIControlStateNormal];
    [dismissReceivedImageButton addTarget:self action:@selector(dismissReceivedImage) forControlEvents:UIControlEventTouchUpInside];
    dismissReceivedImageButton.frame = CGRectMake(64, 64, 64, 64);
    dismissReceivedImageButton.center = receivedView.center;
    [receivedView addSubview:dismissReceivedImageButton];

    UIButton *saveReceivedImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [saveReceivedImageButton setImage:[UIImage imageNamed:@"save"] forState:UIControlStateNormal];
    [saveReceivedImageButton addTarget:self action:@selector(saveReceivedImage) forControlEvents:UIControlEventTouchUpInside];
    saveReceivedImageButton.frame = CGRectMake(64, 64, 64, 64);
    saveReceivedImageButton.center = CGPointMake(receivedView.center.x, receivedView.center.y + 64 + 24);
    [receivedView addSubview:saveReceivedImageButton];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cameraIsReady:)
                                                 name:AVCaptureSessionDidStartRunningNotification object:nil];
}

- (void) dismissReceivedImage {
    dispatch_async(dispatch_get_main_queue(), ^() {
        [UIView animateWithDuration:0.3 animations:^() {
            self.receivedView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.receivedView.hidden = YES;
            self.receivedView.alpha = 1.0;
        }];
    });
}

- (void) saveReceivedImage {
//    UIImageWriteToSavedPhotosAlbum(self.receivedView.image, self, @selector(dismissReceivedImage), nil);
    UIImageWriteToSavedPhotosAlbum(self.receivedView.image, nil, nil, nil);
    [self dismissReceivedImage];
}

- (void)cameraIsReady:(NSNotification *)notification {
    NSLog(@"Camera is ready...");
}

- (void) shoot {
    [self takePicture];
}

- (void) gotoSetting {
    SettingViewController *vc = [[SettingViewController alloc] initWithNibName:@"SettingViewController" bundle:nil];
    [self pushViewController:vc animated:YES];
}

#pragma mark ImagePickerDelegate

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSLog(@"did cancel");
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // show a dialog to choose a peer to send the photo
    dispatch_async(dispatch_get_main_queue(), ^() {
        if (self.previewView) {
            [self.previewView removeFromSuperview];
            self.previewView = nil;
        }
        
        UIImage *imageToSave = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
        UIImageView *preview = [[UIImageView alloc] initWithImage:imageToSave];
        preview.userInteractionEnabled = YES;
        preview.frame = CGRectMake(0, 0, picker.view.frame.size.width, 426);
        self.previewView = preview;
        preview.alpha = 0.0;
        [picker.cameraOverlayView addSubview:preview];
        
        UIButton *retakeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        retakeButton.tag = k_RETAKE_BUTTON_TAG;
        retakeButton.frame = CGRectMake(160, 320, 66, 66);
        retakeButton.center = picker.view.center;
        [retakeButton setBackgroundImage:[UIImage imageNamed:@"retake"] forState:UIControlStateNormal];
        [retakeButton addTarget:self action:@selector(retake) forControlEvents:UIControlEventTouchUpInside];
        [preview addSubview:retakeButton];

        for (UIViewController *vc in self.childViewControllers) {
            if (! [vc isKindOfClass:[PeerViewController class]])
                continue;
            PeerViewController *pvc = (PeerViewController *)vc;
            CGFloat y = pvc.view.center.y;
            
            [UIView animateWithDuration:0.3 animations:^() {
                pvc.view.alpha = 0.5;
                pvc.view.center = CGPointMake(pvc.view.center.x, y - 300);
                pvc.hidden = NO;
            }];
        }
        
        [UIView animateWithDuration:0.3 animations:^() {
            preview.alpha = 1.0;
        }];
    });
}

- (void) retake {
    dispatch_async(dispatch_get_main_queue(), ^() {
        if (self.previewView) {
            [self.previewView removeFromSuperview];
            self.previewView = nil;
        }
        
        for (UIViewController *vc in self.childViewControllers) {
            if (! [vc isKindOfClass:[PeerViewController class]])
                continue;
            PeerViewController *pvc = (PeerViewController *)vc;
            if (pvc.hidden)
                continue;
            CGFloat y = pvc.view.center.y;
            
            [UIView animateWithDuration:0.3 animations:^() {
                pvc.view.alpha = 0;
                pvc.view.center = CGPointMake(pvc.view.center.x, y + 300);
                pvc.hidden = YES;
            }];
        };
    });
}

- (void) panPhoto:(UIGestureRecognizer *)gestureRecognizer
{
    UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer *)gestureRecognizer;
    CGPoint translation = [recognizer translationInView:self.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x,
                                         recognizer.view.center.y + translation.y);
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGFloat finalX = recognizer.view.center.x;
        CGFloat finalY = -900;
        
        CGPoint velocity = [recognizer velocityInView:self.view];
        if (velocity.y > 0) {
            finalY = 900*2;
            [self sendPhoto:self.previewView.image];
        }
        
        // Check here for the position of the view when the user stops touching the screen
        // Set "CGFloat finalX" and "CGFloat finalY", depending on the last position of the touch
        // Use this to animate the position of your view to where you want
        [UIView animateWithDuration: 0.3
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
    
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
}

- (void) sendPhoto:(UIImage *)image
{
    UIImage *smallerImage = [Utils imageWithImage:image scaledToSize:CGSizeMake(32, 24)];
    NSData *jpgData = UIImageJPEGRepresentation(smallerImage, 1.0);
    
    // send the photo
    // Don't block the UI when writing the image to documents
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // We only handle a still image
        
        // Create a unique file name
        NSDateFormatter *inFormat = [NSDateFormatter new];
        [inFormat setDateFormat:@"yyMMdd-HHmmss"];
        NSString *imageName = [NSString stringWithFormat:@"image-%@.jpg", [inFormat stringFromDate:[NSDate date]]];
        // Create a file path to our documents directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:imageName];
        [jpgData writeToFile:filePath atomically:YES]; // Write the file
        // Get a URL for this file resource
        NSURL *imageUrl = [NSURL fileURLWithPath:filePath];
        
        // Send the resource to the remote peers and get the resulting progress transcript
        // Loop on connected peers and send the image to each
        
        AppDelegate *ad = [UIApplication sharedApplication].delegate;
        [ad.postman sendPhoto:imageUrl];
    });
}

#pragma mark - Notification Callbacks

- (void) imageReceived:(NSNotification *)notification {
    NSDictionary *dict = notification.userInfo;
    NSURL *localURL = dict[@"url"];

    NSData *data = [NSData dataWithContentsOfURL:localURL];
    UIImage *image = [UIImage imageWithData:data];

    dispatch_async(dispatch_get_main_queue(), ^() {
        self.receivedView.image = image;
        self.receivedView.hidden = NO;
    });
}

- (void) peerJoined:(NSNotification *)notification {
    NSDictionary *dict = notification.userInfo;
    MCPeerID *peerID = dict[@"peerID"];
    NSLog(@"peer %@ joined", peerID.displayName);

    for (UIViewController *vc in self.childViewControllers) {
        if (! [vc isKindOfClass:[PeerViewController class]])
            continue;

        PeerViewController *pvc = (PeerViewController *)vc;
        if (pvc && [pvc.peerID isEqual:peerID]) {
            NSLog(@"PeerView already exists, skip");
            return;
        }
    }

    [self createPeerView:peerID image:nil];
}

- (void) peerLeft:(NSNotification *)notification {
    NSDictionary *dict = notification.userInfo;
    MCPeerID *peerID = dict[@"peerID"];
    NSLog(@"peer left %@", peerID.displayName);

    for (UIViewController *vc in self.childViewControllers) {
        if (! [vc isKindOfClass:[PeerViewController class]])
            continue;
        PeerViewController *pvc = (PeerViewController *)vc;
        if (pvc && [pvc.peerID isEqual:peerID]) {
            dispatch_async(dispatch_get_main_queue(), ^() {
                pvc.view.center = self.view.center;
                pvc.view.alpha = 1.0;
                pvc.hidden = NO;

                [UIView animateWithDuration:1 animations:^() {
                    pvc.view.alpha = 0.0;
                    pvc.view.center = CGPointMake(pvc.view.center.x, -100);
                } completion:^(BOOL finished) {
                    [pvc removeFromParentViewController];
                    [pvc.view removeFromSuperview];
                }];
            });
            return;
        }
    }
}

- (void) profileImageReceived:(NSNotification *)notification {
    NSDictionary *dict = notification.userInfo;
    NSURL *localURL = dict[@"url"];
    MCPeerID *peerID = dict[@"peerID"];
    
    NSData *data = [NSData dataWithContentsOfURL:localURL];
    UIImage *image = [UIImage imageWithData:data];
    
    for (UIViewController *vc in self.childViewControllers) {
        if (! [vc isKindOfClass:[PeerViewController class]])
            continue;
        PeerViewController *pvc = (PeerViewController *)vc;
        if (pvc && [pvc.peerID isEqual:peerID]) {
            dispatch_async(dispatch_get_main_queue(), ^() {
                pvc.imageView.image = image;
            });
            return;
        }
    }
}

#pragma mark - Advertiser delegates

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"didNotStartAdvertisingPeer: error=%@", error);
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler {
    UIImage *image = [UIImage imageWithData:context];
    [self createPeerView:peerID image:image];
    
    AppDelegate *ad = [UIApplication sharedApplication].delegate;
    invitationHandler(YES, ad.postman.session);
}

#pragma mark -

- (void) createPeerView:(MCPeerID *)peerID image:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^() {
        PeerViewController *pvc = [[PeerViewController alloc] initWithNibName:@"PeerViewController" bundle:nil];
        pvc.hidden = NO;
        pvc.delegate = self;
        
        pvc.view.frame = CGRectMake(32, 426-64, 92, 92);
        pvc.view.center = CGPointMake(self.view.center.x, self.view.center.y);

        pvc.peerID = peerID;
        pvc.nameLabel.text = peerID.displayName;
        if (image)
            pvc.imageView.image = image;
        
        [self addChildViewController:pvc];
        [self.view addSubview:pvc.view];
        [pvc didMoveToParentViewController:self];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.5 animations:^() {
                pvc.view.center = CGPointMake(self.view.center.x, self.view.center.y + 400);
                pvc.view.alpha = 0;
            } completion:^(BOOL finished) {
                pvc.hidden = YES;
            }];
        });
    });
}

- (void) beginSend:(PeerViewController *)pvc {
    [[self.view viewWithTag:k_RETAKE_BUTTON_TAG] removeFromSuperview];
}

- (void) didSend:(PeerViewController *)pvc {
    [self retake];
}

@end