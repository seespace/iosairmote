//
// Created by Manh Tuan Cao on 9/24/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import "IAStateMachine.h"
#import "TKState.h"
#import "TKEvent.h"


@implementation IAStateMachine {

}
+ (IAStateMachine *)sharedStateMachine {
  static IAStateMachine *_instance = nil;

  @synchronized (self) {
    if (_instance == nil) {
      _instance = [[self alloc] init];
      [_instance setup];
    }
  }

  return _instance;
}

- (void)setup {

  TKState *idle = [TKState stateWithName:kStateIdle]; // Begin state
  TKState *startWifiSetup = [TKState stateWithName:kStateWifiSetupStart];
  TKState *setupBonjourDiscovery = [TKState stateWithName:kStateSetupBonjourDiscovery];
  TKState *setupServiceResolving = [TKState stateWithName:kStateSetupServiceResolving];
  TKState *setupAddressFound = [TKState stateWithName:kStateSetupAddressFound];
  TKState *codeVerificationStart = [TKState stateWithName:kStateCodeVerificationStart];
  TKState *failedToConnectToInAirSocket = [TKState stateWithName:kStateFailedToConnectToInAirSocket];
  TKState *codeVerification = [TKState stateWithName:kStateCodeVerification];
  TKState *wifiListing = [TKState stateWithName:kStateWifiListing];
  TKState *failedToGetWifiList = [TKState stateWithName:kStateFailedToGetWifiListing];
  TKState *enteringWifiPassword = [TKState stateWithName:kStateEnteringWifiPassword];
  TKState *selectedOpenWifi = [TKState stateWithName:kStateSelectedOpenWifi];
  TKState *sameWiFiAwaiting = [TKState stateWithName:kStateSameWifiAwaiting];

  TKState *normalStart = [TKState stateWithName:kStateNormalStart];
  TKState *bonjourDiscovery = [TKState stateWithName:kStateBonjourDiscovery];
  TKState *foundMultipleServices = [TKState stateWithName:kStateFoundMultipleServices];
  TKState *serviceResolving = [TKState stateWithName:kStateServiceResolving];
  TKState *serviceResolved = [TKState stateWithName:kStateAddressResolved];
  TKState *socketConnected = [TKState stateWithName:kStateSocketConnected];  //Done state

  [self addStates:@[idle, startWifiSetup, setupBonjourDiscovery, setupServiceResolving,
      setupAddressFound, failedToConnectToInAirSocket, codeVerificationStart,
      codeVerification, wifiListing, failedToGetWifiList, enteringWifiPassword,
      selectedOpenWifi, sameWiFiAwaiting, normalStart, bonjourDiscovery,
      foundMultipleServices, serviceResolving, serviceResolved, socketConnected]];





  TKEvent *detectedInAirWifiEvent = [TKEvent eventWithName:kEventSetupDetectedInAirWifi transitioningFromStates:@[startWifiSetup] toState:setupBonjourDiscovery];
  TKEvent *setupBonjourServiceFoundEvent = [TKEvent eventWithName:kEventSetupFoundBonjourService transitioningFromStates:@[setupBonjourDiscovery] toState:setupServiceResolving];
  TKEvent *setupAddressFoundEvent = [TKEvent eventWithName:kEventSetupAddressFound transitioningFromStates:@[setupServiceResolving] toState:setupAddressFound];
  TKEvent *setupSocketConnectedEvent = [TKEvent eventWithName:kEventSetupSocketConnected transitioningFromStates:@[setupAddressFound] toState:codeVerificationStart];
  TKEvent *setupCodeVerificationReceivedEvent = [TKEvent eventWithName:kEventSetupCodeVerificationReceived transitioningFromStates:@[codeVerificationStart] toState:codeVerification];
  TKEvent *userConfirmedCodeEvent = [TKEvent eventWithName:kEventSetupSameCodeVerified transitioningFromStates:@[codeVerification] toState:wifiListing];
  TKEvent *userSelectedOpenWifiEvent = [TKEvent eventWithName:kEventSetupUserSelectedOpenWifi transitioningFromStates:@[wifiListing] toState:sameWiFiAwaiting];
  TKEvent *userSelectedSecureWifiEvent = [TKEvent eventWithName:kEventSetupUserSelectedSecureWifi transitioningFromStates:@[wifiListing] toState:enteringWifiPassword];
  TKEvent *userStartConnectedToSecureEvent = [TKEvent eventWithName:kEventUserConnectedToSecureWifi transitioningFromStates:@[enteringWifiPassword] toState:sameWiFiAwaiting];
  TKEvent *detectedToTheSameWifiEvent = [TKEvent eventWithName:kEventSetupConnectedToTheSameNetwork transitioningFromStates:@[sameWiFiAwaiting] toState:normalStart];


  TKEvent *startBonjourServiceEvent = [TKEvent eventWithName:kEventBonjourStart
                                     transitioningFromStates:@[normalStart]
                                                     toState:bonjourDiscovery];

  TKEvent *foundMultipleServicesEvent = [TKEvent eventWithName:kEventFoundMultipleServices
                                       transitioningFromStates:@[bonjourDiscovery]
                                                       toState:foundMultipleServices];

  TKEvent *startResolvingServiceEvent = [TKEvent eventWithName:kEventStartResolvingService
                                       transitioningFromStates:@[bonjourDiscovery, foundMultipleServices]
                                                       toState:serviceResolving];

  TKEvent *failedToConnectToInAirEvent = [TKEvent eventWithName:kEventFailToConnectToInAiR
                                       transitioningFromStates:@[bonjourDiscovery, foundMultipleServices, serviceResolving, serviceResolved]
                                                       toState:normalStart];

  TKEvent *serviceResolvedEvent = [TKEvent eventWithName:kEventServiceResolved
                              transitioningFromStates:@[serviceResolving]
                                              toState:serviceResolved];
  TKEvent *socketConnectedEvent = [TKEvent eventWithName:kEventRealSocketConnected
                                 transitioningFromStates:@[serviceResolved]
                                                 toState:socketConnected];

  [self addEvents:@[startBonjourServiceEvent, foundMultipleServicesEvent, startResolvingServiceEvent, failedToConnectToInAirEvent, serviceResolvedEvent, socketConnectedEvent]];


  TKEvent *startSetupEvent = [TKEvent eventWithName:kEventSetupStart transitioningFromStates:@[idle] toState:startWifiSetup];
  TKEvent *startNormalWorkflowEvent = [TKEvent eventWithName:kEventStartNormalWorkFlow transitioningFromStates:@[idle] toState:normalStart];
  [self addEvents:@[startSetupEvent, startNormalWorkflowEvent]];

//  [self addEvents:@[startSetupEvent, startNormalWorkflowEvent, detectedInAirWifiEvent, setupBonjourServiceFoundEvent, setupAddressFoundEvent, setupSocketConnectedEvent, setupCodeVerificationReceivedEvent,
//  userConfirmedCodeEvent, userSelectedOpenWifiEvent, userSelectedSecureWifiEvent, userStartConnectedToSecureEvent, detectedToTheSameWifiEvent,
//  startBonjourServiceEvent, failedToConnectToInAirEvent, serviceResolvedEvent, startResolvingServiceEvent, foundMultipleServicesEvent, serviceResolvedEvent, socketConnectedEvent]];
}

@end