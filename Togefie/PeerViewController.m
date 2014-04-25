//
//  PeerViewController.m
//  Togefie
//
//  Created by Motohiro Takayama on 4/24/14.
//  Copyright (c) 2014 mootoh.net. All rights reserved.
//

#import "PeerViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "CameraViewController.h"
#import "AppDelegate.h"
#import "Postman.h"
#import "Utils.h"

@interface PeerViewController ()
@property (nonatomic) NSProgress *progress;
@end

@implementation PeerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.hidden = NO;
    // Do any additional setup after loading the view from its nib.
    self.progressView.hidden = YES;

    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendToPeer:)];
    [self.view addGestureRecognizer:tgr];
}

- (void) viewWillDisappear:(BOOL)animated {
    if (self.progress) {
        [self.progress removeObserver:self forKeyPath:kProgressCancelledKeyPath];
        [self.progress removeObserver:self forKeyPath:kProgressCompletedUnitCountKeyPath];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSProgress *progress = object;
    
    // Check which KVO key change has fired
    if ([keyPath isEqualToString:kProgressCancelledKeyPath]) {
        // Notify the delegate that the progress was cancelled
        //        [self.delegate observerDidCancel:self];
    }
    else if ([keyPath isEqualToString:kProgressCompletedUnitCountKeyPath]) {
        // Notify the delegate of our progress change
        //        [self.delegate observerDidChange:self];
        dispatch_async(dispatch_get_main_queue(), ^() {
            self.progressView.progress = (float)progress.completedUnitCount / (float)progress.totalUnitCount;
            NSLog(@"progress... %f", (float)progress.completedUnitCount / (float)progress.totalUnitCount);
        });

         if (progress.completedUnitCount == progress.totalUnitCount) {
             // Progress completed, notify delegate
             dispatch_async(dispatch_get_main_queue(), ^() {
                 self.progressView.hidden = YES;
                 self.view.userInteractionEnabled = YES;
                 [UIView animateWithDuration:0.3 animations:^() {
                     self.view.alpha = 0.5;
                 }];
             });
             if (self.delegate) {
                 [self.delegate didSend:self];
             }
         }
    }
}

- (void) sendToPeer:(UIGestureRecognizer *)recognizer {
    if (self.delegate) {
        [self.delegate beginSend:self];
    }

    CameraViewController *cvc = (CameraViewController *)self.parentViewController;

    UIImage *smallerImage = [Utils imageWithImage:cvc.previewView.image scaledToSize:CGSizeMake(32*5, 24*5)];
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
        
        NSProgress *progress = [ad.postman sendPhoto:imageUrl to:self.peerID];
        self.progress = progress;
        // Add KVO observer for the cancelled and completed unit count properties of NSProgress
        [progress addObserver:self forKeyPath:kProgressCancelledKeyPath options:NSKeyValueObservingOptionNew context:NULL];
        [progress addObserver:self forKeyPath:kProgressCompletedUnitCountKeyPath options:NSKeyValueObservingOptionNew context:NULL];
        dispatch_async(dispatch_get_main_queue(), ^() {
            self.progressView.hidden = NO;
            self.view.userInteractionEnabled = NO;
            [UIView animateWithDuration:0.3 animations:^() {
                self.view.alpha = 1.0;
            }];
        });
    });
}

@end