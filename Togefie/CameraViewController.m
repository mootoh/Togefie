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

@interface CameraViewController ()
@property (nonatomic) UIImageView *receivedView;
@end

@implementation CameraViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageReceived:) name:k_IMAGE_RECEIVED object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peerJoined:) name:k_PEER_JOINED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peerLeft:) name:k_PEER_LEFT object:nil];

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
    receivedView.userInteractionEnabled = YES;
    [receivedView addSubview:dismissReceivedImageButton];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cameraIsReady:)
                                                 name:AVCaptureSessionDidStartRunningNotification object:nil];
}

- (void) dismissReceivedImage {
    [UIView animateWithDuration:0.3 animations:^() {
        self.receivedView.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.receivedView.hidden = YES;
        self.receivedView.alpha = 1.0;
    }];
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
    retakeButton.frame = CGRectMake(160, 320, 66, 66);
    retakeButton.center = picker.view.center;
    [retakeButton setBackgroundImage:[UIImage imageNamed:@"retake"] forState:UIControlStateNormal];
    [retakeButton addTarget:self action:@selector(retake) forControlEvents:UIControlEventTouchUpInside];
    [preview addSubview:retakeButton];

    AppDelegate *ad = [UIApplication sharedApplication].delegate;
    Postman *postman = ad.postman;

    int offsetX = 32;
    for (MCPeerID *peerID in postman.session.connectedPeers) {
        PeerViewController *pvc = [[PeerViewController alloc] initWithNibName:nil bundle:nil];
        pvc.view.frame = CGRectMake(offsetX, 426-64, 92, 92);
        pvc.peerID = peerID;

        pvc.nameLabel.text = peerID.displayName;

        [self addChildViewController:pvc];
        [self.view addSubview:pvc.view];
        [pvc didMoveToParentViewController:self];
    }

    [UIView animateWithDuration:0.3 animations:^() {
        preview.alpha = 1.0;
    }];
    
//    UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPhoto:)];
//    [preview addGestureRecognizer:pgr];

    return;
}

- (void) retake {
    if (self.previewView) {
        [self.previewView removeFromSuperview];
        self.previewView = nil;
    }
    for (UIViewController *vc in self.childViewControllers) {
        if ([vc isKindOfClass:[PeerViewController class]]) {
            [vc.view removeFromSuperview];
            [vc removeFromParentViewController];
        }
    }
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
    UIImage *smallerImage = [CameraViewController imageWithImage:image scaledToSize:CGSizeMake(32, 24)];
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
    NSString *nickname = dict[@"nickname"];
    NSLog(@"peer %@ joined", nickname);
    UILabel *joined = [[UILabel alloc] initWithFrame:CGRectMake(240, 300, 80, 32)];
    joined.text = nickname;

    dispatch_async(dispatch_get_main_queue(), ^() {
        [self.cameraOverlayView addSubview:joined];

        [UIView animateWithDuration:1 animations:^() {
            joined.frame = CGRectMake(400, 300, 80, 32);
        }];

    });
}

- (void) peerLeft:(NSNotification *)notification {
    NSDictionary *dict = notification.userInfo;
    NSString *nickname = dict[@"nickname"];
    NSLog(@"peer left %@", nickname);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end