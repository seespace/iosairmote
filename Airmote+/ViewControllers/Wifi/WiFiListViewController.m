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

#define kWifiCellHeight 30
#define kNumberOfWifiNetworks 100
@interface WiFiListViewController ()

@end

@implementation WiFiListViewController
{
    
    __weak IBOutlet UITableView *tableView;
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView1 heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  kWifiCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView1 numberOfRowsInSection:(NSInteger)section
{
    return kNumberOfWifiNetworks;
}

- (UITableViewCell *)tableView:(UITableView *)tableView1 cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    [self.navigationController pushViewController:enterPasswordVC animated:YES];
}



@end
