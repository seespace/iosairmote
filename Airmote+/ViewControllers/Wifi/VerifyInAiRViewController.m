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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [self configureStateMachine];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self requestConfirmationCode];
}

- (void)configureStateMachine {
  TKState *nameChangingState = [[IAStateMachine sharedStateMachine] stateNamed:kStateSetupChangeName];
  [nameChangingState setWillEnterStateBlock:^(TKState *state, TKTransition *transition) {
    if ([[IAStateMachine sharedStateMachine] isInState:kStateSetupCodeVerification]) {
      ChangeNameViewController *changeNameViewController = [[ChangeNameViewController alloc] init];
      [[EventCenter defaultCenter] setDelegate:changeNameViewController];
      [self.navigationController pushViewController:changeNameViewController animated:NO];
    }
  }];

  [[[IAStateMachine sharedStateMachine] stateNamed:kStateSetupCodeVerification] setDidExitStateBlock:^(TKState *state, TKTransition *transition) {
    if ([[IAStateMachine sharedStateMachine] isInState:kStateWifiSetupStart]) {
      [self.navigationController popViewControllerAnimated:NO];
    }
  }];
}


-(void)viewDidAppear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)noButtonPressed:(id)sender {
  [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupFailedToRetrieveConfirmationCode];
}


- (IBAction)yesButtonPressed:(id)sender
{
  [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupSameCodeVerified];
}


- (void)requestConfirmationCode {
  Event *ev = [ProtoHelper setupCodeRequest];
  [[EventCenter defaultCenter] sendEvent:ev withTag:0];
}

- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event {
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
      [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupCodeVerificationReceived];

      break;
    }
    default:
      NSLog(@"Event recevied - Phase: %d", ev.phase);
  }

}


@end
