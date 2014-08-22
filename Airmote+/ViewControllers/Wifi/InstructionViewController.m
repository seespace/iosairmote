//
//  InstructionViewController.m
//  Airmote+
//
//  Created by Manh Tuan Cao on 8/19/14.
//  Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "InstructionViewController.h"
#import "ChangeNameViewController.h"
#import "Proto.pb.h"
#import "SVProgressHUD.h"
#import "NSData+NetService.h"

@interface InstructionViewController ()

@end

@implementation InstructionViewController
{
    __weak IBOutlet UIView *connectedContainerView;
    __weak IBOutlet UILabel *confirmationCodeLabel;
    __weak IBOutlet UILabel *instructionLabel;
    BonjourManager *_bonjourManager;
    
    BOOL isConnecting;
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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain
                                                                             target:self action:@selector(nextButtonPressed:)];
    _bonjourManager = [[BonjourManager alloc] init];
    _bonjourManager.delegate = self;
    [_bonjourManager start];
    //TODO disable Next button
}


-(void)viewDidAppear:(BOOL)animated
{
    [EventCenter defaultCenter].delegate = self;
}

-(void)nextButtonPressed:(id) sender
{
    ChangeNameViewController *nameViewController = [[ChangeNameViewController alloc] init];
    [self.navigationController pushViewController:nameViewController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)bonjourManagerFinishedDiscoveringServices:(NSArray *)services
{
    if ([services count])
    {
        NSNetService *service = services[0];
        if (service.addresses.count == 0)
        {
            service.delegate = self;
            [service resolveWithTimeout:10];
        }
        else
        {
            if ([service.addresses count])
            {
                NSString *address = [[service.addresses objectAtIndex:0] socketAddress];
                [self connectToHost:address];
            }

        }
    }
}

- (void)bonjourManagerServiceNotFound
{
    NSLog(@"Failed to find bonjour services");
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog(@"Failed to resolve address for service: %@", sender);
    //TODO retry ??
}


- (void)netServiceDidResolveAddress:(NSNetService *)service
{
    if ([service.addresses count])
    {
        NSString *address = [[service.addresses objectAtIndex:0] socketAddress];
        [self connectToHost:address];
    }
    
}


- (void)connectToHost:(NSString *)hostname
{
    if (isConnecting)
        return;

    EventCenter *eventCenter = [EventCenter defaultCenter];
    eventCenter.delegate = nil;

    eventCenter = [EventCenter defaultCenter];
    eventCenter.delegate = self;
    isConnecting = [eventCenter connectToHost:hostname];
    if (isConnecting)
    {
        [SVProgressHUD showWithStatus:@"Connecting" maskType:SVProgressHUDMaskTypeBlack];
    }
}

- (void)eventCenterDidConnect
{
    [SVProgressHUD dismiss];
    isConnecting = NO;
    [self requestConfirmationCode];
}

- (void)requestConfirmationCode
{
    //TODO implement code for sending confirmation code to InAir
}

- (void)eventCenterDidDisconnectWithError:(NSError *)error
{
    [SVProgressHUD dismiss];
    //TODO show retry button??
    isConnecting = NO;
}

- (void)eventCenter:(EventCenter *)eventCenter receivedEvent:(Event *)event
{
    //TODO process event to get confirmation code
    NSString *confirmationCode = @"BCD";

    confirmationCodeLabel.text = confirmationCode;
    [SVProgressHUD dismiss];
    [UIView animateWithDuration:0.5 animations:^{
        instructionLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            connectedContainerView.alpha = 1.0;
        }];
    }];

    //TODO enable Next when received confirmation code
}

@end
