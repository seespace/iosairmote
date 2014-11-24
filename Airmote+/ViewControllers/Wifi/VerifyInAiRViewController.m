//
//  VerifyInAiRViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/20/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "VerifyInAiRViewController.h"
#import "Proto.pb.h"
#import "ProtoHelper.h"
#import "TKState.h"
#import "IAStateMachine.h"    ]
#import "ChangeNameViewController.h"

@interface VerifyInAiRViewController ()

@end

@implementation VerifyInAiRViewController{
  __weak IBOutlet UILabel *confirmationCodeLabel;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  confirmationCodeLabel.text = self.confirmationCode;
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)noButtonPressed:(id)sender {
  [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)yesButtonPressed:(id)sender
{
  ChangeNameViewController *changeNameViewController = [[ChangeNameViewController alloc] init];
  [[IAConnection sharedConnection] setDelegate:changeNameViewController];
  [self.navigationController pushViewController:changeNameViewController animated:YES];
}

@end
