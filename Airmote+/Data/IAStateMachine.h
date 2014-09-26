//
// Created by Manh Tuan Cao on 9/24/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKStateMachine.h"


#define kIdleKey @"Idle"

#define kStateWifiSetupKey @"StartWifiSetup"

#define kSetupBonjourDiscoveryKey @"SetupBonjourDiscovery"

#define kSetupServiceResolvingKey @"SetupServiceResolving"

#define kSetupAddressFoundKey @"ConnectingToInAirSocket"

#define kFailedToConnectToInAirSocketKey @"FailedToConnectToInAirSocket"

#define kCodeVerificationKey @"CodeVerification"

#define kWifiListingKey @"WifiListing"

#define kFailedToGetWifiListingKey @"FailedToGetWifiList"

#define kEnteringWifiPasswordKey @"EnteringWifiPassword"

#define kSelectedOpenWifiKey @"SelectedOpenWifi"

#define kSameWifiAwaitingKey @"SameWifiAwaiting"

#define kWifiSetupDoneKey @"WifiSetupDone"

#define kBonjourDiscoveryKey @"BonjourDiscovery"

#define kFoundMultipleServicesKey @"FoundMultipleServices"

#define kServiceResolvingKey @"ServiceResolving"

#define kAddressResolvedKey @"AddressResolved"

#define kSocketConnectedKey @"SocketConnected"

#define kCodeVerificationStartKey @"CodeVerificationStart"

@interface IAStateMachine : TKStateMachine
+ (IAStateMachine *)sharedStateMachine;

- (void)test;

- (void)setup;
@end