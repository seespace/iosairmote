//
//  ChangeNameViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/20/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "ChangeNameViewController.h"
#import "WiFiListViewController.h"
#import "EventCenter.h"
#import "Proto.pb.h"

@interface ChangeNameViewController ()

@end

@implementation ChangeNameViewController
{
    __weak IBOutlet UITextField *textField;
    
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
    self.title = @"InAiR Name";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextButtonPressed:)];
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
}

-(void)viewDidAppear:(BOOL)animated
{
    [EventCenter defaultCenter].delegate = self;
}


-(void)nextButtonPressed:(id) sender
{
    [self sendRenameRequestWithName:textField.text];
    WiFiListViewController *wifiListVC = [[WiFiListViewController alloc] init];
    [self.navigationController pushViewController:wifiListVC animated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event
{
    // TODO if success goto next screen
}


- (BOOL)textFieldShouldReturn:(UITextField *)aTextField
{
    [self sendRenameRequestWithName:textField.text];
    return YES;
}

- (void)sendRenameRequestWithName:(NSString *)name
{
    if ([name length] > 0)
    {
        //TODO send a change name request to server using EventCenter
    }
}

@end
