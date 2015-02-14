//
//  WSEnterPasswordController.m
//  Airmote+
//
//  Created by Long Nguyen on 2/13/15.
//  Copyright (c) 2015 Long Nguyen. All rights reserved.
//

#import "WSEnterPasswordController.h"
#import "MBSetupPageSection.h"
#import "MBTextFieldItem.h"
#import "SVProgressHUD.h"
#import "JDStatusBarNotification+Extension.h"

#define kDismissDelay 1.5f

@interface WSEnterPasswordController () {
  MBTextFieldItem *_passwordItem;
}

@end

@implementation WSEnterPasswordController

- (id)initWithNetwork:(WifiNetwork *)network {
  if (self = [super init]) {
    self.selectedNetwork = network;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.

  __weak WSEnterPasswordController *weakSelf = self;

  weakSelf.nextButtonItem.enabled = NO;

  MBSetupPageSection *section;

  if (self.selectedNetwork.requiredPassword) {
    weakSelf.nextButtonItem.title = @"Join";

    //Configure section
    section = [MBSetupPageSection sectionWithTitle:@"Enter Password"];
    section.headerViewBlock = ^UIView *(MBSetupPageSection *section) {
      return [weakSelf preparedPageHeaderViewWithTitle:section.title];
    };

    section.headerHeightBlock = ^CGFloat(UITableView *tableView, MBSetupPageSection *section, UIView *view) {
      CGSize size = [view sizeThatFits:CGSizeMake(tableView.frame.size.width, 0)];
      return size.height;
    };

    section.footerViewBlock = ^UIView *(MBSetupPageSection *section) {
      MBSectionFooter *footer = [weakSelf preparedFooterViewWithImage:nil
                                                                title:nil
                                                             subtitle:[NSString stringWithFormat:@"Enter the password for \"%@\"", self.selectedNetwork.ssid]];
      return footer;
    };
    section.footerHeightBlock = ^CGFloat(UITableView *tableView, MBSetupPageSection *section, UIView *view) {
      CGSize size = [view sizeThatFits:CGSizeMake(tableView.frame.size.width, 0)];
      return size.height;
    };

    _passwordItem = [[MBTextFieldItem alloc] initWithTitle:@"Password" text:nil placeholder:@"Required"];
    _passwordItem.autocorrectionType = UITextAutocorrectionTypeNo;
    _passwordItem.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _passwordItem.secureTextEntry = YES;
    _passwordItem.textDidChangeBlock = ^(MBTextFieldItem *item) {
      [weakSelf validate];
    };
    _passwordItem.validateBlock = ^BOOL(MBSetupPageItem *item) {
      return [(MBTextFieldItem *) item text].length > 0;
    };

    section.items = @[_passwordItem];
  } else {
    //Configure section
    section = [MBSetupPageSection sectionWithTitle:@"Connecting..."];
    section.headerViewBlock = ^UIView *(MBSetupPageSection *section) {
      return [weakSelf preparedPageHeaderViewWithTitle:section.title];
    };

    section.headerHeightBlock = ^CGFloat(UITableView *tableView, MBSetupPageSection *section, UIView *view) {
      CGSize size = [view sizeThatFits:CGSizeMake(tableView.frame.size.width, 0)];
      return size.height;
    };

    section.items = @[];
  }

  self.sections = @[section];
}

- (void)handleNextButtonTap {
  [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
  [JDStatusBarNotification showWithStatus:@"Connecting"];
  [self connect:_passwordItem.text];
}

- (void)connect:(NSString *)password {
  Event *ev = [ProtoHelper setupWifiConnectRequestWithSSID:self.selectedNetwork.ssid password:password];
  [[IAConnection sharedConnection] sendEvent:ev withTag:0];
}

- (BOOL)validate {
  BOOL success = [super validate];
  self.nextButtonItem.enabled = success;
  [JDStatusBarNotification dismiss];
  return success;
}

- (void)viewDidAppear:(BOOL)animated {
  [IAConnection sharedConnection].delegate = self;

  if (!self.selectedNetwork.requiredPassword) {
    [self connect:@""];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [JDStatusBarNotification dismiss];
}

- (void)didReceiveEvent:(Event *)event {
  SetupResponseEvent *ev = [event getExtension:[SetupResponseEvent event]];
  switch (ev.phase) {
    case SetupPhaseRequestWifiConnect: {
      if (ev.error) {
//        [SVProgressHUD showErrorWithStatus:@"Authentication Failed"];
        DDLogDebug(@"Authentication Failed");
        [JDStatusBarNotification showErrorWithStatus:@"Authentication Failed"];
      } else {
//        [SVProgressHUD showSuccessWithStatus:@"Connected"];
        [JDStatusBarNotification showUSBConnectionWithStatus:@"Connected"];
      }

      [SVProgressHUD dismiss];
    }
      break;

    default:
      break;
  }
}

- (void)didStopUSBConnection:(NSError *)error {
  [JDStatusBarNotification dismissAfter:kDismissDelay];
  [self dismissViewControllerAnimated:true completion:nil];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
