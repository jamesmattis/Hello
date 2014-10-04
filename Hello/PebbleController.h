//
//  PebbleController.h
//  Hello
//
//  Created by James Mattis on 3/25/14.
//  Copyright (c) 2014 World Champ Tech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PebbleKit/PebbleKit.h>
#import "NSMutableArray+Queue.h"

#pragma mark - PEBBLE ENUMS

enum PebbleData
{
    CustomAppMessageKey = 0,
    CustomAppDataKey = 1,
    CustomAppSniffKey = 2
};

@protocol PebbleControllerDelegate;

@interface PebbleController : NSObject <PBPebbleCentralDelegate, PBWatchDelegate>

#pragma mark - Properties

// Delegate

@property (weak, nonatomic) id <PebbleControllerDelegate> delegate;

// Pebble Watch

@property (strong, nonatomic) PBWatch *watch;

// Pebble App UUID

@property (strong, nonatomic) NSData *appUUID;

// Pebble Queued Update Dictionary

@property (strong, nonatomic) NSMutableDictionary *queuedPebbleMessageUpdate;

// Pebble Update Queue

@property (strong, nonatomic) NSMutableArray *pebbleMessageUpdateQueue;

// Pebble Watch App Update Handle

@property (nonatomic, assign) id appUpdateHandle;

// Control Bools

@property (assign, nonatomic) BOOL useQueue;
@property (assign, nonatomic) BOOL useMaxData;
@property (assign, nonatomic) BOOL useReducedSniff;

// Pebble Watch BOOL Properties

@property (assign, nonatomic) BOOL pebbleHardwareEnabled;
@property (assign, nonatomic) BOOL pebbleAppUUIDSet;
@property (assign, nonatomic) BOOL useCustomPebbleApp;
@property (assign, nonatomic) BOOL isSendingPebbleUpdate;
@property (assign, nonatomic) BOOL isResettingPebble;
@property (assign, nonatomic) BOOL isManuallyResettingPebble;
@property (assign, nonatomic) BOOL shouldKillPebbleApp;
@property (assign, nonatomic) BOOL shouldClosePebbleSession;
@property (assign, nonatomic) BOOL pebbleSessionOpen;
@property (assign, nonatomic) BOOL pebbleConnected;

// Error Count

@property (assign, nonatomic) NSInteger errorCount;

// Stats

@property (nonatomic, assign) NSInteger pushes;
@property (nonatomic, assign) NSInteger receivedMessages;
@property (nonatomic, assign) NSInteger pushFails;
@property (nonatomic, assign) NSInteger blockedPushes;
@property (nonatomic, assign) NSInteger successfulPushes;
@property (nonatomic, assign) NSInteger timeoutErrors;
@property (nonatomic, assign) NSInteger timeoutCycles;
@property (nonatomic, assign) NSInteger totalErrors;
@property (nonatomic, assign) NSInteger errorRecoveries;
@property (nonatomic, assign) NSInteger pushedBytes;
@property (nonatomic, assign) NSInteger blockedBytes;
@property (nonatomic, assign) NSInteger failedBytes;
@property (nonatomic, assign) NSInteger disconnectConnectCycles;
@property (nonatomic, assign) double runTime;

#pragma mark - Methods

// Singleton Class Factory Method

+(PebbleController *)pebble;

// Pebble Watch Methods

-(void)enablePebbleHardware;

// Connect Pebble Display Method

-(void)connectPebbleDisplay;

// Install Handlers Method

-(void)installHandlers;

// App Dictionay Byte Calculation Method

-(NSInteger)bytesForDictionary:(NSDictionary *)dictionary;

// Add Dictionary to Queue Method

-(BOOL)addDictionaryToQueue:(NSDictionary *)dictionary;

// Sould Push Pebble Update Method

-(BOOL)shouldPushPebbleUpdate;

// Pebble Push Update Method

-(void)pushPebbleUpdate;

// Kill Pebble App

-(void)killPebbleApp;

// Clean Up Pebble App

-(void)cleanUpPebbleApp;

// Log & Reset Stats Methods

-(void)logStats;
-(void)resetStats;

@end


@protocol PebbleControllerDelegate <NSObject>

-(void)pebbleLaunchSuccess;
-(void)appLifecycleUpdateReceived:(PBAppState)state;
-(void)appUpdateReceived:(NSDictionary *)message;
-(void)appMessagePushCallBackReceived:(NSError *)error;
-(void)watchWillReset;
-(BOOL)getIsRunningStatus;

@end

