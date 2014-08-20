//
// Created by Manh Tuan Cao on 8/20/14.
// Copyright (c) 2014 Long Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BonjourManager;
@protocol BonjourManagerDelegate <NSObject>

@required
-(void) bonjourManagerDidFoundServices:(NSArray *) services;

@optional
-(void) bonjourManagerDidResolveHostNames:(NSArray *) hosts;

@end

@interface BonjourManager : NSObject <NSNetServiceDelegate>

@property (nonatomic, weak) id <BonjourManagerDelegate> delegate;

-(void) start;
@end