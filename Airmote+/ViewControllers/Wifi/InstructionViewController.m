//
//  InstructionViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/19/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "InstructionViewController.h"
#import "WiFiListViewController.h"
#import "VerifyInAiRViewController.h"
@interface InstructionViewController ()

@end

@implementation InstructionViewController
{
    __weak IBOutlet UIView *connectedContainerView;
    __weak IBOutlet UILabel *confirmationCodeLabel;
    __weak IBOutlet UILabel *instructionLabel;
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
    self.title = @"Setup InAiR";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextButtonPressed:)];
}

-(void)nextButtonPressed:(id) sender
{
    VerifyInAiRViewController *verifyVC = [[VerifyInAiRViewController alloc] init];
    [self.navigationController pushViewController:verifyVC animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
