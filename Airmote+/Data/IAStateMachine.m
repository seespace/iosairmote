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
  TKState *idle = [TKState stateWithName:kIdleKey]; // Begin state
  TKState *startWifiSetup = [TKState stateWithName:kStateWifiSetupKey];
  TKState *setupBonjourDiscovery = [TKState stateWithName:kSetupBonjourDiscoveryKey];
  TKState *setupServiceResolving = [TKState stateWithName:kSetupServiceResolvingKey];
  TKState *setupAddressFound = [TKState stateWithName:kSetupAddressFoundKey];
  TKState *codeVerificationStart = [TKState stateWithName:kCodeVerificationStartKey];
  TKState *failedToConnectToInAirSocket = [TKState stateWithName:kFailedToConnectToInAirSocketKey];
  TKState *codeVerification = [TKState stateWithName:kCodeVerificationKey];
  TKState *wifiListing = [TKState stateWithName:kWifiListingKey];
  TKState *failedToGetWifiList = [TKState stateWithName:kFailedToGetWifiListingKey];
  TKState *enteringWifiPassword = [TKState stateWithName:kEnteringWifiPasswordKey];
  TKState *selectedOpenWifi = [TKState stateWithName:kSelectedOpenWifiKey];
  TKState *sameWiFiAwaiting = [TKState stateWithName:kSameWifiAwaitingKey];
  TKState *wifiSetupDone = [TKState stateWithName:kWifiSetupDoneKey];
  TKState *bonjourDiscovery = [TKState stateWithName:kBonjourDiscoveryKey];
  TKState *foundMultipleServices = [TKState stateWithName:kFoundMultipleServicesKey];
  TKState *serviceResolving = [TKState stateWithName:kServiceResolvingKey];
  TKState *addressResolved = [TKState stateWithName:kAddressResolvedKey];
  TKState *socketConnected = [TKState stateWithName:kSocketConnectedKey];  //Done state

  [self addStates:@[idle, startWifiSetup, setupBonjourDiscovery, setupServiceResolving,
      setupAddressFound, failedToConnectToInAirSocket, codeVerificationStart,
      codeVerification, wifiListing, failedToGetWifiList, enteringWifiPassword,
      selectedOpenWifi, sameWiFiAwaiting, wifiSetupDone, bonjourDiscovery,
      foundMultipleServices, serviceResolving, addressResolved, socketConnected]];


  TKEvent *startSetupEvent = [TKEvent eventWithName:@"Setup: Start" transitioningFromStates:@[idle] toState:startWifiSetup];
  TKEvent *detectedInAirWifiEvent = [TKEvent eventWithName:@"Setup: Detected InAiR Wifi" transitioningFromStates:@[startWifiSetup] toState:setupBonjourDiscovery];
  TKEvent *setupBonjourServiceFoundEvent = [TKEvent eventWithName:@"Setup: Found InAir Service" transitioningFromStates:@[setupBonjourDiscovery] toState:setupServiceResolving];
  TKEvent *setupAddressFoundEvent = [TKEvent eventWithName:@"Setup: Address Found" transitioningFromStates:@[setupServiceResolving] toState:setupAddressFound];
  TKEvent *setupSocketConnectedEvent = [TKEvent eventWithName:@"Setup: Socket Connected" transitioningFromStates:@[setupAddressFound] toState:codeVerificationStart];
  TKEvent *setupCodeVerificationReceivedEvent = [TKEvent eventWithName:@"Setup: Code verification received" transitioningFromStates:@[codeVerificationStart] toState:codeVerification];
  TKEvent *userConfirmedCodeEvent = [TKEvent eventWithName:@"Setup: Same code verified" transitioningFromStates:@[codeVerification] toState:wifiListing];
  TKEvent *userSelectedOpenWifiEvent = [TKEvent eventWithName:@"Setup: User selected open wifi" transitioningFromStates:@[wifiListing] toState:sameWiFiAwaiting];
  TKEvent *userSelectedSecureWifiEvent = [TKEvent eventWithName:@"Setup: User selected secure wifi" transitioningFromStates:@[wifiListing] toState:enteringWifiPassword];
  TKEvent *userStartConnectedToSecureEvent = [TKEvent eventWithName:@"Setup: User conncected secure wifi" transitioningFromStates:@[enteringWifiPassword] toState:sameWiFiAwaiting];
  TKEvent *detectedToTheSameWifiEvent = [TKEvent eventWithName:@"Setup: Connected to the same network" transitioningFromStates:@[sameWiFiAwaiting] toState:wifiSetupDone];
  TKEvent *startBonjourServiceEvent = [TKEvent eventWithName:@"Start bonjour" transitioningFromStates:@[wifiSetupDone] toState:bonjourDiscovery];
  TKEvent *foundSingleServiceEvent = [TKEvent eventWithName:@"Found one service" transitioningFromStates:@[bonjourDiscovery] toState:serviceResolving];
  TKEvent *foundMultipleServicesEvent = [TKEvent eventWithName:@"Found multiple services" transitioningFromStates:@[bonjourDiscovery] toState:foundMultipleServices];
  TKEvent *foundAddressEvent = [TKEvent eventWithName:@"Found Address" transitioningFromStates:@[serviceResolving] toState:addressResolved];
  TKEvent *socketConnectedEvent = [TKEvent eventWithName:@"Socket Connected" transitioningFromStates:@[addressResolved] toState:socketConnected];

  [self addEvents:@[startSetupEvent, detectedInAirWifiEvent, setupBonjourServiceFoundEvent, setupAddressFoundEvent, setupSocketConnectedEvent, setupCodeVerificationReceivedEvent,
  userConfirmedCodeEvent, userSelectedOpenWifiEvent, userSelectedSecureWifiEvent, userStartConnectedToSecureEvent, detectedToTheSameWifiEvent,
  startBonjourServiceEvent, foundSingleServiceEvent, foundMultipleServicesEvent, foundAddressEvent, socketConnectedEvent]];
}

@end