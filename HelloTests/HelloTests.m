//
//  HelloTests.m
//  HelloTests
//
//  Created by James Mattis on 3/25/14.
//  Copyright (c) 2014 World Champ Tech. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ViewController.h"

@interface HelloTests : XCTestCase

@property (nonatomic, strong) ViewController *viewController;

@end

@implementation HelloTests

- (void)setUp
{
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    self.viewController = [storyboard instantiateInitialViewController];

    [self.viewController loadView];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testOutlets
{
    XCTAssertNotNil(self.viewController.englishButton, @"englishButton IBOutlet NOT Connected");
    XCTAssertNotNil(self.viewController.dutchButton, @"dutchButton IBOutlet NOT Connected");
    XCTAssertNotNil(self.viewController.spanishButton, @"spanishButton IBOutlet NOT Connected");
    XCTAssertNotNil(self.viewController.danishButton, @"danishButton IBOutlet NOT Connected");
    XCTAssertNotNil(self.viewController.frenchButton, @"frenchButton IBOutlet NOT Connected");
    XCTAssertNotNil(self.viewController.italianButton, @"italianButton IBOutlet NOT Connected");
    XCTAssertNotNil(self.viewController.latinButton, @"latinButton IBOutlet NOT Connected");
    XCTAssertNotNil(self.viewController.portugueseButton, @"portugueseButton IBOutlet NOT Connected");
    XCTAssertNotNil(self.viewController.vietnameseButton, @"vietnameseButton IBOutlet NOT Connected");
    XCTAssertNotNil(self.viewController.basqueButton, @"basqueButton IBOutlet NOT Connected");
}

@end
