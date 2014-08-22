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

#define kWifiCellHeight 30
#define kNumberOfWifiNetworks 100
@interface WiFiListViewController ()

@end

@implementation WiFiListViewController
{
    
    __weak IBOutlet UITableView *tableView;
    NSArray *wifiNetworks;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;

    //TODO send request to retrieve list of wifi network
}

- (void)viewDidAppear:(BOOL)animated
{
    [EventCenter defaultCenter].delegate = self;
}


- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event
{
    // TODO reload tableview
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView1 heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  kWifiCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView1 numberOfRowsInSection:(NSInteger)section
{
    return [wifiNetworks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView1 cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //TODO use real data in here
    static NSString *wifiCellIdentifier = @"WifiCellIdentifier";
    
    WifiCell *cell = [tableView1 dequeueReusableCellWithIdentifier:wifiCellIdentifier];
    if (cell == nil)
    {
        NSArray *items = [[NSBundle mainBundle] loadNibNamed:@"WifiCell" owner:nil options:nil];
        cell = items[0];
    }
    [cell configureCellWithName:[NSString stringWithFormat:@"Network %d", indexPath.row] andSignalLevel:indexPath.row % 4];
    return cell;
}

- (void)tableView:(UITableView *)tableView1 didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    EnterPasswordViewController *enterPasswordVC = [[EnterPasswordViewController alloc] init];
    enterPasswordVC.networkSDID = @"Something"; //TODO use real data
    [self.navigationController pushViewController:enterPasswordVC animated:YES];
}



@end
