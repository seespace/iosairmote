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

  TKState *normalStart = [TKState stateWithName:kStateNormalStart];
  TKState *startWifiSetup = [TKState stateWithName:kStateWifiSetupStart];
  TKState *bonjourDiscovery = [TKState stateWithName:kStateBonjourDiscovery];
  TKState *foundMultipleServices = [TKState stateWithName:kStateFoundMultipleServices];
  TKState *serviceResolving = [TKState stateWithName:kStateServiceResolving];
  TKState *serviceResolved = [TKState stateWithName:kStateAddressResolved];
  TKState *socketConnected = [TKState stateWithName:kStateSocketConnected];  //Done state

  [self addStates:@[idle, normalStart, startWifiSetup, bonjourDiscovery,
      foundMultipleServices, serviceResolving, serviceResolved, socketConnected]];

  TKEvent *startBonjourServiceEvent = [TKEvent eventWithName:kEventBonjourStart
                                     transitioningFromStates:@[normalStart]
                                                     toState:bonjourDiscovery];

  TKEvent *foundMultipleServicesEvent = [TKEvent eventWithName:kEventFoundMultipleServices
                                       transitioningFromStates:@[normalStart, bonjourDiscovery]
                                                       toState:foundMultipleServices];

  TKEvent *startResolvingServiceEvent = [TKEvent eventWithName:kEventStartResolvingService
                                       transitioningFromStates:@[normalStart, bonjourDiscovery, foundMultipleServices]
                                                       toState:serviceResolving];

  TKEvent *failedToConnectToInAirEvent = [TKEvent eventWithName:kEventFailToConnectToInAiR
                                       transitioningFromStates:@[bonjourDiscovery, foundMultipleServices, serviceResolving, serviceResolved]
                                                       toState:normalStart];

  TKEvent *serviceResolvedEvent = [TKEvent eventWithName:kEventServiceResolved
                              transitioningFromStates:@[serviceResolving, normalStart]
                                              toState:serviceResolved];
  TKEvent *socketConnectedEvent = [TKEvent eventWithName:kEventRealSocketConnected
                                 transitioningFromStates:@[serviceResolved]
                                                 toState:socketConnected];

  [self addEvents:@[startBonjourServiceEvent, foundMultipleServicesEvent, startResolvingServiceEvent, failedToConnectToInAirEvent, serviceResolvedEvent, socketConnectedEvent]];


  TKEvent *startSetupEvent = [TKEvent eventWithName:kEventSetupStart transitioningFromStates:@[idle] toState:startWifiSetup];
  TKEvent *startNormalWorkflowEvent = [TKEvent eventWithName:kEventStartNormalWorkFlow transitioningFromStates:@[idle] toState:normalStart];
  [self addEvents:@[startSetupEvent, startNormalWorkflowEvent]];

  // WIFI setup flow setup

  TKState *setupBonjourDiscovery = [TKState stateWithName:kStateSetupBonjourDiscovery];
  TKState *setupServiceResolving = [TKState stateWithName:kStateSetupServiceResolving];
  TKState *setupServiceResolved = [TKState stateWithName:kStateSetupServiceResolved];
  TKState *setupSocketConnected = [TKState stateWithName:kStateSetupSocketConnected];
  TKState *codeVerification = [TKState stateWithName:kStateSetupCodeVerification];

  TKState *wifiListing = [TKState stateWithName:kStateSetupWifiListing];
  TKState *enteringWifiPassword = [TKState stateWithName:kStateEnteringWifiPassword];
  TKState *sameWiFiAwaiting = [TKState stateWithName:kStateSameWifiAwaiting];

  [self addStates:@[setupBonjourDiscovery, setupServiceResolving,
        setupServiceResolved, setupSocketConnected, codeVerification,
        wifiListing, enteringWifiPassword, sameWiFiAwaiting]];

  TKEvent *detectedInAirWifiEvent = [TKEvent eventWithName:kEventSetupDetectedInAirWifi
                                   transitioningFromStates:@[startWifiSetup]
                                                   toState:setupBonjourDiscovery];

  TKEvent *setupBonjourServiceFoundEvent = [TKEvent eventWithName:kEventSetupFoundBonjourService
                                          transitioningFromStates:@[setupBonjourDiscovery]
                                                          toState:setupServiceResolving];

  TKEvent *setupServiceResolvedEvent = [TKEvent eventWithName:kEventSetupServiceResolved
                                   transitioningFromStates:@[setupServiceResolving]
                                                   toState:setupServiceResolved];

  TKEvent *setupSocketConnectedEvent = [TKEvent eventWithName:kEventSetupSocketConnected
                                      transitioningFromStates:@[startWifiSetup, setupServiceResolved]
                                                      toState:setupSocketConnected];

  TKEvent *setupCodeVerificationReceivedEvent = [TKEvent eventWithName:kEventSetupCodeVerificationReceived
                                               transitioningFromStates:@[setupSocketConnected]
                                                               toState:codeVerification];

  TKEvent *userConfirmedCodeEvent = [TKEvent eventWithName:kEventSetupSameCodeVerified
                                   transitioningFromStates:@[codeVerification]
                                                   toState:wifiListing];

  TKEvent *userSelectedOpenWifiEvent = [TKEvent eventWithName:kEventSetupUserSelectedOpenWifi
                                      transitioningFromStates:@[wifiListing]
                                                      toState:sameWiFiAwaiting];

  TKEvent *userSelectedSecureWifiEvent = [TKEvent eventWithName:kEventSetupUserSelectedSecureWifi
                                        transitioningFromStates:@[wifiListing]
                                                        toState:enteringWifiPassword];

  TKEvent *userStartConnectedToSecureEvent = [TKEvent eventWithName:kEventUserConnectedToSecureWifi
                                            transitioningFromStates:@[enteringWifiPassword]
                                                            toState:sameWiFiAwaiting];

  TKEvent *detectedToTheSameWifiEvent = [TKEvent eventWithName:kEventSetupConnectedToTheSameNetwork
                                       transitioningFromStates:@[sameWiFiAwaiting]
                                                       toState:normalStart];

  TKEvent *failedToConnectToSocketEvent = [TKEvent eventWithName:kEventSetupFailedToConnectToSocket
                                    transitioningFromStates:@[setupBonjourDiscovery, setupServiceResolving, setupServiceResolved]
                                                    toState:startWifiSetup];

  TKEvent *failedToRetrieveConfirmationCodeEvent = [TKEvent eventWithName:kEventSetupFailedToRetrieveConfirmationCode
                                                  transitioningFromStates:@[codeVerification ]
                                                                  toState:startWifiSetup];

  TKEvent *backToCodeVerificationEvent = [TKEvent eventWithName:kEventSetupBackToCodeVerification
                                   transitioningFromStates:@[wifiListing]
                                                   toState:codeVerification];

  TKEvent *backToWifiListingEvent = [TKEvent eventWithName:kEventSetupBackToWifiListing
                                   transitioningFromStates:@[enteringWifiPassword] toState:wifiListing];

  [self addEvents:@[detectedInAirWifiEvent, setupBonjourServiceFoundEvent, setupServiceResolvedEvent,
      setupSocketConnectedEvent, setupCodeVerificationReceivedEvent, userConfirmedCodeEvent,
      userSelectedOpenWifiEvent, userSelectedSecureWifiEvent, userStartConnectedToSecureEvent,
      detectedToTheSameWifiEvent, failedToConnectToSocketEvent, failedToRetrieveConfirmationCodeEvent,
      backToCodeVerificationEvent,backToWifiListingEvent]];

}


-(void)fireEvent:(id)eventOrEventName  {
  NSError *error = nil;
  [[IAStateMachine sharedStateMachine] fireEvent:eventOrEventName userInfo:nil error:&error];
  if (error) {
    NSLog(@"ERROR: %@", error);
  }

}
@end