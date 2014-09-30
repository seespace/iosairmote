//
// Created by Manh Tuan Cao on 9/24/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKStateMachine.h"


#define kStateIdle @"Idle"

#define kStateWifiSetupStart @"StateWifiSetupStart"

#define kStateSetupBonjourDiscovery @"StateSetupBonjourDiscovery"

#define kStateSetupServiceResolving @"StateSetupServiceResolving"

#define kStateSetupServiceResolved @"StateSetupServiceResolved"


#define kStateSetupCodeVerification @"StateSetupCodeVerification"

//#define kStateSetupConfirmationCodeReceived @"kStateSetupConfirmationCodeReceived"

#define kStateSetupWifiListing @"StateSetupWifiListing"


#define kStateFailedToGetWifiListing @"StateFailedToGetWifiListing"

#define kStateEnteringWifiPassword @"StateEnteringWifiPassword"

#define kStateSelectedOpenWifi @"StateSelectedOpenWifi"

#define kStateSameWifiAwaiting @"StateSameWifiAwaiting"

#define kStateNormalStart @"StateNormalStart"

#define kStateBonjourDiscovery @"StateBonjourDiscovery"

#define kStateBonjourDiscoveryFailed @"StateBonjourDiscoveryFailed"

#define kStateFoundMultipleServices @"StateFoundMultipleServices"

#define kStateServiceResolving @"StateServiceResolving"

#define kStateAddressResolved @"StateAddressResolved"

#define kStateSocketConnected @"StateSocketConnected"

#define kStateSetupSocketConnected @"StateSetupSocketConnected"


// Events definitions
#define kEventSetupStart @"Setup: Start"

#define kEventSetupDetectedInAirWifi @"Setup: Detected InAiR Wifi"

#define kEventSetupFoundBonjourService @"Setup: Found InAir Service"

#define kEventSetupServiceResolved @"Setup: Address Found"

#define kEventSetupSocketConnected @"Setup: Socket Connected"

#define kEventSetupFailedToConnectToSocket @"EventSetupFailedToConnectToSocket"

#define kEventSetupCodeVerificationReceived @"Setup: Code verification received"

#define kEventSetupSameCodeVerified @"Setup: Same code verified"

#define kEventSetupUserSelectedOpenWifi @"Setup: User selected open wifi"

#define kEventSetupUserSelectedSecureWifi @"Setup: User selected secure wifi"

#define kEventUserConnectedToSecureWifi @"Setup: User conncected secure wifi"

#define kEventSetupConnectedToTheSameNetwork @"Setup: Connected to the same network"

#define kEventSetupFailedToRetrieveConfirmationCode @"EventSetupFailedToRetrieveConfirmationCode"

#define kEventSetupBackToCodeVerification @"EventSetupBackToCodeVerification"

#define kEventSetupBackToWifiListing @"EventSetupBackToWifiListing"

#define kEventBonjourStart @"Start bonjour"

#define kEventStartResolvingService @"Start resolving service"

#define kEventFoundMultipleServices @"Found multiple services"

#define kEventFailToConnectToInAiR @"Fail to connect to InAiR device"

#define kEventServiceResolved @"Service Resolved"

#define kEventRealSocketConnected @"Socket Connected"

#define kEventStartNormalWorkFlow @"Start normal work flow"

@interface IAStateMachine : TKStateMachine
+ (IAStateMachine *)sharedStateMachine;

- (void)setup;
@end