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

#define kStateSetupChangeName @"StateSetupChangeName"

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
#define kEventSetupStart @"EventSetupStart"

#define kEventSetupDetectedInAirWifi @"EventSetupDetectedInAirWifi"

#define kEventSetupFoundBonjourService @"EventSetupFoundBonjourService"

#define kEventSetupServiceResolved @"EventSetupServiceResolved"

#define kEventSetupSocketConnected @"EventSetupSocketConnected"

#define kEventSetupFailedToConnectToSocket @"EventSetupFailedToConnectToSocket"

#define kEventSetupCodeVerificationReceived @"EventSetupCodeVerificationReceived"

#define kEventSetupSameCodeVerified @"EventSetupSameCodeVerified"

#define kEventSetupNameChanged @"EventSetupNameChanged"

#define kEventSetupUserSelectedOpenWifi @"EventSetupUserSelectedOpenWifi"

#define kEventSetupUserSelectedSecureWifi @"EventSetupUserSelectedSecureWifi"

#define kEventUserConnectedToSecureWifi @"EventUserConnectedToSecureWifi"

#define kEventSetupConnectedToTheSameNetwork @"EventSetupConnectedToTheSameNetwork"

#define kEventSetupFailedToRetrieveConfirmationCode @"EventSetupFailedToRetrieveConfirmationCode"

#define kEventSetupBackToCodeVerification @"EventSetupBackToCodeVerification"

#define kEventSetupBackToNameChanging @"EventSetupBackToNameChanging"

#define kEventSetupBackToWifiListing @"EventSetupBackToWifiListing"

#define kEventBonjourStart @"EventBonjourStart"

#define kEventStartResolvingService @"EventStartResolvingService"

#define kEventFoundMultipleServices @"EventFoundMultipleServices"

#define kEventFailToConnectToInAiR @"EventFailToConnectToInAiR"

#define kEventServiceResolved @"kEventServiceResolved"

#define kEventRealSocketConnected @"kEventRealSocketConnected"

#define kEventStartNormalWorkFlow @"kEventStartNormalWorkFlow"

@interface IAStateMachine : TKStateMachine
+ (IAStateMachine *)sharedStateMachine;

- (void)setup;

- (void)fireEvent:(id)eventOrEventName;
@end