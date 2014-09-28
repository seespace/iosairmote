//
// Created by Manh Tuan Cao on 9/24/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKStateMachine.h"


#define kStateIdle @"Idle"

#define kStateWifiSetupStart @"StartWifiSetup"

#define kStateSetupBonjourDiscovery @"SetupBonjourDiscovery"

#define kStateSetupServiceResolving @"SetupServiceResolving"

#define kStateSetupAddressFound @"ConnectingToInAirSocket"

#define kStateFailedToConnectToInAirSocket @"FailedToConnectToInAirSocket"

#define kStateCodeVerification @"CodeVerification"

#define kStateWifiListing @"WifiListing"

#define kStateFailedToGetWifiListing @"FailedToGetWifiList"

#define kStateEnteringWifiPassword @"EnteringWifiPassword"

#define kStateSelectedOpenWifi @"SelectedOpenWifi"

#define kStateSameWifiAwaiting @"SameWifiAwaiting"

#define kStateWifiSetupDone @"WifiSetupDone"

#define kStateBonjourDiscovery @"BonjourDiscovery"

#define kStateFoundMultipleServices @"FoundMultipleServices"

#define kStateServiceResolving @"ServiceResolving"

#define kStateAddressResolved @"AddressResolved"

#define kStateSocketConnected @"SocketConnected"

#define kStateCodeVerificationStart @"CodeVerificationStart"


// Events definitions
#define kEventSetupStart @"Setup: Start"

#define kEventSetupDetectedInAirWifi @"Setup: Detected InAiR Wifi"

#define kEventSetupFoundBonjourService @"Setup: Found InAir Service"

#define kEventSetupAddressFound @"Setup: Address Found"

#define kEventSetupSocketConnected @"Setup: Socket Connected"

#define kEventSetupCodeVerificationReceived @"Setup: Code verification received"

#define kEventSetupSameCodeVerified @"Setup: Same code verified"

#define kEventSetupUserSelectedOpenWifi @"Setup: User selected open wifi"

#define kEventSetupUserSelectedSecureWifi @"Setup: User selected secure wifi"

#define kEventUserConnectedToSecureWifi @"Setup: User conncected secure wifi"

#define kEventSetupConnectedToTheSameNetwork @"Setup: Connected to the same network"

#define kEventBonjourStart @"Start bonjour"

#define kEventFoundOneService @"Found one service"

#define kEventFoundMultipleServices @"Found multiple services"

#define kEventFoundAddress @"Found Address"

#define kEventRealSocketConnected @"Socket Connected"


#define kEventStartNormalWorkFlow @"Start normal work flow"

@interface IAStateMachine : TKStateMachine
+ (IAStateMachine *)sharedStateMachine;

- (void)setup;
@end