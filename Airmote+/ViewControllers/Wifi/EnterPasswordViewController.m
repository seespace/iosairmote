//
//  EnterPasswordViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/20/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "EnterPasswordViewController.h"
#import "EventCenter.h"

@interface EnterPasswordViewController ()

@end

@implementation EnterPasswordViewController

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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextButtonPressed:)];
}

- (void)viewDidAppear:(BOOL)animated
{
    [EventCenter defaultCenter].delegate = self;
}

- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event
{

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)nextButtonPressed:(id) sender
{
    //TODO send event to InAiR to login to wifi    
}

@end
