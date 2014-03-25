//
//  ViewController.m
//  Hello
//
//  Created by James Mattis on 3/14/14.
//  Copyright (c) 2014 World Champ Tech. All rights reserved.
//

#import "ViewController.h"
#import <mach/mach.h>

// Log All Pushes

#define LOG_ALL_PUSHES NO

// For Max Rate Testing, RandomAverage = 0.1 & RandomRange = 0.1
// For Real World Testing, RandomAverage = 0.9 & RandomRange = 0.2;

#define RANDOM_AVERAGE 0.1
#define RANDOM_RANGE 0.1

// Color Defines

#define BLUE 0
#define GREEN 1
#define YELLOW 2
#define ORANGE 3
#define RED 4
#define BROWN 5

#pragma mark - PEBBLE ENUMS

enum PebbleData
{
    CustomAppMessageKey = 0,
    CustomAppDataKey = 1,
    CustomAppSniffKey = 2
};

#pragma mark - PEBBLE WATCH APP UUID

// Hint: Copy this from appinfo.auto.c file in Watch App build folder after building watch app

uint8_t pebbleAppUUID[] = {0xE7, 0xA7, 0x49, 0x80, 0xDC, 0x0B, 0x41, 0x5D, 0xA9, 0x8B, 0x28, 0x5E, 0x7A, 0x6C, 0xA6, 0x92};

@interface ViewController ()
{
    // External Display Controller Concurrent Dispatch Queue
    
    dispatch_queue_t queue;
    
    int pebbleTextCount;
    
    BOOL pebbleTestRunning;
    
    // Elapsed Time Variables
    
    uint64_t startTime;
    uint64_t endTime;
    
    mach_timebase_info_data_t timebaseInfo;
    
    double timebaseConversionFactor;
}
@end

@implementation ViewController

#pragma mark - LOG STATS METHOD

-(void)logStats
{
    int seconds = (int) self.runTime % 60;
    int minutes = (int) (self.runTime / 60) % 60;
    int hours = (int) (self.runTime / 3600.0);
    
    NSLog(@"Run Time: %02d:%02d:%02d", hours, minutes, seconds);
    NSLog(@"Message Pushes: %ld Successful: %ld (%1.2f %%)", (long)self.pushes, (long)self.successfulPushes, 100.0 * ((float) self.successfulPushes) / ((float) self.pushes));
    NSLog(@"PushedBytes: %1.1f MB %1.1f kB %1.3f kB/s", ((float)self.pushedBytes / 1000000.0), ((float)self.pushedBytes / 1000.0), ((float)self.pushedBytes / 1000.0) / self.runTime);
    NSLog(@"Receieved Messages: %ld", (long)self.receivedMessages);
    NSLog(@"Blocked Pushes: %ld (%1.2f %%)", (long)self.blockedPushes, 100.0 * ((float) self.blockedPushes) / ((float) self.pushes));
    NSLog(@"BlockedBytes: %1.1f MB %1.1f kB %1.3f kB/s", ((float)self.blockedBytes / 1000000.0), ((float)self.blockedBytes / 1000.0), ((float)self.blockedBytes / 1000.0) / self.runTime);
    
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

#pragma mark - PEBBLE TEST METHOD

-(void)pebbleTest
{
    if (pebbleTestRunning)
    {
        endTime = mach_absolute_time();
        
        self.runTime += (((double)endTime - (double)startTime) * timebaseConversionFactor) / NSEC_PER_SEC;
        
        startTime = mach_absolute_time();
        
        // Get Random Title to Send to Watch
        
        NSString *labelString;
        
        switch (pebbleTextCount) {
            case 0:
                labelString = @"hello";
                break;
            case 1:
                labelString = @"hallo";
                break;
            case 2:
                labelString = @"hola";
                break;
            case 3:
                labelString = @"hej";
                break;
            case 4:
                labelString = @"bonjour";
                break;
            case 5:
                labelString = @"ciao";
                break;
            case 6:
                labelString = @"salve";
                break;
            case 7:
                labelString = @"ola";
                break;
            case 8:
                labelString = @"chaoa";
                break;
            case 9:
                labelString = @"kaixo";
                break;
            default:
                break;
        }
        
        self->pebbleTextCount++;
        
        if (self->pebbleTextCount > 9)
            self->pebbleTextCount = 0;
        
        __weak __typeof__(self) weakSelf = self;

        if (self.useCustomPebbleApp)
        {
            // Update Queued Dictionary
            
            dispatch_barrier_sync(queue, ^{
                __strong __typeof__(self) strongSelf = weakSelf;
                
                if ((strongSelf.queuedPebbleMessageUpdate)[@(CustomAppDataKey)])
                {
                    [strongSelf.queuedPebbleMessageUpdate removeObjectForKey:@(CustomAppDataKey)];
                }

                (strongSelf.queuedPebbleMessageUpdate)[@(CustomAppMessageKey)] = labelString;
                
                NSInteger dataLength = (123 - 7) - [self bytesForDictionary:strongSelf.queuedPebbleMessageUpdate];
                
                if (strongSelf.useMaxData)
                {
                    (strongSelf.queuedPebbleMessageUpdate)[@(CustomAppDataKey)] = [NSMutableData dataWithLength:dataLength];
                }
                
                if (LOG_ALL_PUSHES)
                    NSLog(@"pebbleTest bytesForDictionary: %ld", (long)[strongSelf bytesForDictionary:strongSelf.queuedPebbleMessageUpdate]);
            });
            
            // Get Latest Dictionary
            
            __block NSDictionary *dictionary;
            
            dispatch_sync(queue, ^{
                __strong __typeof__(self) strongSelf = weakSelf;
                
                dictionary = [[NSDictionary alloc] initWithDictionary:strongSelf.queuedPebbleMessageUpdate];
            });
            
            // Add Queue Dictionary To Queue

            [self addDictionaryToQueue:dictionary];
            
            // Push Update
            
            if (self.queuedPebbleMessageUpdate.count > 0 || self.shouldKillPebbleApp)
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    __strong __typeof__(self) strongSelf = weakSelf;

                    [strongSelf pushPebbleUpdate];
                });
        }
        
        // Start Loop again if running
        
        double randomAverage = RANDOM_AVERAGE;
        double randomRange = RANDOM_RANGE;
        
        if (self.isRunning)
        {
            double randomDelay = ((double)arc4random() / 0x100000000) * randomRange + randomAverage;
            
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, randomDelay * NSEC_PER_SEC);
            
            // Start the long running task and return immediately.
            
            dispatch_after(delay, dispatch_get_main_queue(), ^{
                __strong __typeof__(self) strongSelf = weakSelf;
                
                [strongSelf pebbleTest];
            });
        }
    }
}

#pragma mark - BUTTON PRESS IBACTION METHOD

-(IBAction)buttonPress:(UIButton *)button
{
    NSLog(@"buttonPress: %@", button.currentTitle);
    
    NSString *labelString = button.currentTitle;
    
    if (self.useCustomPebbleApp)
    {
        if (!self.isRunning)
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
            self.blockedPushes = 0;
            self.failedBytes = 0;
            self.timeoutCycles = 0;
            
            NSLog(@"buttonPress: %@ !self.isRunning", button.currentTitle);
            
            self.isRunning = YES;
            
            // Reset Time
            
            startTime = mach_absolute_time();
            endTime = mach_absolute_time();
            
            __weak __typeof__(self) weakSelf = self;
            
            dispatch_barrier_async(queue, ^{
                
                __strong __typeof__(self) strongSelf = weakSelf;
                
                (strongSelf.queuedPebbleMessageUpdate)[@(CustomAppMessageKey)] = labelString;
                
                if (strongSelf.queuedPebbleMessageUpdate.count > 0 || strongSelf.shouldKillPebbleApp)
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [strongSelf pushPebbleUpdate];
                    });
            });
            
            if (!self->pebbleTestRunning)
            {
                self->pebbleTestRunning = YES;
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    __strong __typeof__(self) strongSelf = weakSelf;
                    
                    [strongSelf pebbleTest];
                });
            }
            else
            {
                self->pebbleTestRunning = NO;
            }
        }
        else
        {
            NSLog(@"buttonPress: %@ self.isRunning", button.currentTitle);
            
            self.isRunning = NO;
            
            [self logStats];
        }
    }
}

#pragma mark - SWITCH TOGGLE IBACTION

-(IBAction)switchToggle:(UISwitch *)theSwitch
{
    if (theSwitch == self.queueSwitch)
    {
        self.useQueue = self.queueSwitch.on;
    }
    else if (theSwitch == self.maxDataSwitch)
    {
        self.useMaxData = self.maxDataSwitch.on;
    }
    else if (theSwitch == self.reducedSniffSwitch)
    {
        self.useReducedSniff = self.reducedSniffSwitch.on;
        
        __weak __typeof__(self) weakSelf = self;
        
        if (self.useCustomPebbleApp)
        {
            // Update Queued Dictionary
            
            dispatch_barrier_sync(queue, ^{
                __strong __typeof__(self) strongSelf = weakSelf;
                
                if ((strongSelf.queuedPebbleMessageUpdate)[@(CustomAppDataKey)])
                {
                    [strongSelf.queuedPebbleMessageUpdate removeObjectForKey:@(CustomAppDataKey)];
                }
                
                (strongSelf.queuedPebbleMessageUpdate)[@(CustomAppSniffKey)] = [NSNumber numberWithUint8:strongSelf.useReducedSniff];
                
                NSInteger dataLength = (123 - 7) - [self bytesForDictionary:strongSelf.queuedPebbleMessageUpdate];
                
                if (strongSelf.useMaxData)
                {
                    (strongSelf.queuedPebbleMessageUpdate)[@(CustomAppDataKey)] = [NSMutableData dataWithLength:dataLength];
                }
                
                if (LOG_ALL_PUSHES)
                    NSLog(@"pebbleTest bytesForDictionary: %ld", (long)[strongSelf bytesForDictionary:strongSelf.queuedPebbleMessageUpdate]);
            });
            
            // Get Latest Dictionary
            
            __block NSDictionary *dictionary;
            
            dispatch_sync(queue, ^{
                __strong __typeof__(self) strongSelf = weakSelf;
                
                dictionary = [[NSDictionary alloc] initWithDictionary:strongSelf.queuedPebbleMessageUpdate];
            });
            
            // Add Queue Dictionary To Queue
            
            [self addDictionaryToQueue:dictionary];
            
            // Push Update
            
            if (self.queuedPebbleMessageUpdate.count > 0 || self.shouldKillPebbleApp)
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    __strong __typeof__(self) strongSelf = weakSelf;
                    
                    [strongSelf pushPebbleUpdate];
                });
        }
    }
}


#pragma mark - Application Notifications

-(void)applicationDidBecomeActive:(NSNotification *)notification
{
    // Do Nothing
}

-(void)applicationWillResignActive:(NSNotification *)notification
{
    // Do Nothing
}

-(void)applicationDidEnterBackground:(NSNotification *)notification
{
    // If not running, kill pebble app.
    
    if (!self.isRunning)
        [self killPebbleApp];
}

-(void)applicationWillEnterForeground:(NSNotification *)notification
{
    // Relaunch Pebble App
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
    // Remove appMessageUpdateHanlder
    
    if (self.useCustomPebbleApp)
    {
        if (self.appUpdateHandle)
        {
            [self.watch appMessagesRemoveUpdateHandler:self.appUpdateHandle];
            
            self.appUpdateHandle = nil;
        }
    }
}

#pragma mark - View Did Load - App Setup

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Register for Notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    
    // Setup Timebase Info
    
    mach_timebase_info(&timebaseInfo);
    
    timebaseConversionFactor = (double)timebaseInfo.numer / (double)timebaseInfo.denom;

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
    self.blockedPushes = 0;
    self.failedBytes = 0;
    self.timeoutCycles = 0;
    
    // State BOOLs
    
    self.useQueue = YES;
    self.useMaxData = YES;
    self.useReducedSniff = NO;
    
    // Switch Setup
    
    [self.maxDataSwitch setOn:YES];
    [self.queueSwitch setOn:YES];
    [self.reducedSniffSwitch setOn:NO];

    // Pebble Test Variables
    
    self->pebbleTextCount = 0;
    self->pebbleTestRunning = NO;
    
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
    self.isRunning = NO;
    self.isReconnecting = NO;
    self.isManuallyResettingPebble = NO;
    
    // Error Count
    
    self.errorCount = 0;
    
    // Setup Pebble App UUID
    
    self.appUUID = [NSData dataWithBytes:pebbleAppUUID length:sizeof(pebbleAppUUID)];
    
    // Set Buttons to Inactive
    
    // Language Button Outlets
    
    [self.englishButton setEnabled:NO];
    [self.dutchButton setEnabled:NO];
    [self.spanishButton setEnabled:NO];
    [self.danishButton setEnabled:NO];
    [self.frenchButton setEnabled:NO];
    [self.italianButton setEnabled:NO];
    [self.latinButton setEnabled:NO];
    [self.portugueseButton setEnabled:NO];
    [self.vietnameseButton setEnabled:NO];
    [self.basqueButton setEnabled:NO];
    
    // Set Color
    
    self.color = BLUE;
    [self.view setBackgroundColor:[UIColor colorWithRed:0.0 green:0.4785 blue:1.0 alpha:1.0]];
    
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

-(void)viewWillAppear:(BOOL)animated
{
    // Pebble API Test
    
    // Setup Pebble Watch App
    
    [self enablePebbleHardware];
    
    // Super View Will Appear
    
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Successful Pebble App Launch Method - Post Launch Clean Up

-(void)appLaunchSuccess
{
    NSLog(@"appLaunchSuccess");
    
    // Enable Language Button Outlets
    
    [self.englishButton setEnabled:YES];
    [self.dutchButton setEnabled:YES];
    [self.spanishButton setEnabled:YES];
    [self.danishButton setEnabled:YES];
    [self.frenchButton setEnabled:YES];
    [self.italianButton setEnabled:YES];
    [self.latinButton setEnabled:YES];
    [self.portugueseButton setEnabled:YES];
    [self.vietnameseButton setEnabled:YES];
    [self.basqueButton setEnabled:YES];
}

#pragma mark - Pebble Watch Methods

-(void)enablePebbleHardware
{
    NSLog(@"enablePebbleHardware");
    
    [PBPebbleCentral setDebugLogsEnabled:YES];
    
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
    
    __weak __typeof__(self) weakSelf = self;
    
    self.appUpdateHandle = [self.watch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update){
        
        __strong __typeof__(self) strongSelf = weakSelf;
        
        strongSelf.receivedMessages++;
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (strongSelf.color == BLUE)
            {
                strongSelf.color = GREEN;
                [strongSelf.view setBackgroundColor:[UIColor greenColor]];
                
                dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC);
                
                // Start the long running task and return immediately.
                
                dispatch_after(delay, dispatch_get_main_queue(), ^{
                    if (strongSelf.color == GREEN)
                    {
                        strongSelf.color = BLUE;
                        [strongSelf.view setBackgroundColor:[UIColor colorWithRed:0.0 green:0.4785 blue:1.0 alpha:1.0]];
                    }
                });
            }
            else
            {
                strongSelf.color = BROWN;
                [strongSelf.view setBackgroundColor:[UIColor brownColor]];
            }
        });
        
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
        
        NSLog(@"appMessageLifecycleHandler");
        
        if (newAppState == PBAppStateNotRunning)
        {
            NSLog(@"appMessageLifecycleHandler PBAppStateNotRunning");
            
            [strongSelf connectPebbleDisplay];
        }
        else
        {
            NSLog(@"appMessageLifecycleHandler PBAppStateRunning");
            
            [strongSelf appLaunchSuccess];
        }
    }];
}

#pragma mark - Reconnect Pebble Display Method

-(void)reconnectPebbleDisplay
{
    NSLog(@"reconnectPebbleDisplay");
    
    if (self.pebbleHardwareEnabled)
    {
        // If Reconnecting, Open Session
        
        self.isReconnecting = YES;
        
        if (self.isReconnecting)
        {
            [[PBPebbleCentral defaultCentral] setDelegate:self];
            
            if ([PBPebbleCentral defaultCentral].connectedWatches.count > 0)
            {
                self.watch = [PBPebbleCentral defaultCentral].lastConnectedWatch;
                
                if (self.watch.delegate != self)
                    [self.watch setDelegate:self];
                
                [[PBPebbleCentral defaultCentral] setAppUUID:self.appUUID];
                
                if ([[PBPebbleCentral defaultCentral] hasValidAppUUID])
                {
                    // Do Nothing
                    
                    NSLog(@"watch reconnectPebbleDisplay hasValidAppUUID");
                    
                    self.pebbleAppUUIDSet = YES;
                    self.isSendingPebbleUpdate = NO;
                }
            }
        }
    }
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
                              
                              [strongSelf appLaunchSuccess];
                          }
                          else
                          {
                              // Do Nothing Once New SDK Released
                              
                              dispatch_barrier_sync(strongSelf->queue, ^{
                                  strongSelf.pebbleConnected = YES;
                                  strongSelf.isSendingPebbleUpdate = NO;
                              });
                              
                              [strongSelf installHandlers];
                              
                              [strongSelf appLaunchSuccess];
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
                              
                              [strongSelf appLaunchSuccess];
                          }
                          else
                          {
                              // Do Nothing Once New SDK Released
                              
                              dispatch_barrier_sync(strongSelf->queue, ^{
                                  strongSelf.pebbleConnected = YES;
                                  strongSelf.isSendingPebbleUpdate = NO;
                              });
                              
                              [strongSelf installHandlers];
                              
                              [strongSelf appLaunchSuccess];
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
    
    dispatch_barrier_sync(queue, ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        
        [strongSelf.pebbleMessageUpdateQueue enqueue:dictionary];
    });
}

#pragma mark - Pebble Push Update Method

-(void)pushPebbleUpdate
{
    if (LOG_ALL_PUSHES)
        NSLog(@"pushPebbleUpdate");
    
    self.pushes++;
    
    // For Max Rate Testing, Update Stats Every 1000 pushes (approximately 3-5 minutes)
    
    if (fmodf(((float) self.pushes), 1000.0) == 0.0)
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
                         
                         if (error)
                         {
                             strongSelf.totalErrors++;
                             
                             strongSelf.pushFails++;
                             strongSelf.failedBytes += [strongSelf bytesForDictionary:update];
                             
                             NSLog(@"pushPebbleUpdate appMessagesPushUpdate errorCount: %ld error: %@", (long)strongSelf.errorCount, error.debugDescription);
                             
                             dispatch_async(dispatch_get_main_queue(), ^(void) {
                                 [strongSelf.view setBackgroundColor:[UIColor orangeColor]];
                             });
                             
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
                                     
                                     if (!weakSelf.isResettingPebble)
                                         dispatch_async(dispatch_get_main_queue(), ^(void) {
                                             if (strongSelf.color != RED)
                                             {
                                                 strongSelf.color = RED;
                                                 [strongSelf.view setBackgroundColor:[UIColor redColor]];
                                             }
                                             
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
                                             if (strongSelf.color != RED)
                                             {
                                                 strongSelf.color = RED;
                                                 [strongSelf.view setBackgroundColor:[UIColor redColor]];
                                             }
                                             
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
                                         if (strongSelf.color != RED)
                                         {
                                             strongSelf.color = RED;
                                             [strongSelf.view setBackgroundColor:[UIColor redColor]];
                                         }
                                         
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
                             
                             dispatch_async(dispatch_get_main_queue(), ^(void) {
                                 
                                 if (strongSelf.color != BLUE)
                                 {
                                     strongSelf.color = BLUE;
                                     [strongSelf.view setBackgroundColor:[UIColor colorWithRed:0.0 green:0.4785 blue:1.0 alpha:1.0]];
                                 }
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
                
                updateDictionary = [NSDictionary dictionaryWithDictionary:strongSelf.queuedPebbleMessageUpdate];
            });
            
            self.blockedBytes = [self bytesForDictionary:updateDictionary];
            
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
                NSLog(@"!shouldPushUpdate self.isRunning %@", (self.isRunning ? @"PASS" : @"FAIL"));
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
            
            if (self.isRunning)
            {
                NSLog(@"pebbleCentral watchDidConnect [self.watch isConnected] self.isRunning");
                
                [[PBPebbleCentral defaultCentral] setAppUUID:self.appUUID];
                
                self.pebbleAppUUIDSet = YES;
                self.pebbleHardwareEnabled = YES;
                self.pebbleConnected = YES;
            }
            else
            {
                NSLog(@"pebbleCentral watchDidConnect [self.watch isConnected] !self.isRunning");
                
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
        
        if (self.isRunning)
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
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        __strong __typeof__(self) strongSelf = weakSelf;

        if (strongSelf.color != YELLOW)
        {
            strongSelf.color = YELLOW;
            [strongSelf.view setBackgroundColor:[UIColor yellowColor]];
        }
    });
    
    dispatch_barrier_sync(queue, ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        
        strongSelf.isResettingPebble = YES;
    });
}

@end
