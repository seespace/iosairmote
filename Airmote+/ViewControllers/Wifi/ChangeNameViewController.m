//
//  ChangeNameViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/20/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "ChangeNameViewController.h"
#import "WiFiListViewController.h"
#import "Proto.pb.h"
#import "ProtoHelper.h"
#import "IAStateMachine.h"
#import "TKState.h"

@interface ChangeNameViewController ()

@end

@implementation ChangeNameViewController {
  __weak IBOutlet UITextField *textField;

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
  self.title = @"InAiR Name";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextButtonPressed:)];
  if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
    self.edgesForExtendedLayout = UIRectEdgeNone;
  }
  textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 30)];
  textField.leftViewMode = UITextFieldViewModeAlways;

}


- (void)viewDidAppear:(BOOL)animated {
  [IAConnection sharedConnection].delegate = self;
}



- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)didReceiveEvent:(Event *)event
{
  SetupResponseEvent *ev = [event getExtension:[SetupResponseEvent event]];
  switch (ev.phase) {
    case SetupPhaseRequestRename: {
      if (ev.error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:ev.errorMessage
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
      }
      else {
        WiFiListViewController *wifiListVC = [[WiFiListViewController alloc] init];
        [IAConnection sharedConnection].delegate = wifiListVC;
        [self.navigationController pushViewController:wifiListVC animated:YES];
      }
      break;
    }


    default:
      break;
  }

}


- (BOOL)textFieldShouldReturn:(UITextField *)aTextField {
  [self sendRenameRequestWithName:textField.text];
  return YES;
}

- (void)sendRenameRequestWithName:(NSString *)name {
  if ([name length] > 0) {
    Event *ev = [ProtoHelper setupRenameRequestWithName:name];
    [[IAConnection sharedConnection] sendEvent:ev withTag:0];
  }
}
- (IBAction)backPressed:(id)sender {
  [self.navigationController popViewControllerAnimated:NO];
}

@end
