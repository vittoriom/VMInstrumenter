//
//  VMInstrumenter_Tests.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <OCMock/OCMock.h>
#import <Expecta/Expecta.h>
#import "VMInstrumenter.h"
#import "VMTestsHelper.h"

@interface VMInstrumenter_Tests : SenTestCase {
    VMInstrumenter *_instrumenter;
}

@end

@implementation VMInstrumenter_Tests

- (void)setUp
{
    [super setUp];
    
    _instrumenter = [VMInstrumenter sharedInstance];
}

- (void)testSuppressMethodOnce
{
    VMTestsHelper *helper = [VMTestsHelper new];
    VMTestsHelper *check = [VMTestsHelper new];
    
    helper.forwardCalls = check;
    
    id testsMock = [OCMockObject partialMockForObject:check];
    
    [_instrumenter suppressSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
    
    [[testsMock reject] dontCallMe];
    
    [helper canSafelyCallMe];
    
    [testsMock verify];
}

- (void)testSuppressMethodTwice
{
    [_instrumenter suppressSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
    
    EXP_expect(^{
        [_instrumenter suppressSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
    }).toNot.raiseAny();
}

- (void)testRestoreSelector
{
    VMTestsHelper *helper = [VMTestsHelper new];
    VMTestsHelper *check = [VMTestsHelper new];
    
    helper.forwardCalls = check;
    
    id testsMock = [OCMockObject partialMockForObject:check];
    
    [_instrumenter suppressSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
    
    [[testsMock expect] dontCallMe];
    
    [_instrumenter restoreSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
    
    [helper canSafelyCallMe];
    
    [testsMock verify];
}

- (void)testRestoreSelectorTwice
{
    [_instrumenter suppressSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
    
    [_instrumenter restoreSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
    
    EXP_expect(^{
        [_instrumenter restoreSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
    }).toNot.raiseAny();
}

- (void)testRestoreNotSuppressedMethod
{
    EXP_expect(^{
        [_instrumenter restoreSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
    }).toNot.raiseAny();
}

- (void)testReplaceMethods
{
    VMTestsHelper *helper = [VMTestsHelper new];
    VMTestsHelper *helper2 = [VMTestsHelper new];
    
    helper.forwardCalls = helper2;
    
    [_instrumenter replaceSelector:@selector(dontCallMe) ofClass:[VMTestsHelper class] withSelector:@selector(ifReplacedCalled) ofClass:[VMTestsHelper class]];
    
    id testsMock = [OCMockObject partialMockForObject:helper2];
    
    [[testsMock expect] canSafelyCallMe];
    
    [helper dontCallMe];
    
    [testsMock verify];
}

@end
