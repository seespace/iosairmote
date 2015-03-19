//
//  WSNetworksController.m
//  Airmote+
//
//  Created by Long Nguyen on 2/13/15.
//  Copyright (c) 2015 Long Nguyen. All rights reserved.
//

#import <Build/SetupController/MBSetupPageItem.h>
#import "WSNetworksController.h"
#import "MBSetupPageSection.h"
#import "MBSectionHeader.h"
#import "ProtoHelper.h"
#import "WifiCell.h"
#import "MBLabelCell.h"
#import "Proto.pb.h"
#import "JDStatusBarNotification+Extension.h"
#import "AppDelegate.h"

@interface WSNetworksController () {
  NSArray *_wifiNetworks;
  UIActivityIndicatorView *_activityView;
}

@end

@implementation WSNetworksController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.

  if (![[IAConnection sharedConnection] isUSBConnected]) {
    [self proceedToPreviousPage];
  }

  __weak WSNetworksController *weakSelf = self;

  weakSelf.nextButtonItem.enabled = NO;

  //Configure section
  MBSetupPageSection *section = [MBSetupPageSection sectionWithTitle:@"Choose a Network"];
  section.headerViewBlock = ^UIView *(MBSetupPageSection *section) {
    return [weakSelf preparedPageHeaderViewWithTitle:section.title];
  };

  section.headerHeightBlock = ^CGFloat(UITableView *tableView, MBSetupPageSection *section, UIView *view) {
    CGSize size = [view sizeThatFits:CGSizeMake(tableView.frame.size.width, 0)];
    return size.height;
  };

//  section.footerViewBlock = ^UIView*(MBSetupPageSection *section) {
//    UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] init];
//    return view;
//  };
//
//  section.footerHeightBlock = ^CGFloat(UITableView *tableView, MBSetupPageSection *section, UIView *view) {
//    CGSize size = [view sizeThatFits:CGSizeMake(tableView.frame.size.width, 0)];
//    return size.height;
//  };

  section.items = @[];
  self.sections = @[section];

//  self.tableView.dataSource = self;
}

- (void)viewDidAppear:(BOOL)animated {
  if (![[IAConnection sharedConnection] isUSBConnected]) {
    [self proceedToPreviousPage];
    return;
  }

  [IAConnection sharedConnection].delegate = self;
  if (_wifiNetworks.count == 0) {
    [self showActivityViewer];
  }
  Event *ev = [ProtoHelper setupWifiScanRequest];
  [[IAConnection sharedConnection] sendEvent:ev withTag:0];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark ActivityView

-(void)showActivityViewer {
  _activityView = [[UIActivityIndicatorView alloc] initWithFrame: CGRectMake(self.tableView.bounds.size.width / 2 - 18, self.tableView.bounds.size.height / 2 - 18, 36, 36)];
  _activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
  _activityView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
      UIViewAutoresizingFlexibleRightMargin |
      UIViewAutoresizingFlexibleTopMargin |
      UIViewAutoresizingFlexibleBottomMargin);
  [self.tableView addSubview:_activityView];

  [_activityView startAnimating];
}

-(void)hideActivityViewer {
  if (_activityView != nil) {
    [_activityView stopAnimating];
    [_activityView removeFromSuperview];
    _activityView = nil;
  }
}

#pragma mark TableView

// NOTE: WE ARE OVERRIDING THIS METHOD TO FIX A CRASH BUG ON IOS 7
- (MBSetupPageItem *)itemAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section < self.sections.count) {
    MBSetupPageSection *section = self.sections[indexPath.section];
    if (indexPath.row < section.items.count) {
      return section.items[indexPath.row];
    }
  }
  
  return nil;
}

// NOTE: WE ARE OVERRIDING THIS METHOD TO FIX A CRASH BUG ON IOS 7
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (self.useAutosizingCells) {
    return UITableViewAutomaticDimension;
  }
  
  MBSetupPageItem *item = (MBSetupPageItem *)[self itemAtIndexPath:indexPath];
  if (item == nil)
    return 44.0;
  
  NSAssert(item.cellIdentifier != nil, @"cellIdentifier != nil not satisfied");
  
  MBSetupPageCell *cell = [tableView dequeueReusableCellWithIdentifier:item.cellIdentifier];
  if (!cell) {
    cell = item.createCellBlock(item);
  }
  
  item.configureCellBlock(item, cell);
  
  CGFloat height = 0;
  
  if (cell) {
    NSAssert(item.cellHeightBlock != nil, @"item.cellHeightBlock != nil not satisfied");
    height = item.cellHeightBlock(tableView, item, cell);
  }
  if (height == 0) {
    height = 44.0;
  }
  
  return height;
}


- (NSInteger)tableView:(UITableView *)tableView1 numberOfRowsInSection:(NSInteger)section {
  return [_wifiNetworks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *wifiCellIdentifier = @"WifiCellIdentifier";

//  WifiCell *cell = [tableView dequeueReusableCellWithIdentifier:wifiCellIdentifier];
//  if (cell == nil) {
//    NSArray *items = [[NSBundle mainBundle] loadNibNamed:@"WifiCell" owner:nil options:nil];
//    cell = items[0];
//  }
//
//  WifiNetwork *network = _wifiNetworks[(NSUInteger) indexPath.row];
//
//  [cell configureCellWithName:network.ssid andSignalLevel:network.strength passwordRequired:network.requiredPassword];
//  return cell;

  WifiNetwork *network = _wifiNetworks[(NSUInteger) indexPath.row];

  MBLabelCell *cell = [tableView dequeueReusableCellWithIdentifier:wifiCellIdentifier];
  if (cell == nil) {
    cell = [[MBLabelCell alloc] init];
  }

  if (network.ssid.length == 0) {
    cell.textLabel.text = @"Untitled";
  } else {
    cell.textLabel.text = network.ssid;
  }

  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  self.selectedNetwork = _wifiNetworks[(NSUInteger) indexPath.row];

  [self proceedToNextPage];

//  if (_selectedNetwork.requiredPassword) {
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Enter Password"
//                                                        message:[NSString stringWithFormat:@"Enter the password for \"%@\"", _selectedNetwork.ssid]
//                                                       delegate:self
//                                              cancelButtonTitle:@"Cancel"
//                                              otherButtonTitles:@"Join", nil];
//    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
//    [alertView show];
//  } else {
//    Event *ev = [ProtoHelper setupWifiConnectRequestWithSSID:_selectedNetwork.ssid password:@""];
//    [[IAConnection sharedConnection] sendEvent:ev withTag:0];
//  }
}

#pragma mark IAConnection

- (void)didStopUSBConnection:(NSError *)error {
  [JDStatusBarNotification showErrorWithStatus:@"USB connection closed" dismissAfter:kAnimationSlow];
  [self proceedToPreviousPage];
}

- (void)didReceiveEvent:(Event *)event {
  SetupResponseEvent *ev = [event getExtension:[SetupResponseEvent event]];

  switch (ev.phase) {
    case SetupPhaseRequestWifiScan: {
      [self handleWifiScanEvent:ev];
      break;
    }

    case SetupPhaseRequestWifiConnect: {
      if (ev.error) {
        // error
      } else {
        // proceed to next page
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
    } else {
      _wifiNetworks = ev.wifiNetworks;
      [self.tableView reloadData];
      [self hideActivityViewer];
    }
  }
}

@end
