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

@interface VerifyInAiRViewController ()

@end

@implementation VerifyInAiRViewController{
  
  __weak IBOutlet UILabel *confirmationCodeLabel;
  IBOutletCollection(UIView) NSArray *views;
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
  for (UIView *aView in views) {
    aView.alpha = 0.0;
  }
  [self requestConfirmationCode];
}


-(void)viewDidAppear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)noButtonPressed:(id)sender {
  [self.navigationController popViewControllerAnimated:NO];
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

      break;
    }
    default:
      NSLog(@"Event recevied - Phase: %d", ev.phase);
  }

}


@end
