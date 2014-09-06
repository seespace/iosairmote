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
#import "FXBlurView.h"

#define MAX_RETRY_COUNT 3

@interface InstructionViewController ()

@end

@implementation InstructionViewController {
  __weak IBOutlet UIView *connectedContainerView;
  __weak IBOutlet UILabel *confirmationCodeLabel;
  __weak IBOutlet UILabel *instructionLabel;
  __weak IBOutlet FXBlurView *notConnectedView;

  __weak IBOutlet UILabel *headTitleLabel;
  __weak IBOutlet UILabel *detailLabel;
  __weak IBOutlet UIButton *tryAgainButton;
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

  _bonjourManager = [[BonjourManager alloc] init];
  _bonjourManager.delegate = self;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
  notConnectedView.blurRadius = 6.0;
}

- (void)didBecomeActive:(NSNotification *)notification {
  [self connectIfNeeded];

}

- (void)connectIfNeeded {
  if (![WifiHelper isConnectedToInAiRWiFi]) {
    [self fadeInNotConnectedView];
  } else {
    if (![EventCenter defaultCenter].isActive && !isDiscoveringBonjourServices && (self == self.navigationController.topViewController)) {
      [self fadeOutNotConnectedView];
      isDiscoveringBonjourServices = YES;
      [_bonjourManager start];
    }
  }
}


- (void)fadeOutNotConnectedView {
  if (notConnectedView.alpha == 0.0) {
    return;
  }

  [UIView animateWithDuration:0.6 delay:0.4 options:UIViewAnimationOptionCurveEaseIn animations:^{
    notConnectedView.alpha = 0.0;

  }                completion:^(BOOL finished) {
    headTitleLabel.alpha = 0.0;
    detailLabel.alpha = 0.0;
    tryAgainButton.alpha = 0.0;
  }];
}

- (void)fadeInNotConnectedView {
  if (notConnectedView.alpha == 1.0) {
    return;
  }

  [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
    notConnectedView.alpha = 1.0;

  }                completion:^(BOOL finished) {
    [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
      headTitleLabel.alpha = 1.0;
      detailLabel.alpha = 1.0;
      tryAgainButton.alpha = 1.0;
    }                completion:^(BOOL finished) {

    }];
  }];
}


- (void)viewDidAppear:(BOOL)animated {
  [EventCenter defaultCenter].delegate = self;
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
  [self fadeOutNotConnectedView];
  isConnecting = NO;

  VerifyInAiRViewController *verifyVC = [[VerifyInAiRViewController alloc] init];
  [EventCenter defaultCenter].delegate = verifyVC;
  [self.navigationController pushViewController:verifyVC animated:NO];
}


- (void)eventCenterDidDisconnectWithError:(NSError *)error {
  [SVProgressHUD dismiss];
  isConnecting = NO;
}

- (IBAction)tryAgainButtonPressed:(id)sender {
  [self fadeOutNotConnectedView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self connectIfNeeded];
    });
  [self fadeOutNotConnectedView];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
