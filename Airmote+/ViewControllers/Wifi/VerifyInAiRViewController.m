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
  IBOutletCollection(UIView) NSArray *views;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  [self requestConfirmationCode];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)noButtonPressed:(id)sender {
  [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)yesButtonPressed:(id)sender
{
  ChangeNameViewController *changeNameViewController = [[ChangeNameViewController alloc] init];
  [[IAConnection sharedConnection] setDelegate:changeNameViewController];
  [self.navigationController pushViewController:changeNameViewController animated:NO];
}


- (void)requestConfirmationCode {
  Event *ev = [ProtoHelper setupCodeRequest];
  [[IAConnection sharedConnection] sendEvent:ev withTag:0];
}

- (void)didReceiveEvent:(Event *)event
{
  SetupResponseEvent *ev = [event getExtension:[SetupResponseEvent event]];
  NSString *confirmationCode = ev.code;

  switch (ev.phase) {
    case SetupPhaseRequestCode: {
      confirmationCodeLabel.text = confirmationCode;
      [UIView animateWithDuration:1.0 animations:^{
        for (UIView *aView in views) {
          aView.alpha = 1.0;
        }
      } completion:NULL];
      NSLog(@"eventCenter: receivedEvent");

      break;
    }
    default:
      NSLog(@"Event recevied - Phase: %d", ev.phase);
  }

}

@end
