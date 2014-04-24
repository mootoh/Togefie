//
//  SettingViewController.m
//  Togefie
//
//  Created by Motohiro Takayama on 4/22/14.
//  Copyright (c) 2014 mootoh.net. All rights reserved.
//

#import "SettingViewController.h"

static const int k_IMAGE_VIEW_TAG = 7;

@interface SettingViewController ()

@end

@implementation SettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.navigationController.navigationBarHidden = NO;
    self.title = @"Setting";
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(choosePhoto:)];
    UIImageView *imageView = (UIImageView *)[self.view viewWithTag:k_IMAGE_VIEW_TAG];
    [imageView addGestureRecognizer:tgr];
}

- (void) viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Event handlers

- (IBAction)nicknameEntered:(id)sender {
    UITextField *textField = (UITextField *)sender;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:k_NICKNAME_CHANGED object:nil userInfo:@{@"nickname": textField.text}];
}

- (void) choosePhoto:(UIGestureRecognizer *)recognizer {
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    [self addChildViewController:ipc];
    ipc.delegate = self;
    [self.view addSubview:ipc.view];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - ImagePicker delegates

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImageView *imageView = (UIImageView *)[self.view viewWithTag:k_IMAGE_VIEW_TAG];

    UIImage *pickedImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    imageView.image = pickedImage;
    [picker.view removeFromSuperview];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSLog(@"canceld");
}

@end
