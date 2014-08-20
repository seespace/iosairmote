//
//  InstructionViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/19/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "InstructionViewController.h"

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
    // Do any additional setup after loading the view from its nib.
    
    [UIView animateWithDuration:0.5 delay:0.2 options:0 animations:^{
        instructionLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 delay:0 options:0 animations:^{
            connectedContainerView.alpha = 1.0;
        } completion:NULL];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
