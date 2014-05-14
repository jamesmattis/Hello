//
//  ViewController.h
//  Hello
//
//  Created by James Mattis on 3/14/14.
//  Copyright (c) 2014 World Champ Tech. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PebbleControllerDelegate;

@interface ViewController : UIViewController <PebbleControllerDelegate>

#pragma mark - Test Properties

// Display Color

@property (nonatomic, assign) NSInteger color;

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

// Test Running Property

@property (assign, nonatomic) BOOL isRunning;

#pragma mark - Test Methods

// Pebble Test Method

-(void)pebbleTest;

// Button Press Action

-(IBAction)buttonPress:(UIButton *)button;

// Switch Toggle Action

-(IBAction)switchToggle:(UISwitch *)theSwitch;

// Application Notifications

-(void)applicationDidBecomeActive:(NSNotification *)notification;
-(void)applicationWillResignActive:(NSNotification *)notification;
-(void)applicationDidEnterBackground:(NSNotification *)notification;
-(void)applicationWillEnterForeground:(NSNotification *)notification;
-(void)applicationWillTerminate:(NSNotification *)notification;

@end
