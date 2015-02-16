//
//  WSInstructionController.m
//  Airmote+
//
//  Created by Long Nguyen on 2/12/15.
//  Copyright (c) 2015 Long Nguyen. All rights reserved.
//

#import "WSInstructionController.h"
#import "JDStatusBarNotification+Extension.h"
#import "MBSetupPageSection.h"
#import "MBSectionHeader.h"
#import "MBSectionFooter.h"
#import "IAConnection.h"

@interface WSInstructionController ()

@end

@implementation WSInstructionController

- (void)viewDidLoad {
//  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.

  __weak WSInstructionController *weakSelf = self;

  weakSelf.nextButtonItem.enabled = [[IAConnection sharedConnection] isConnected];

  if ([IAConnection sharedConnection].isConnected) {
    [self proceedToNextPage];
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [IAConnection sharedConnection].delegate = self;
  [self.navigationController setNavigationBarHidden:true];
}

- (void)viewWillDisappear:(BOOL)animated {
  [self.navigationController setNavigationBarHidden:false];
}

- (void)didStartUSBConnection {
  [self proceedToNextPage];
}

- (void)didConnect:(NSString *)hostName {
  [self proceedToNextPage];
}

- (IBAction)cancel:(id)sender {
  [self dismissViewControllerAnimated:true completion:nil];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
