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

#define MAX_RETRY_COUNT 3

@interface InstructionViewController ()

@end

@implementation InstructionViewController {
  __weak IBOutlet UILabel *instructionLabel;

  __weak IBOutlet UILabel *headTitleLabel;
  __weak IBOutlet UILabel *detailLabel;
  __weak IBOutlet UIButton *tryAgainButton;
  BonjourManager *_bonjourManager;

  BOOL isConnecting;
  BOOL isDiscoveringBonjourServices;

  int retryCount;
  int resolveServiceRetryCount;
  NSNetService *_netService;
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

  _bonjourManager = [[BonjourManager alloc] init];
  _bonjourManager.delegate = self;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
  viewDidAppear = NO;
  [self showVerificationViewController];  
}


- (void)didBecomeActive:(NSNotification *)notification {
  
  [self connectIfNeeded];

}

- (void)connectIfNeeded {

  if (self != self.navigationController.topViewController) {
    return;
  }
  
  if ([EventCenter defaultCenter].isActive) {
    [self showVerificationViewController];
  } else {
    if ([WifiHelper isConnectedToInAiRWiFi]) {
      if (!isDiscoveringBonjourServices) {
        isDiscoveringBonjourServices = YES;
        [_bonjourManager start];
      } else {
        NSLog(@"Ignoring connect request...");
      }
    }
  }
}



- (void)viewDidAppear:(BOOL)animated {
  [EventCenter defaultCenter].delegate = self;
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

- (void)eventCenterDidConnectToHost:(NSString *)hostName {
  [SVProgressHUD dismiss];
  isConnecting = NO;
  [self showVerificationViewController];
}


- (void)showVerificationViewController {
  VerifyInAiRViewController *verifyVC = [[VerifyInAiRViewController alloc] init];
  [EventCenter defaultCenter].delegate = verifyVC;
  [self.navigationController pushViewController:verifyVC animated:NO];

}


- (void)eventCenterDidDisconnectFromHost:(NSString *)hostName withError:(NSError *)error {
  [SVProgressHUD dismiss];
  isConnecting = NO;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
