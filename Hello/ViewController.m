//
//  ViewController.m
//  Hello
//
//  Created by James Mattis on 3/14/14.
//  Copyright (c) 2014 World Champ Tech. All rights reserved.
//

#import "ViewController.h"
#import <mach/mach.h>

// For Max Rate Testing, RandomAverage = 0.05 & RandomRange = 0.00
// For Real World Testing, RandomAverage = 0.9 & RandomRange = 0.2;

#define RANDOM_AVERAGE 0.9
#define RANDOM_RANGE 0.2

// Color Defines

#define BLUE 0
#define GREEN 1
#define YELLOW 2
#define ORANGE 3
#define RED 4
#define BROWN 5

@interface ViewController ()
{
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

#pragma mark - PEBBLE TEST METHOD

-(void)pebbleTest
{
    if (self->pebbleTestRunning)
    {
        endTime = mach_absolute_time();
        
        [PebbleController pebble].runTime += (((double)endTime - (double)startTime) * timebaseConversionFactor) / NSEC_PER_SEC;
        
        startTime = mach_absolute_time();
        
        // Get Random Title to Send to Watch
        
        NSString *labelString;
        
        switch (self->pebbleTextCount) {
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

        if ([PebbleController pebble].useCustomPebbleApp)
        {
            // Create Dictionary
            
            NSDictionary *dictionary = @{@(CustomAppMessageKey) : labelString};
            
            // Add Queue Dictionary To Queue

            if (![[PebbleController pebble] addDictionaryToQueue:dictionary])
                NSLog(@"[[PebbleController pebble] addDictionaryToQueue FAILURE: %ld", (long)[[PebbleController pebble] bytesForDictionary:dictionary]);

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
    
    if ([PebbleController pebble].useCustomPebbleApp)
    {
        if (!self.isRunning)
        {
            [[PebbleController pebble] resetStats];
            
            NSLog(@"buttonPress: %@ !self.isRunning", button.currentTitle);
            
            self.isRunning = YES;
            
            // Reset Time
            
            [PebbleController pebble].runTime = 0.0;
            startTime = mach_absolute_time();
            endTime = mach_absolute_time();
            
            // Create Dictionary
            
            NSDictionary *dictionary = @{@(CustomAppMessageKey) : labelString};
            
            // Add Queue Dictionary To Queue
            
            if (![[PebbleController pebble] addDictionaryToQueue:dictionary])
                NSLog(@"[[PebbleController pebble] addDictionaryToQueue FAILURE: %ld", (long)[[PebbleController pebble] bytesForDictionary:dictionary]);
            
            __weak __typeof__(self) weakSelf = self;

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
            
            [[PebbleController pebble] logStats];
        }
    }
}

#pragma mark - SWITCH TOGGLE IBACTION

-(IBAction)switchToggle:(UISwitch *)theSwitch
{
    if (theSwitch == self.queueSwitch)
    {
        [PebbleController pebble].useQueue = self.queueSwitch.on;
    }
    else if (theSwitch == self.maxDataSwitch)
    {
        [PebbleController pebble].useMaxData = self.maxDataSwitch.on;
    }
    else if (theSwitch == self.reducedSniffSwitch)
    {
        [PebbleController pebble].useReducedSniff = self.reducedSniffSwitch.on;
        
        // Create Dictionary
        
        NSDictionary *dictionary = @{@(CustomAppSniffKey) : [NSNumber numberWithUint8:self.reducedSniffSwitch.on]};
        
        // Add Queue Dictionary To Queue
        
        if (![[PebbleController pebble] addDictionaryToQueue:dictionary])
            NSLog(@"[[PebbleController pebble] addDictionaryToQueue FAILURE: %ld", (long)[[PebbleController pebble] bytesForDictionary:dictionary]);
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
        [[PebbleController pebble] killPebbleApp];
}

-(void)applicationWillEnterForeground:(NSNotification *)notification
{
    // Relaunch Pebble App
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
    // Remove appMessageUpdateHanlder
    
    if ([PebbleController pebble].useCustomPebbleApp)
    {
        [[PebbleController pebble] cleanUpPebbleApp];
    }
}

#pragma mark - View Did Load - App Setup

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Start PebbleController
    
    [[PebbleController pebble] setDelegate:self];
    [[PebbleController pebble] enablePebbleHardware];
    
    // Register for Notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    
    // Switch Setup
    
    [self.maxDataSwitch setOn:YES];
    [self.queueSwitch setOn:YES];
    [self.reducedSniffSwitch setOn:NO];
    
    // Language Button Outlets - Set Buttons to Inactive
    
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
    
    // Test Running Property
    
    self.isRunning = NO;
    
    // Setup Timebase Info
    
    mach_timebase_info(&timebaseInfo);
    
    timebaseConversionFactor = (double)timebaseInfo.numer / (double)timebaseInfo.denom;
}

-(void)viewWillAppear:(BOOL)animated
{
    // Super View Will Appear
    
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Successful Pebble App Launch Method - Post Launch Clean Up

-(void)pebbleLaunchSuccess
{
    NSLog(@"pebbleLaunchSuccess");
    
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

#pragma mark - Pebble Messaging Delegate Methods

-(void)appUpdateReceived:(NSDictionary *)message
{
    __weak __typeof__(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        __strong __typeof__(self) strongSelf = weakSelf;
        
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
}

-(void)appLifecycleUpdateReceived:(PBAppState)state
{
    // DO NOTHING
}

-(void)appMessagePushCallBackReceived:(NSError *)error
{
    if (error)
    {
        
        __weak __typeof__(self) weakSelf = self;
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong __typeof__(self) strongSelf = weakSelf;

            [strongSelf.view setBackgroundColor:[UIColor orangeColor]];
        });

        if (error.code == 10 || error.code == 9)
        {
            if (![PebbleController pebble].isResettingPebble)
            {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    __strong __typeof__(self) strongSelf = weakSelf;
                    
                    if (strongSelf.color != RED)
                    {
                        strongSelf.color = RED;
                        [strongSelf.view setBackgroundColor:[UIColor redColor]];
                    }
                });
            }
        }
    }
    else
    {
        __weak __typeof__(self) weakSelf = self;
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong __typeof__(self) strongSelf = weakSelf;
            
            if (strongSelf.color != BLUE)
            {
                strongSelf.color = BLUE;
                [strongSelf.view setBackgroundColor:[UIColor colorWithRed:0.0 green:0.4785 blue:1.0 alpha:1.0]];
            }
        });
    }
}

-(void)watchWillReset
{
    __weak __typeof__(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        __strong __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf.color != YELLOW)
        {
            strongSelf.color = YELLOW;
            [strongSelf.view setBackgroundColor:[UIColor yellowColor]];
        }
    });
}

-(BOOL)getIsRunningStatus
{
    return self.isRunning;
}

@end
