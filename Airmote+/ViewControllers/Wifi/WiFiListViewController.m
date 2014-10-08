//
//  WiFiListViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/20/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import "WiFiListViewController.h"
#import "WifiCell.h"
#import "EnterPasswordViewController.h"
#import "ProtoHelper.h"
#import "WifiNetwork+Extension.h"
#import "IAStateMachine.h"
#import "TKState.h"

#define kWifiCellHeight 38

@interface WiFiListViewController ()

@end

@implementation WiFiListViewController {

  __weak IBOutlet UITableView *tableView;
  NSArray *wifiNetworks;
  WifiNetwork *_selectedNetwork;
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
  if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    self.edgesForExtendedLayout = UIRectEdgeNone;

  if ([[IAStateMachine sharedStateMachine].currentState.name isEqualToString:kStateSetupWifiListing]) {
    Event *ev = [ProtoHelper setupWifiScanRequest];
    [[EventCenter defaultCenter] sendEvent:ev withTag:0];
    [SVProgressHUD showWithStatus:@"Loading..." maskType:SVProgressHUDMaskTypeGradient];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [SVProgressHUD dismiss];
    });
  }
  [self configureStateMachine];
  tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

}

- (void)configureStateMachine {
  [[[IAStateMachine sharedStateMachine] stateNamed:kStateEnteringWifiPassword] setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
    EnterPasswordViewController *enterPasswordVC = [[EnterPasswordViewController alloc] init];
    [EventCenter defaultCenter].delegate = enterPasswordVC;
    enterPasswordVC.networkSSID = _selectedNetwork.ssid;
    [self.navigationController pushViewController:enterPasswordVC animated:NO];
  }];

  [[[IAStateMachine sharedStateMachine] stateNamed:kStateSetupChangeName] setWillEnterStateBlock:^(TKState *state, TKTransition *transition) {
    if ([[[[IAStateMachine sharedStateMachine] currentState] name] isEqualToString:kStateSetupWifiListing]) {
      [self.navigationController popViewControllerAnimated:NO];
    }
  }];

  [[[IAStateMachine sharedStateMachine] stateNamed:kStateSameWifiAwaiting] setWillEnterStateBlock:^(TKState *state, TKTransition *transition) {
    if ([[IAStateMachine sharedStateMachine] isInState:kStateSetupWifiListing]) {
      [SVProgressHUD showSuccessWithStatus:@"Connected"];
      ConnectedConfirmationViewController *confirmationViewController = [[ConnectedConfirmationViewController alloc] init];
      confirmationViewController.delegate = self;
      confirmationViewController.networkSSID = _selectedNetwork.ssid;
      [self.navigationController presentViewController:confirmationViewController animated:YES completion:NULL];
    }
  }];
}

- (void)viewDidAppear:(BOOL)animated {
  [EventCenter defaultCenter].delegate = self;
}


- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event {

  [SVProgressHUD dismiss];
  SetupResponseEvent *ev = [event getExtension:[SetupResponseEvent event]];

  switch (ev.phase) {
    case SetupPhaseRequestWifiScan: {
      [self handleWifiScanEvent:ev];
      break;
    }

    case SetupPhaseRequestWifiConnect: {
      if (ev.error) {
        [SVProgressHUD dismiss];
      } else {
        [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupUserSelectedOpenWifi];
      }
      break;
    }

    default:
      break;
  }
}

- (void)handleWifiScanEvent:(SetupResponseEvent *)ev {
  if (ev.error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:ev.errorMessage
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
      } else {
        if ([ev.wifiNetworks count] == 0) {
          UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"WiFi networks are not available."
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
          [alertView show];
        }
        else {
          wifiNetworks = ev.wifiNetworks;
          [tableView reloadData];
        }
      }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
  return 1;
}

- (CGFloat)tableView:(UITableView *)tableView1 heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kWifiCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView1 numberOfRowsInSection:(NSInteger)section {
  return [wifiNetworks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView1 cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *wifiCellIdentifier = @"WifiCellIdentifier";

  WifiCell *cell = [tableView1 dequeueReusableCellWithIdentifier:wifiCellIdentifier];
  if (cell == nil) {
    NSArray *items = [[NSBundle mainBundle] loadNibNamed:@"WifiCell" owner:nil options:nil];
    cell = items[0];
  }

  WifiNetwork *network = wifiNetworks[(NSUInteger) indexPath.row];

  [cell configureCellWithName:network.ssid andSignalLevel:network.strength passwordRequired:network.requiredPassword];
  return cell;
}

- (void)tableView:(UITableView *)tableView1 didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  _selectedNetwork = wifiNetworks[(NSUInteger) indexPath.row];
  [tableView1 deselectRowAtIndexPath:indexPath animated:YES];
  if (_selectedNetwork.requiredPassword) {
    [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupUserSelectedSecureWifi];
  } else {
    if ([[IAStateMachine sharedStateMachine] isInState:kStateSetupWifiListing]) {
      Event *ev = [ProtoHelper setupWifiConnectRequestWithSSID:_selectedNetwork.ssid password:@""];
      [[EventCenter defaultCenter] sendEvent:ev withTag:0];
      [SVProgressHUD showWithStatus:@"InAir device connecting..."];
    }
  }
}


- (IBAction)backButtonPressed:(id)sender {
  [[IAStateMachine sharedStateMachine] fireEvent:kEventSetupBackToNameChanging];
}

- (void)didConnectedToTheSameNetworkWithInAirDevice {
  [self.parentViewController.presentingViewController dismissViewControllerAnimated:NO completion:NULL];
}

@end
