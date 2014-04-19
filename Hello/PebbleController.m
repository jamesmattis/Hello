//
//  PebbleController.m
//  Hello
//
//  Created by James Mattis on 3/25/14.
//  Copyright (c) 2014 World Champ Tech. All rights reserved.
//

#import <mach/mach.h>
#import "PebbleController.h"

// Log All Pushes

#define LOG_ALL_PUSHES NO

#pragma mark - PEBBLE WATCH APP UUID

// Hint: Copy this from appinfo.auto.c file in Watch App build folder after building watch app

uint8_t pebbleAppUUID[] = {0xA3, 0xE3, 0x3D, 0x68, 0xB3, 0x51, 0x41, 0x73, 0xAB, 0x8F, 0xDF, 0xEE, 0xEA, 0x46, 0xB1, 0xCD};

@interface PebbleController ()
{
    // Pebble Controller Concurrent Dispatch Queue
    
    dispatch_queue_t queue;
}
@end


@implementation PebbleController

#pragma mark - Singleton Class Factory Method

+(PebbleController *)pebble
{
    static PebbleController *pebble = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once (&onceToken, ^{
        pebble = [[PebbleController alloc] init];
    });
    
    return pebble;
}

#pragma mark - Init

-(id)init
{
    if (self = [super init])
    {
        // Test Stats
        
        self.pushes = 0;
        self.pushFails = 0;
        self.successfulPushes = 0;
        self.receivedMessages = 0;
        self.blockedPushes = 0;
        self.pushFails = 0;
        self.timeoutErrors = 0;
        self.totalErrors = 0;
        self.errorRecoveries = 0;
        self.runTime = 0.0;
        self.pushedBytes = 0;
        self.blockedBytes = 0;
        self.failedBytes = 0;
        self.timeoutCycles = 0;
        
        // Setup Pebble BOOLs
        
        self.pebbleHardwareEnabled = NO;
        self.pebbleAppUUIDSet = NO;
        self.useCustomPebbleApp = NO;
        self.isSendingPebbleUpdate = NO;
        self.isResettingPebble = NO;
        self.shouldKillPebbleApp = NO;
        self.shouldClosePebbleSession = NO;
        self.pebbleSessionOpen = NO;
        self.pebbleConnected = NO;
        self.isReconnecting = NO;
        self.isManuallyResettingPebble = NO;
        
        // Error Count
        
        self.errorCount = 0;
        
        // State BOOLs
        
        self.useQueue = YES;
        self.useMaxData = YES;
        self.useReducedSniff = NO;
        
        // Setup Pebble App UUID
        
        self.appUUID = [NSData dataWithBytes:pebbleAppUUID length:sizeof(pebbleAppUUID)];

        // Setup Private Queue
        
        queue = dispatch_queue_create("com.jamesmattis.pebblequeue", DISPATCH_QUEUE_CONCURRENT);
        
        dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        
        // Setup Queued Pebble Update Dictionary
        
        self.queuedPebbleMessageUpdate = [[NSMutableDictionary alloc] init];
        
        // Setup Pebble Update Queue Array
        
        self.pebbleMessageUpdateQueue = [[NSMutableArray alloc] init];
        
        self.appLifecycleHandle = nil;
        self.appUpdateHandle = nil;
    }
    
    return self;
}

#pragma mark - Log Stats & Reset Stats

-(void)logStats
{
    int seconds = (int) self.runTime % 60;
    int minutes = (int) (self.runTime / 60) % 60;
    int hours = (int) (self.runTime / 3600.0);
    
    NSLog(@"Run Time: %02d:%02d:%02d (%1.1f s)", hours, minutes, seconds, self.runTime);
    NSLog(@"Message Pushes: %ld Successful: %ld (%1.2f %%)", (long)self.pushes, (long)self.successfulPushes, 100.0 * ((float) self.successfulPushes) / ((float) self.pushes));
    NSLog(@"PushedBytes: %1.1f MB %1.1f kB %1.3f kB/s", ((float)self.pushedBytes / 1000000.0), ((float)self.pushedBytes / 1000.0), ((float)self.pushedBytes / 1000.0) / self.runTime);
    NSLog(@"Blocked Pushes: %ld (%1.2f %%)", (long)self.blockedPushes, 100.0 * ((float) self.blockedPushes) / ((float) self.pushes));
    NSLog(@"BlockedBytes: %1.1f MB %1.1f kB %1.3f kB/s", ((float)self.blockedBytes / 1000000.0), ((float)self.blockedBytes / 1000.0), ((float)self.blockedBytes / 1000.0) / self.runTime);
    NSLog(@"Receieved Messages: %ld", (long)self.receivedMessages);

    if (self.useQueue)
    {
        NSInteger bytesInQueue = 0;
        
        for (NSDictionary *dictionary in self.pebbleMessageUpdateQueue)
        {
            bytesInQueue += [self bytesForDictionary:dictionary];
        }
        
        NSLog(@"Queued Message Dictionaries: %ld Bytes (kb): %1.3f", (long)self.pebbleMessageUpdateQueue.count, ((float)self.pushedBytes / 1000.0));
    }
    
    NSLog(@"Failed Pushes: %ld (%1.2f %%)", (long)self.pushFails, 100.0 * ((float) self.pushFails) / ((float) self.pushes));
    
    if (self.totalErrors > 0)
    {
        double averageTimeoutTime = self.runTime / ((double) self.timeoutCycles);
        
        int avgSeconds = (int) averageTimeoutTime % 60;
        int avgMinutes = (int) (averageTimeoutTime / 60) % 60;
        int avgHours = (int) (averageTimeoutTime / 3600.0);
        
        NSLog(@"Timeout Errors: %ld (%1.2f %% Total Errors) (%1.2f %% Total Pushes)", (long)self.timeoutErrors, 100.0 * ((float) self.timeoutErrors) / ((float) self.totalErrors), 100.0 * ((float) self.timeoutErrors) / ((float) self.pushes));
        NSLog(@"Timeout Bytes: %ld", (long)self.failedBytes);
        
        NSLog(@"Total Errors: %ld", (long)self.totalErrors);
        NSLog(@"Error Recoveries: %ld (%1.2f %%)", (long)self.errorRecoveries, 100.0 * ((float) self.errorRecoveries) / ((float) self.timeoutErrors));
        NSLog(@"Average Time Between Timeout %02d:%02d:%02d", avgHours, avgMinutes, avgSeconds);
    }
    else
    {
        NSLog(@"Total Errors: %ld", (long)self.totalErrors);
    }
    
    NSLog(@"______________________________________________");
}

-(void)resetStats
{
    // Reset Stats
    
    self.pushes = 0;
    self.pushFails = 0;
    self.successfulPushes = 0;
    self.receivedMessages = 0;
    self.blockedPushes = 0;
    self.pushFails = 0;
    self.timeoutErrors = 0;
    self.totalErrors = 0;
    self.errorRecoveries = 0;
    self.runTime = 0.0;
    self.pushedBytes = 0;
    self.blockedBytes = 0;
    self.failedBytes = 0;
    self.timeoutCycles = 0;
}

#pragma mark - Pebble Watch Methods

-(void)enablePebbleHardware
{
    NSLog(@"enablePebbleHardware");
    
    [PBPebbleCentral setDebugLogsEnabled:NO];
    
    [[PBPebbleCentral defaultCentral] setDelegate:self];
    
    if ([PBPebbleCentral defaultCentral].connectedWatches.count > 0)
    {
        self.watch = [PBPebbleCentral defaultCentral].lastConnectedWatch;
        
        if (self.watch)
        {
            [self.watch setDelegate:self];
            
            if ([self.watch isConnected])
            {
                self.pebbleHardwareEnabled = YES;
                
                NSLog(@"enablePebbleHardware self.watch.serialNumber: %@", self.watch.serialNumber);
                
                NSString *settingsName = [NSString stringWithFormat:@"Pebble-%@-versionMajor", self.watch.serialNumber];
                
                if (![[NSUserDefaults standardUserDefaults].dictionaryRepresentation.allKeys containsObject:settingsName])
                {
                    __weak __typeof__(self) weakSelf = self;
                    
                    [self.watch getVersionInfo:^(PBWatch *watch, PBVersionInfo *versionInfo)
                     {
                         __strong __typeof__(self) strongSelf = weakSelf;
                         
                         [[NSUserDefaults standardUserDefaults] setInteger:versionInfo.runningFirmwareMetadata.version.major forKey:settingsName];
                         [[NSUserDefaults standardUserDefaults] synchronize];
                         
                         if ([strongSelf.watch.versionInfo.runningFirmwareMetadata.version.suffix length] > 0)
                             NSLog(@"enablePebbleHardware getVersionInfo %ld.%ld.%ld-%@", (long)strongSelf.watch.versionInfo.runningFirmwareMetadata.version.os, (long)strongSelf.watch.versionInfo.runningFirmwareMetadata.version.major, (long)strongSelf.watch.versionInfo.runningFirmwareMetadata.version.minor, strongSelf.watch.versionInfo.runningFirmwareMetadata.version.suffix);
                         else
                             NSLog(@"enablePebbleHardware getVersionInfo %ld.%ld.%ld", (long)strongSelf.watch.versionInfo.runningFirmwareMetadata.version.os, (long)strongSelf.watch.versionInfo.runningFirmwareMetadata.version.major, (long)strongSelf.watch.versionInfo.runningFirmwareMetadata.version.minor);
                         
                         NSLog(@"enablePebbleHardware setAppUUID");
                         
                         [[PBPebbleCentral defaultCentral] setAppUUID:strongSelf.appUUID];
                         
                         if ([[PBPebbleCentral defaultCentral] hasValidAppUUID])
                         {
                             // Do Nothing
                             
                             NSLog(@"enablePebbleHardware hasValidAppUUID");
                             
                             strongSelf.pebbleAppUUIDSet = YES;
                             strongSelf.useCustomPebbleApp = YES;
                             
                             [strongSelf connectPebbleDisplay];
                         }
                         else
                         {
                             NSLog(@"enablePebbleHardware !hasValidAppUUID");
                         }
                     } onTimeout:^(PBWatch *watch)
                     {
                         NSLog(@"enablePebbleHardware getVersionInfo onTimeout");
                         
                     }];
                }
                else
                {
                    NSInteger version = [[NSUserDefaults standardUserDefaults] integerForKey:settingsName];
                    
                    if (version >= 2)
                    {
                        [[PBPebbleCentral defaultCentral] setAppUUID:self.appUUID];
                        
                        if ([[PBPebbleCentral defaultCentral] hasValidAppUUID])
                        {
                            // Do Nothing
                            
                            NSLog(@"enablePebbleHardware hasValidAppUUID");
                            
                            self.pebbleAppUUIDSet = YES;
                            self.useCustomPebbleApp = YES;
                            
                            [self connectPebbleDisplay];
                        }
                        else
                        {
                            NSLog(@"enablePebbleHardware !hasValidAppUUID");
                        }
                    }
                    else
                    {
                        // Check if the version has been updated
                        
                        __weak __typeof__(self) weakSelf = self;
                        
                        [self.watch getVersionInfo:^(PBWatch *watch, PBVersionInfo *versionInfo)
                         {
                             __strong __typeof__(self) strongSelf = weakSelf;
                             
                             [[NSUserDefaults standardUserDefaults] setInteger:versionInfo.runningFirmwareMetadata.version.major forKey:settingsName];
                             [[NSUserDefaults standardUserDefaults] synchronize];
                             
                             if ([strongSelf.watch.versionInfo.runningFirmwareMetadata.version.suffix length] > 0)
                                 NSLog(@"enablePebbleHardware getVersionInfo %ld.%ld.%ld-%@", (long)strongSelf.watch.versionInfo.runningFirmwareMetadata.version.os, (long)strongSelf.watch.versionInfo.runningFirmwareMetadata.version.major, (long)strongSelf.watch.versionInfo.runningFirmwareMetadata.version.minor, strongSelf.watch.versionInfo.runningFirmwareMetadata.version.suffix);
                             else
                                 NSLog(@"enablePebbleHardware getVersionInfo %ld.%ld.%ld", (long)strongSelf.watch.versionInfo.runningFirmwareMetadata.version.os, (long)strongSelf.watch.versionInfo.runningFirmwareMetadata.version.major, (long)strongSelf.watch.versionInfo.runningFirmwareMetadata.version.minor);
                             
                             NSLog(@"enablePebbleHardware setAppUUID");
                             
                             [[PBPebbleCentral defaultCentral] setAppUUID:strongSelf.appUUID];
                             
                             if ([[PBPebbleCentral defaultCentral] hasValidAppUUID])
                             {
                                 // Do Nothing
                                 
                                 NSLog(@"enablePebbleHardware hasValidAppUUID");
                                 
                                 strongSelf.pebbleAppUUIDSet = YES;
                                 strongSelf.useCustomPebbleApp = YES;
                                 
                                 [strongSelf connectPebbleDisplay];
                             }
                             else
                             {
                                 NSLog(@"enablePebbleHardware !hasValidAppUUID");
                             }
                         } onTimeout:^(PBWatch *watch)
                         {
                             NSLog(@"enablePebbleHardware getVersionInfo onTimeout");
                             
                         }];
                    }
                }
            }
            else
            {
                self.pebbleHardwareEnabled = NO;
            }
            
            NSLog(@"enablePebbleHardware self.pebbleHardwareEnabled = YES;");
        }
    }
}

#pragma mark - Install Handlers Method

-(void)installHandlers
{
    NSLog(@"installHandlers");
    
    if (self.appUpdateHandle)
    {
        [self.watch appMessagesRemoveUpdateHandler:self.appUpdateHandle];
        
        self.appUpdateHandle = nil;
    }
    
    __weak __typeof__(self) weakSelf = self;
    
    self.appUpdateHandle = [self.watch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update){
        
        __strong __typeof__(self) strongSelf = weakSelf;
        
        strongSelf.receivedMessages++;
        
        [strongSelf.delegate appUpdateReceived:update];
        
        NSMutableString *appMessage = [[NSMutableString alloc] init];
        
        for (NSString *key in [update allKeys])
        {
            [appMessage appendFormat:@"key: %@ value %@ ", key, update[key]];
        }
        
        NSLog(@"appMessageUpdateHandler %@", appMessage);
        
        return YES;
        
    } withUUID:self.appUUID];
    
    self.appLifecycleHandle = [self.watch appMessagesAddAppLifecycleUpdateHandler:^(PBWatch *watch , NSUUID *uuid , PBAppState newAppState){
        
        __strong __typeof__(self) strongSelf = weakSelf;
        
        [strongSelf.delegate appLifecycleUpdateReceived:newAppState];
        
        NSLog(@"appMessageLifecycleHandler");
        
        if (newAppState == PBAppStateNotRunning)
        {
            NSLog(@"appMessageLifecycleHandler PBAppStateNotRunning");
            
            [strongSelf connectPebbleDisplay];
        }
        else
        {
            NSLog(@"appMessageLifecycleHandler PBAppStateRunning");
            
            [strongSelf.delegate pebbleLaunchSuccess];
        }
    }];
}

#pragma mark - Connect Pebble Display Method

-(void)connectPebbleDisplay
{
    NSLog(@"connectPebbleDisplay");
    
    if (self.pebbleHardwareEnabled)
    {
        __weak __typeof__(self) weakSelf = self;
        
        __weak PBPebbleCentral *weakPebbleCentral = [PBPebbleCentral defaultCentral];
        
        self.isSendingPebbleUpdate = YES;
        
        [self.watch appMessagesGetIsSupported:^(PBWatch *watch, BOOL isAppMessagesSupported)
         {
             __strong __typeof__(self) strongSelf = weakSelf;
             __strong PBPebbleCentral *strongPebbleCentral = weakPebbleCentral;
             
             if (isAppMessagesSupported)
             {
                 if (!strongSelf.pebbleAppUUIDSet || (strongPebbleCentral.appUUID != strongSelf.appUUID))
                 {
                     NSLog(@"connectPebbleDisplay !strongSelf.pebbleAppUUIDSet %@", ((!strongSelf.pebbleAppUUIDSet)? @"YES" : @"NO"));
                     NSLog(@"connectPebbleDisplay strongPebbleCentral.appUUID != self.appUUID %@", ((strongPebbleCentral.appUUID != strongSelf.appUUID)? @"YES" : @"NO"));
                     
                     [strongPebbleCentral setAppUUID:strongSelf.appUUID];
                     
                     if ([strongPebbleCentral hasValidAppUUID])
                     {
                         // Do Nothing
                         
                         NSLog(@"connectPebbleDisplay setAppUUID hasValidAppUUID");
                     }
                     else
                     {
                         NSLog(@"connectPebbleDisplay setAppUUID !hasValidAppUUID");
                     }
                     
                     strongSelf.pebbleAppUUIDSet = YES;
                     
                     [watch appMessagesLaunch:^(PBWatch *watch, NSError *error)
                      {
                          if (!error)
                          {
                              dispatch_barrier_sync(strongSelf->queue, ^{
                                  strongSelf.pebbleConnected = YES;
                                  strongSelf.isSendingPebbleUpdate = NO;
                              });
                              
                              [strongSelf installHandlers];
                              
                              [strongSelf.delegate pebbleLaunchSuccess];
                          }
                          else
                          {
                              // Do Nothing Once New SDK Released
                              
                              dispatch_barrier_sync(strongSelf->queue, ^{
                                  strongSelf.pebbleConnected = YES;
                                  strongSelf.isSendingPebbleUpdate = NO;
                              });
                              
                              [strongSelf installHandlers];
                              
                              [strongSelf.delegate pebbleLaunchSuccess];
                          }
                          
                          if (error)
                              NSLog(@"connectPebbleDisplay appMessagesLaunch error: %@", error.debugDescription);
                          else
                              NSLog(@"connectPebbleDisplay appMessagesLaunch");
                      } withUUID:strongSelf.appUUID];
                 }
                 else
                 {
                     NSLog(@"connectPebbleDisplay pebbleAppUUDISet");
                     NSLog(@"connectPebbleDisplay strongSelf.pebbleAppUUIDSet %@", ((strongSelf.pebbleAppUUIDSet)? @"YES" : @"NO"));
                     NSLog(@"connectPebbleDisplay strongPebbleCentral.appUUID == self.appUUID %@", ((strongPebbleCentral.appUUID == strongSelf.appUUID)? @"YES" : @"NO"));
                     
                     [watch appMessagesLaunch:^(PBWatch *watch, NSError *error)
                      {
                          if (!error)
                          {
                              dispatch_barrier_sync(strongSelf->queue, ^{
                                  strongSelf.pebbleConnected = YES;
                                  strongSelf.isSendingPebbleUpdate = NO;
                              });
                              
                              [strongSelf installHandlers];
                              
                              [strongSelf.delegate pebbleLaunchSuccess];
                          }
                          else
                          {
                              // Do Nothing Once New SDK Released
                              
                              dispatch_barrier_sync(strongSelf->queue, ^{
                                  strongSelf.pebbleConnected = YES;
                                  strongSelf.isSendingPebbleUpdate = NO;
                              });
                              
                              [strongSelf installHandlers];
                              
                              [strongSelf.delegate pebbleLaunchSuccess];
                          }
                          
                          if (error)
                              NSLog(@"connectPebbleDisplay appMessagesLaunch error: %@", error.debugDescription);
                          else
                              NSLog(@"connectPebbleDisplay appMessagesLaunch");
                      } withUUID:strongSelf.appUUID];
                 }
             }
             else
             {
                 NSLog(@"connectPebbleDisplay !isAppMessagesSupported");
                 
                 // Do Nothing
             }
         }];
    }
}

#pragma mark - ADD DICTIONARY TO QUEUE METHOD

-(void)addDictionaryToQueue:(NSDictionary *)dictionary
{
    __weak __typeof__(self) weakSelf = self;

    // Update Queued Dictionary
    
    dispatch_barrier_sync(queue, ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        
        if ((strongSelf.queuedPebbleMessageUpdate)[@(CustomAppDataKey)])
        {
            [strongSelf.queuedPebbleMessageUpdate removeObjectForKey:@(CustomAppDataKey)];
        }
        
        for (NSString *key in dictionary)
        {
            (strongSelf.queuedPebbleMessageUpdate)[key] = dictionary[key];
        }
        
        if (strongSelf.useMaxData)
        {
            NSInteger dataLength = (123 - 7) - [strongSelf bytesForDictionary:strongSelf.queuedPebbleMessageUpdate];

            (strongSelf.queuedPebbleMessageUpdate)[@(CustomAppDataKey)] = [NSMutableData dataWithLength:dataLength];
        }
    });
    
    if (LOG_ALL_PUSHES)
        NSLog(@"pebbleTest bytesForDictionary: %ld", (long)[self bytesForDictionary:self.queuedPebbleMessageUpdate]);
    
    // Get Latest Dictionary
    
    __block NSDictionary *updateDictionary;
    
    dispatch_sync(queue, ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        
        updateDictionary = [[NSDictionary alloc] initWithDictionary:strongSelf.queuedPebbleMessageUpdate];
    });
    
    dispatch_barrier_sync(queue, ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        
        [strongSelf.pebbleMessageUpdateQueue enqueue:updateDictionary];
    });
    
    // Push Update
    
    if (self.queuedPebbleMessageUpdate.count > 0 || self.shouldKillPebbleApp)
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong __typeof__(self) strongSelf = weakSelf;
            
            [strongSelf pushPebbleUpdate];
        });
}

#pragma mark - Pebble Push Update Method

-(void)pushPebbleUpdate
{
    if (LOG_ALL_PUSHES)
        NSLog(@"pushPebbleUpdate");
    
    self.pushes++;
    
    // For Max Rate Testing, Update Stats Every 10000 pushes
    
    if (fmodf(((float) self.pushes), 10000.0) == 0.0)
    {
        [self logStats];
    }
    
    if (self.useCustomPebbleApp)
    {
        __block BOOL shouldPushUpdate = NO;
        
        __weak __typeof__(self) weakSelf = self;
        
        dispatch_sync(queue, ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            
            shouldPushUpdate = (!strongSelf.isSendingPebbleUpdate
                                && !strongSelf.isResettingPebble
                                && (strongSelf.pebbleSessionOpen || strongSelf.isManuallyResettingPebble)
                                && strongSelf.pebbleConnected
                                && strongSelf.pebbleAppUUIDSet
                                && strongSelf.pebbleHardwareEnabled);
        });
        
        if (shouldPushUpdate)
        {
            if (!self.shouldKillPebbleApp)
            {
                if ((self.queuedPebbleMessageUpdate.count > 0 && !self.useQueue) || (self.pebbleMessageUpdateQueue.count > 0 && self.useQueue))
                {
                    dispatch_barrier_sync(queue, ^{
                        __strong __typeof__(self) strongSelf = weakSelf;
                        
                        strongSelf.isSendingPebbleUpdate = YES;
                    });
                    
                    __block NSDictionary *updateDictionary;
                    
                    if (self.useQueue)
                    {
                        dispatch_sync(queue, ^{
                            __strong __typeof__(self) strongSelf = weakSelf;
                            
                            updateDictionary = [NSDictionary dictionaryWithDictionary:(NSDictionary *)[strongSelf.pebbleMessageUpdateQueue headOfQueue]];
                        });
                    }
                    else
                    {
                        dispatch_sync(queue, ^{
                            __strong __typeof__(self) strongSelf = weakSelf;
                            
                            updateDictionary = [NSDictionary dictionaryWithDictionary:strongSelf.queuedPebbleMessageUpdate];
                        });
                    }
                    
                    if (LOG_ALL_PUSHES)
                        NSLog(@"pushPebbleUpdate labelString: %@", updateDictionary[@(CustomAppMessageKey)]);
                    
                    if (self.errorCount > 0)
                        NSLog(@"self.watch appMessagesPushUpdate error.count %ld", (long)self.errorCount);
                    
                    [self.watch appMessagesPushUpdate:updateDictionary withUUID:self.appUUID onSent:^(PBWatch *watch, NSDictionary *update, NSError *error)
                     {
                         __strong __typeof__(self) strongSelf = weakSelf;
                         
                         [strongSelf.delegate appMessagePushCallBackReceived:error];
                         
                         if (error)
                         {
                             strongSelf.totalErrors++;
                             
                             strongSelf.pushFails++;
                             strongSelf.failedBytes += [strongSelf bytesForDictionary:update];
                             
                             NSLog(@"pushPebbleUpdate appMessagesPushUpdate errorCount: %ld error: %@", (long)strongSelf.errorCount, error.debugDescription);
                             
                             if (strongSelf.errorCount == 0)
                                 strongSelf.timeoutCycles++;
                             
                             strongSelf.errorCount++;
                             
                             if (error.code == 10)
                             {
                                 strongSelf.timeoutErrors++;
                                 
                                 dispatch_async(dispatch_get_main_queue(), ^(void) {
                                     NSLog(@"pushPebbleUpdate appMessagesPushUpdate error dispatch code 10");
                                     
                                     dispatch_barrier_sync(strongSelf->queue, ^{
                                         strongSelf.isSendingPebbleUpdate = NO;
                                     });
                                     
                                     if (!strongSelf.isResettingPebble)
                                         dispatch_async(dispatch_get_main_queue(), ^(void) {
                                             strongSelf.isManuallyResettingPebble = YES;
                                             
                                             [strongSelf.watch closeSession:^{
                                                 
                                                 [strongSelf pushPebbleUpdate];
                                             }];
                                         });
                                 });
                             }
                             else if (error.code == 9)
                             {
                                 dispatch_async(dispatch_get_main_queue(), ^(void) {
                                     NSLog(@"pushPebbleUpdate appMessagesPushUpdate error dispatch code 9");
                                     
                                     dispatch_barrier_sync(strongSelf->queue, ^{
                                         strongSelf.isSendingPebbleUpdate = NO;
                                     });
                                     
                                     if (!weakSelf.isResettingPebble)
                                         dispatch_async(dispatch_get_main_queue(), ^(void) {
                                             strongSelf.isManuallyResettingPebble = YES;
                                             
                                             [strongSelf.watch closeSession:^{
                                                 
                                                 [strongSelf pushPebbleUpdate];
                                             }];
                                         });
                                 });
                             }
                             else
                             {
                                 NSLog(@"pushPebbleUpdate appMessagesPushUpdate error code %ld", (long)error.code);
                                 
                                 dispatch_barrier_sync(strongSelf->queue, ^{
                                     strongSelf.isSendingPebbleUpdate = NO;
                                 });
                                 
                                 if (!weakSelf.isResettingPebble)
                                     dispatch_async(dispatch_get_main_queue(), ^(void) {

                                         strongSelf.isManuallyResettingPebble = YES;
                                         
                                         [strongSelf.watch closeSession:^{
                                             
                                             [strongSelf pushPebbleUpdate];
                                         }];
                                         
                                     });
                             }
                         }
                         else
                         {
                             dispatch_barrier_async(queue, ^{
                                 __strong __typeof__(self) strongSelf = weakSelf;
                                 
                                 [strongSelf.queuedPebbleMessageUpdate removeAllObjects];
                                 [strongSelf.pebbleMessageUpdateQueue dequeue];
                             });
                             
                             strongSelf.successfulPushes++;
                             strongSelf.pushedBytes += [strongSelf bytesForDictionary:update];
                             
                             if (strongSelf.errorCount > 0)
                                 strongSelf.errorRecoveries++;
                             
                             dispatch_barrier_sync(strongSelf->queue, ^{
                                 strongSelf.isSendingPebbleUpdate = NO;
                                 strongSelf.errorCount = 0;
                             });
                             
                             if ((!strongSelf.useQueue && strongSelf.queuedPebbleMessageUpdate.count > 0) || (strongSelf.useQueue && strongSelf.pebbleMessageUpdateQueue.count > 0) || strongSelf.shouldKillPebbleApp)
                                 dispatch_async(dispatch_get_main_queue(), ^(void) {
                                     
                                     [strongSelf pushPebbleUpdate];
                                 });
                         }
                     }];
                }
            }
            else
            {
                [self killPebbleApp];
            }
        }
        else
        {
            self.blockedPushes++;
            
            __block NSDictionary *updateDictionary;
            
            dispatch_sync(queue, ^{
                __strong __typeof__(self) strongSelf = weakSelf;
                
                updateDictionary = [NSDictionary dictionaryWithDictionary:[strongSelf.pebbleMessageUpdateQueue headOfQueue]];
            });
            
            self.blockedBytes += [self bytesForDictionary:updateDictionary];
            
            // Log Why Not
            
            if (self.isSendingPebbleUpdate)
            {
                if (LOG_ALL_PUSHES)
                    NSLog(@"!shouldPushUpdate !self.isSendingPebbleUpdate %@", (!self.isSendingPebbleUpdate ? @"SENT" : @"BLOCKED"));
            }
            else
            {
                NSString *sessionOpenOrResetting;
                
                if (self.pebbleSessionOpen)
                    sessionOpenOrResetting = @"pebbleSessionOpen";
                else if (self.isManuallyResettingPebble)
                    sessionOpenOrResetting = @"isManuallyResettingPebble";
                else
                    sessionOpenOrResetting = @"pebbleSessionClosed && notManuallyResetingPebble";
                
                NSLog(@"!shouldPushUpdate !self.isSendingPebbleUpdate %@", (!self.isSendingPebbleUpdate ? @"PASS" : @"FAIL"));
                NSLog(@"!shouldPushUpdate !self.isResettingPebble %@", (!self.isResettingPebble ? @"PASS" : @"FAIL"));
                NSLog(@"!shouldPushUpdate (self.pebbleSessionOpen || self.isManuallyResettingPebble) %@ Reason: %@", ((self.pebbleSessionOpen || self.isManuallyResettingPebble) ? @"PASS" : @"FAIL"), sessionOpenOrResetting);
                NSLog(@"!shouldPushUpdate self.pebbleConnected %@", (self.pebbleConnected ? @"PASS" : @"FAIL"));
                NSLog(@"!shouldPushUpdate self.pebbleAppUUIDSet %@", (self.pebbleAppUUIDSet ? @"PASS" : @"FAIL"));
                NSLog(@"!shouldPushUpdate self.pebbleHardwareEnabled %@", (self.pebbleHardwareEnabled ? @"PASS" : @"FAIL"));
            }
        }
    }
}

#pragma mark - Kill Pebble App

-(void)killPebbleApp
{
    __weak __typeof__(self) weakSelf = self;
    
    dispatch_barrier_sync(queue, ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        
        strongSelf.isSendingPebbleUpdate = YES;
        strongSelf.shouldClosePebbleSession = YES;
    });
    
    if (self.useCustomPebbleApp)
    {
        if (self.appUpdateHandle)
        {
            [self.watch appMessagesRemoveUpdateHandler:self.appUpdateHandle];
            
            self.appUpdateHandle = nil;
        }
        
        [self.watch appMessagesKill:^(PBWatch *watch, NSError *error)
         {
             __strong __typeof__(self) strongSelf = weakSelf;
             
             if (!error)
             {
                 NSLog(@"killPebbleApp appMessagesKill OK");
                 
                 dispatch_barrier_sync(strongSelf->queue, ^{
                     strongSelf.pebbleConnected = NO;
                     strongSelf.isSendingPebbleUpdate = NO;
                 });
                 
                 strongSelf.shouldKillPebbleApp = NO;
                 
                 if (strongSelf.shouldClosePebbleSession)
                 {
                     [strongSelf.watch closeSession:^{
                         NSLog(@"killPebbleApp closeSession");
                         
                         strongSelf.shouldClosePebbleSession = NO;
                     }];
                 }
             }
             else
             {
                 // Do Nothing
                 
                 NSLog(@"killPebbleApp appMessagesKill Error: %@", error.debugDescription);
             }
         }];
    }
}

#pragma mark - Clean Up Pebble App

-(void)cleanUpPebbleApp
{
    if (self.appUpdateHandle)
    {
        [self.watch appMessagesRemoveUpdateHandler:self.appUpdateHandle];
        
        self.appUpdateHandle = nil;
    }
}

#pragma mark - App Dictionay Byte Calculation Methods

-(NSInteger)bytesForDictionary:(NSDictionary *)dictionary
{
    NSInteger bytes = 1;
    
    for (NSString *key in dictionary.allKeys)
    {
        bytes += 7;
        
        if ([[dictionary objectForKey:key] isKindOfClass:[NSString class]])
        {
            bytes += ((NSString *) dictionary[key]).length;
        }
        else if ([[dictionary objectForKey:key] isKindOfClass:[NSNumber class]])
        {
            bytes += ((NSNumber *) dictionary[key]).width;
        }
        else if ([[dictionary objectForKey:key] isKindOfClass:[NSData class]])
        {
            bytes += ((NSData *) dictionary[key]).length;
        }
    }
    
    return bytes;
}

#pragma mark - PEBBLE CENTRAL DELEGATE

-(void)pebbleCentral:(PBPebbleCentral *)central watchDidConnect:(PBWatch *)watch isNew:(BOOL)isNew
{
    NSLog(@"pebbleCentral watchDidConnect isNew: %@", (isNew? @"Yes" : @"No"));
    
    NSLog(@"pebbleCentral watchDidConnect lastConnectedWatch == watch %@ lastConnectedWatch isEqual:watch %@", (([PBPebbleCentral defaultCentral].lastConnectedWatch == watch)? @"Yes" : @"No"), (([[PBPebbleCentral defaultCentral].lastConnectedWatch isEqual:watch])? @"Yes" : @"No"));
    
    NSLog(@"pebbleCentral watchDidConnect hasValidAppUUID %@", (([PBPebbleCentral defaultCentral].hasValidAppUUID)? @"Yes" : @"No"));
    
    NSLog(@"pebbleCentral watchDidConnect appUUID == appUUID %@", (([PBPebbleCentral defaultCentral].appUUID == self.appUUID)? @"Yes" : @"No"));
    
    self.watch = watch;
    
    if (self.watch)
    {
        [self.watch setDelegate:self];
        
        if ([self.watch isConnected])
        {
            NSLog(@"pebbleCentral watchDidConnect [self.watch isConnected]");
            
            __weak __typeof__(self) weakSelf = self;
            
            if ([self.delegate getIsRunningStatus])
            {
                NSLog(@"pebbleCentral watchDidConnect [self.watch isConnected] self.delegate.isRunning");
                
                [[PBPebbleCentral defaultCentral] setAppUUID:self.appUUID];
                
                self.pebbleAppUUIDSet = YES;
                self.pebbleHardwareEnabled = YES;
                self.pebbleConnected = YES;
            }
            else
            {
                [self.watch closeSession:^{
                    __strong __typeof__(self) strongSelf = weakSelf;
                    
                    NSLog(@"pebbleCentral watchDidConnect closeSession");
                    
                    strongSelf.pebbleHardwareEnabled = YES;
                    
                    if (!isNew && !strongSelf.pebbleConnected && !strongSelf.isSendingPebbleUpdate)
                    {
                        [strongSelf connectPebbleDisplay];
                    }
                }];
            }
        }
        else
        {
            NSLog(@"pebbleCentral watchDidConnect ![self.watch isConnected]");
            
            self.pebbleHardwareEnabled = YES;
            
            if (!isNew && !self.pebbleConnected && !self.isSendingPebbleUpdate)
            {
                [self connectPebbleDisplay];
            }
        }
    }
}

-(void)pebbleCentral:(PBPebbleCentral *)central watchDidDisconnect:(PBWatch *)watch
{
    NSLog(@"pebbleCentral watchDidDisconnect");
    
    if (self.watch == watch || [self.watch isEqual:watch])
    {
        NSLog(@"pebbleCentral watchDidDisconnect self.watch == watch || [self.watch isEqual:watch]");
        
        if ([self.delegate getIsRunningStatus])
        {
            self.pebbleAppUUIDSet = YES;
            self.pebbleHardwareEnabled = YES;
            self.pebbleConnected = NO;
            self.isSendingPebbleUpdate = NO;
            
            self.watch = nil;
        }
        else
        {
            __weak __typeof__(self) weakSelf = self;
            
            [self.watch closeSession:^{
                __strong __typeof__(self) strongSelf = weakSelf;
                
                NSLog(@"pebbleCentral watchDidDisconnect closeSession");
                
                strongSelf.pebbleAppUUIDSet = YES;
                strongSelf.pebbleHardwareEnabled = YES;
                strongSelf.pebbleConnected = NO;
                strongSelf.isSendingPebbleUpdate = NO;
                
                strongSelf.watch = nil;
            }];
        }
    }
}

#pragma mark - PEBBLE WATCH DELEGATE

-(void)watch:(PBWatch *)watch handleError:(NSError *)error
{
    NSLog(@"watch handleError");
    
    // Do Nothing
}

-(void)watchDidCloseSession:(PBWatch *)watch
{
    NSLog(@"watch watchDidCloseSession");
    
    __weak __typeof__(self) weakSelf = self;
    
    dispatch_barrier_sync(queue, ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        
        strongSelf.pebbleSessionOpen = NO;
    });
}

-(void)watchDidDisconnect:(PBWatch *)watch
{
    NSLog(@"watch watchDidDisconnect");
    
    // Do Nothing
}

-(void)watchDidOpenSession:(PBWatch *)watch
{
    NSLog(@"watch watchDidOpenSession");
    
    __weak __typeof__(self) weakSelf = self;
    
    dispatch_barrier_sync(queue, ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf.errorCount > 0)
            strongSelf.errorRecoveries++;
        
        strongSelf.isManuallyResettingPebble = NO;
        strongSelf.pebbleSessionOpen = YES;
        strongSelf.isResettingPebble = NO;
        strongSelf.isReconnecting = NO;
        strongSelf.errorCount = 0;
    });
    
    if (self.queuedPebbleMessageUpdate.count > 0 || self.shouldKillPebbleApp)
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong __typeof__(self) strongSelf = weakSelf;
            
            [strongSelf pushPebbleUpdate];
        });
}

-(void)watchWillResetSession:(PBWatch *)watch
{
    NSLog(@"watch watchWillResetSession");
    
    __weak __typeof__(self) weakSelf = self;
    
    dispatch_barrier_sync(queue, ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        
        strongSelf.isResettingPebble = YES;
    });
}

@end
