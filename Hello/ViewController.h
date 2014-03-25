//
//  ViewController.h
//  Hello
//
//  Created by James Mattis on 3/14/14.
//  Copyright (c) 2014 World Champ Tech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PebbleKit/PebbleKit.h>
#import "NSMutableArray+Queue.h"

@interface ViewController : UIViewController <PBPebbleCentralDelegate, PBWatchDelegate>

#pragma mark - General Pebble App Message Properties

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

// Pebble Watch App Lifecycle Handle

@property (nonatomic, assign) id appLifecycleHandle;

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
@property (assign, nonatomic) BOOL isRunning;
@property (assign, nonatomic) BOOL isReconnecting;

// Error Count

@property (assign, nonatomic) NSInteger errorCount;

#pragma mark - Testing Specific App Message Properties

// Display Color

@property (nonatomic, assign) NSInteger color;

// Test Stats

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
@property (nonatomic, assign) double runTime;

// Language Button Outlets

@property (strong, nonatomic) IBOutlet UIButton *englishButton;
@property (strong, nonatomic) IBOutlet UIButton *dutchButton;
@property (strong, nonatomic) IBOutlet UIButton *spanishButton;
@property (strong, nonatomic) IBOutlet UIButton *danishButton;
@property (strong, nonatomic) IBOutlet UIButton *frenchButton;
@property (strong, nonatomic) IBOutlet UIButton *italianButton;
@property (strong, nonatomic) IBOutlet UIButton *latinButton;
@property (strong, nonatomic) IBOutlet UIButton *portugueseButton;
@property (strong, nonatomic) IBOutlet UIButton *vietnameseButton;
@property (strong, nonatomic) IBOutlet UIButton *basqueButton;

// Control Switch Outlets

@property (strong, nonatomic) IBOutlet UISwitch *queueSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *maxDataSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *reducedSniffSwitch;

// Control Switch Bools

@property (assign, nonatomic) BOOL useQueue;
@property (assign, nonatomic) BOOL useMaxData;
@property (assign, nonatomic) BOOL useReducedSniff;

#pragma mark - Testing Specific Method

// Pebble Test Method

-(void)pebbleTest;

// Button Press Action

-(IBAction)buttonPress:(UIButton *)button;

// Switch Toggle Action

-(IBAction)switchToggle:(UISwitch *)theSwitch;

// Log Stats Method

-(void)logStats;


#pragma mark - General Pebble Methods

// Successful Pebble App Launch Method - Post Launch Clean Up

-(void)appLaunchSuccess;

// Pebble Watch Methods

-(void)enablePebbleHardware;

// Connect Pebble Display Method

-(void)connectPebbleDisplay;

// Reconnect Pebble Display Method

-(void)reconnectPebbleDisplay;

// Install Handlers Method

-(void)installHandlers;

// App Dictionay Byte Calculation Method

-(NSInteger)bytesForDictionary:(NSDictionary *)dictionary;

// Add Dictionary to Queue Method

-(void)addDictionaryToQueue:(NSDictionary *)dictionary;

// Pebble Push Update Method

-(void)pushPebbleUpdate;

// Kill Pebble App

-(void)killPebbleApp;

// Application Notifications

-(void)applicationDidBecomeActive:(NSNotification *)notification;
-(void)applicationWillResignActive:(NSNotification *)notification;
-(void)applicationDidEnterBackground:(NSNotification *)notification;
-(void)applicationWillEnterForeground:(NSNotification *)notification;
-(void)applicationWillTerminate:(NSNotification *)notification;

@end
