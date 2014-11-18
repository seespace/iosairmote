//
//  InstructionViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/19/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "InstructionViewController.h"
#import "VerifyInAiRViewController.h"
#import "SVProgressHUD.h"
#import "NSData+NetService.h"
#import "WifiHelper.h"
#import "TKState.h"
#import "IAStateMachine.h"
#import "IAConnection.h"

@interface InstructionViewController ()

@end

@implementation InstructionViewController {
  __weak IBOutlet UILabel *instructionLabel;
  BOOL viewDidAppear;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [IAConnection sharedConnection].delegate = self;
}



- (void)connectIfNeeded {
}


- (void)viewDidAppear:(BOOL)animated {
  [IAConnection sharedConnection].delegate = self;
  if (viewDidAppear) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [self connectIfNeeded];
    });

  }
  viewDidAppear = YES;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}



- (void)showVerificationViewController {
  VerifyInAiRViewController *verifyVC = [[VerifyInAiRViewController alloc] init];
  [IAConnection sharedConnection].delegate = verifyVC;
  [self.navigationController pushViewController:verifyVC animated:NO];

}

@end
