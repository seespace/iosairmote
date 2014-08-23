//
//  WiFiListViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/20/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "WiFiListViewController.h"
#import "WifiCell.h"
#import "EnterPasswordViewController.h"
#import "EventCenter.h"
#import "ProtoHelper.h"

#define kWifiCellHeight 30
#define kNumberOfWifiNetworks 100

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

  //TODO send request to retrieve list of wifi network
  Event *ev = [ProtoHelper setupWifiScanRequest];
  [[EventCenter defaultCenter] sendEvent:ev withTag:0];
}

- (void)viewDidAppear:(BOOL)animated {
  [EventCenter defaultCenter].delegate = self;
}


- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event {
  // TODO reload tableview
  SetupResponseEvent *ev = [event getExtension:[SetupResponseEvent event]];
  wifiNetworks = ev.wifiNetworks;
  [tableView reloadData];
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
  enterPasswordVC.networkSDID = network.ssid; //TODO use real data
  [self.navigationController pushViewController:enterPasswordVC animated:YES];
}


@end
