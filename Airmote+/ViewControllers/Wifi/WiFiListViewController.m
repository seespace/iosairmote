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

#define kWifiCellHeight 30

@interface WiFiListViewController ()

@end

@implementation WiFiListViewController {

  __weak IBOutlet UITableView *tableView;
  NSArray *wifiNetworks;
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

  Event *ev = [ProtoHelper setupWifiScanRequest];
  [[EventCenter defaultCenter] sendEvent:ev withTag:0];
  [SVProgressHUD showWithStatus:@"Loading..." maskType:SVProgressHUDMaskTypeGradient];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [SVProgressHUD dismiss];
  });
}

- (void)viewDidAppear:(BOOL)animated {
  [EventCenter defaultCenter].delegate = self;
}


- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event {

  [SVProgressHUD dismiss];
  SetupResponseEvent *ev = [event getExtension:[SetupResponseEvent event]];

  switch (ev.phase) {
    case SetupPhaseRequestWifiScan: {
      if (ev.error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:ev.errorMessage
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
      } else {
        wifiNetworks = ev.wifiNetworks;
        [tableView reloadData];
      }
      break;
    }

    default:
      break;
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
  //TODO use real data in here
  static NSString *wifiCellIdentifier = @"WifiCellIdentifier";

  WifiCell *cell = [tableView1 dequeueReusableCellWithIdentifier:wifiCellIdentifier];
  if (cell == nil) {
    NSArray *items = [[NSBundle mainBundle] loadNibNamed:@"WifiCell" owner:nil options:nil];
    cell = items[0];
  }

  WifiNetwork *network = wifiNetworks[(NSUInteger) indexPath.row];

  [cell configureCellWithName:network.ssid andSignalLevel:network.strength];
  return cell;
}

- (void)tableView:(UITableView *)tableView1 didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  WifiNetwork *network = wifiNetworks[(NSUInteger) indexPath.row];

  EnterPasswordViewController *enterPasswordVC = [[EnterPasswordViewController alloc] init];
    [EventCenter defaultCenter].delegate = enterPasswordVC;
  enterPasswordVC.networkSSID = network.ssid;
  [self.navigationController pushViewController:enterPasswordVC animated:YES];
}


- (IBAction)backButtonPressed:(id)sender {
  [self.navigationController popViewControllerAnimated:NO];
}
@end
