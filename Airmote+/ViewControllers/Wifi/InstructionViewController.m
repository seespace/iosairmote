//
//  InstructionViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/19/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "InstructionViewController.h"
#import "ChangeNameViewController.h"
#import "Proto.pb.h"
#import "SVProgressHUD.h"
#import "NSData+NetService.h"
#import "ProtoHelper.h"
#import "WifiHelper.h"

#define MAX_RETRY_COUNT 3

@interface InstructionViewController ()

@end

@implementation InstructionViewController {
  __weak IBOutlet UIView *connectedContainerView;
  __weak IBOutlet UILabel *confirmationCodeLabel;
  __weak IBOutlet UILabel *instructionLabel;
  BonjourManager *_bonjourManager;

  BOOL isConnecting;
  BOOL isDiscoveringBonjourServices;

  int retryCount;
  int resolveServiceRetryCount;
  NSNetService *_netService;
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
  self.title = @"Setup InAiR";

  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain
                                                                           target:self action:@selector(nextButtonPressed:)];
  _bonjourManager = [[BonjourManager alloc] init];
  _bonjourManager.delegate = self;

  self.navigationItem.rightBarButtonItem.enabled = NO;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
}

- (void)didBecomeActive:(NSNotification *)notification {
    if (![WifiHelper isConnectedToInAiRWiFi]) {
        [SVProgressHUD showErrorWithStatus:@"Not connected to an InAiR network"];
    } else {
        if (![EventCenter defaultCenter].isActive && !isDiscoveringBonjourServices && (self == self.navigationController.topViewController)) {
            isDiscoveringBonjourServices = YES;
            [_bonjourManager start];
        }
    }

}


- (void)viewDidAppear:(BOOL)animated {
  [EventCenter defaultCenter].delegate = self;
}

- (void)nextButtonPressed:(id)sender {
  ChangeNameViewController *nameViewController = [[ChangeNameViewController alloc] init];
  [EventCenter defaultCenter].delegate = nameViewController;
//    _bonjourManager.delegate = nil
  [self.navigationController pushViewController:nameViewController animated:YES];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)bonjourManagerFinishedDiscoveringServices:(NSArray *)services {
  isDiscoveringBonjourServices = NO;
  if ([services count]) {
    retryCount = 0;
    resolveServiceRetryCount = 0;
    _netService.delegate = nil;
    _netService = services[0];
    _netService.delegate = self;
    [_netService resolveWithTimeout:10];

  } else {
    [self restartBonjourIfNeeded];
  }
}

- (void)restartBonjourIfNeeded {
  if (retryCount < MAX_RETRY_COUNT && !isDiscoveringBonjourServices) {
    isDiscoveringBonjourServices = NO;
    [_bonjourManager start];
    retryCount++;
  }
}

- (void)bonjourManagerServiceNotFound {
  isDiscoveringBonjourServices = NO;
  [self restartBonjourIfNeeded];
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
  NSLog(@"Failed to resolve address for service: %@", sender);
  if (resolveServiceRetryCount < MAX_RETRY_COUNT) {
    resolveServiceRetryCount++;
    [_netService resolveWithTimeout:10];
  }

}


- (void)netServiceDidResolveAddress:(NSNetService *)service {
  if ([service.addresses count]) {
    resolveServiceRetryCount = 0;
    _netService.delegate = nil;
    NSString *address = [(service.addresses)[0] socketAddress];
    [self connectToHost:address];
  }

}


- (void)connectToHost:(NSString *)hostname {
  if (isConnecting)
    return;

  EventCenter *eventCenter = [EventCenter defaultCenter];
  eventCenter.delegate = nil;

  eventCenter = [EventCenter defaultCenter];
  eventCenter.delegate = self;
  isConnecting = [eventCenter connectToHost:hostname];
  if (isConnecting) {
    [SVProgressHUD showWithStatus:@"Connecting" maskType:SVProgressHUDMaskTypeBlack];
  }
}

- (void)eventCenterDidConnect {
  [SVProgressHUD dismiss];
  isConnecting = NO;
  [self requestConfirmationCode];
}

- (void)requestConfirmationCode {
  Event *ev = [ProtoHelper setupCodeRequest];
  [[EventCenter defaultCenter] sendEvent:ev withTag:0];
}

- (void)eventCenterDidDisconnectWithError:(NSError *)error {
  [SVProgressHUD dismiss];
  //TODO show retry button??
  isConnecting = NO;
}

- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event {
  SetupResponseEvent *ev = [event getExtension:[SetupResponseEvent event]];
  NSString *confirmationCode = ev.code;

  switch (ev.phase) {
    case SetupPhaseRequestCode: {
      confirmationCodeLabel.text = confirmationCode;
      [SVProgressHUD dismiss];
      [UIView animateWithDuration:0.5 animations:^{
        instructionLabel.alpha = 0.0;
      }                completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
          connectedContainerView.alpha = 1.0;
        }];
      }];

      self.navigationItem.rightBarButtonItem.enabled = YES;
      break;
    }
    default:
      NSLog(@"Event recevied - Phase: %d", ev.phase);
  }

}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
