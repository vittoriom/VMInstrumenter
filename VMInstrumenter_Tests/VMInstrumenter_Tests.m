//
//  VMInstrumenter_Tests.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <XCTest/XCTest.h>
#import "VMDInstrumenter.h"
#import "VMDHelper.h"
#import "VMTestsHelper.h"
#import "NSMethodSignature+VMDInstrumenter.h"
#import "NSInvocation+VMDInstrumenter.h"

SPEC_BEGIN(VMDInstrumenterTests)
    __block VMDInstrumenter *_instrumenter;

    describe(@"VMDInstrumenter", ^{
        beforeEach(^{
            _instrumenter = [VMDInstrumenter sharedInstance];
        });
    
        context(@"when suppressing a method", ^{
            __block VMTestsHelper *helper;
            __block VMTestsHelper *check;
            
            beforeEach(^{
                helper = [VMTestsHelper new];
                check = [VMTestsHelper new];
                
                helper.forwardCalls = check;
            });
            
            it(@"should suppress method once", ^{
                [_instrumenter suppressSelector:@selector(canSafelyCallMe) forClass:[VMTestsHelper class]];
                [[check shouldNot] receive:@selector(dontCallMe)];
                
                [helper canSafelyCallMe];
            });
            
            it(@"suppressing a method twice should not raise an exception", ^{
                [_instrumenter suppressSelector:@selector(canSafelyCallMe) forClass:[VMTestsHelper class]];
                
                [[theBlock(^{
                    [_instrumenter suppressSelector:@selector(canSafelyCallMe) forClass:[VMTestsHelper class]];
                }) shouldNot] raise];
            });
            
            it(@"should restore suppressed selectors", ^{
                [[check should] receive:@selector(dontCallMe)];
                
                [_instrumenter restoreSelector:@selector(canSafelyCallMe) forClass:[VMTestsHelper class]];
                
                [helper canSafelyCallMe];
            });
            
            it(@"should not restore a selector twice", ^{
                [_instrumenter suppressSelector:@selector(canSafelyCallMe) forClass:[VMTestsHelper class]];
                [_instrumenter restoreSelector:@selector(canSafelyCallMe) forClass:[VMTestsHelper class]];
                
                [[theBlock(^{
                    [_instrumenter restoreSelector:@selector(canSafelyCallMe) forClass:[VMTestsHelper class]];
                }) should] raise];
            });
            
            it(@"should suppress class methods", ^{
                [_instrumenter suppressSelector:@selector(classMethodToSuppress) forClass:[VMTestsHelper class]];
                [[[VMTestsHelper class] shouldNot] receive:@selector(classMethodReturnsObject)];
                
                [VMTestsHelper classMethodToSuppress];
            });
            
            it(@"should raise an exception if the selector does not exist in the class", ^{
                [[theBlock(^{
                    [_instrumenter suppressSelector:@selector(doubleTest) forClass:[self class]];
                }) should] raise];
            });
        });
        
        context(@"when in stable state", ^{
            it(@"should not restore methods not suppressed", ^{
                [[theBlock(^{
                    [_instrumenter restoreSelector:@selector(canSafelyCallMe) forClass:[VMTestsHelper class]];
                }) should] raise];
            });
        });
        
        context(@"when replacing method implementations", ^{
            __block VMTestsHelper *helper;
            __block VMTestsHelper *helper2;
            
            beforeEach(^{
                helper = [VMTestsHelper new];
                helper2 = [VMTestsHelper new];
            
                helper.forwardCalls = helper2;
            });
            
            it(@"should replace implementations once", ^{
                [_instrumenter replaceSelector:@selector(dontCallMe) ofClass:[VMTestsHelper class] withSelector:@selector(ifReplacedCalled) ofClass:[VMTestsHelper class]];
                
                [[helper2 should] receive:@selector(canSafelyCallMe)];
                
                [helper dontCallMe];
            });
            
            it(@"should raise an exception if the selector does not exist in the class", ^{
                [[theBlock(^{
                    [_instrumenter replaceSelector:@selector(doubleTest) ofClass:[self class] withSelector:@selector(doSomethingNewWithThisString:) ofClass:[VMTestsHelper class]];
                }) should] raise];
            });
            
            it(@"should restore the original implementation if called twice", ^{
                [_instrumenter replaceSelector:@selector(dontCallMe) ofClass:[VMTestsHelper class] withSelector:@selector(ifReplacedCalled) ofClass:[VMTestsHelper class]];
                
                [[helper2 shouldNot] receive:@selector(canSafelyCallMe)];
                
                [helper dontCallMe];
            });
        });
        
        context(@"when instrumenting selectors", ^{
            __block VMTestsHelper *helper;
            
            //@TODO: add here all kind of tests
            
            //@TODO: add tests for new API
            
            beforeEach(^{
                helper = [VMTestsHelper new];
            });
            
            afterEach(^{
                helper = nil;
            });
            
            it(@"should not instrument a selector twice", ^{
                [_instrumenter traceSelector:@selector(dontCallMe) forClass:[VMTestsHelper class]];
                
                [[theBlock(^{
                    [_instrumenter traceSelector:@selector(dontCallMe) forClass:[VMTestsHelper class]];
                }) should] raise];
            });
            
            it(@"should not impact return values for methods that don't take parameters", ^{
                [_instrumenter traceSelector:@selector(alwaysReturnTest) forClass:[VMTestsHelper class]];
                
                [[[helper alwaysReturnTest] should] equal:@"Test"];
            });
            
            it(@"should not impact primitive return values for methods that don't take parameters", ^{
                [_instrumenter traceSelector:@selector(alwaysReturn3) forClass:[VMTestsHelper class]];
                [[theValue([helper alwaysReturn3]) should] equal:@3];
            });
            
            it(@"should not impact return values for methods that take one parameter", ^{
                [_instrumenter traceSelector:@selector(doAndReturnValue:) forClass:[VMTestsHelper class]];
                
                NSString *returnValue = [helper doAndReturnValue:@"Test"];
                [[returnValue should] equal:@"Test"];
            });
            
            it(@"should instrument selectors that return primitive values", ^{
                [_instrumenter traceSelector:@selector(doAndReturnPrimitiveValue:) forClass:[VMTestsHelper class]];
                
                NSInteger returnValue = [helper doAndReturnPrimitiveValue:3];
                [[theValue(returnValue) should] equal:theValue(3)];
            });
            
            it(@"should instrument selectors that take more than one parameter", ^{
                [_instrumenter traceSelector:@selector(doFoo:withMoreThanOneParameter:) forClass:[VMTestsHelper class]];
            
                VMTestsHelper *helper2 = [VMTestsHelper new];
                [[helper2 should] receive:@selector(dontCallMe)];
                helper.forwardCalls = helper2;
                
                [helper doFoo:@"Test" withMoreThanOneParameter:@1];
            });
            
            it(@"should correctly handle arguments", ^{
                //Also when they return values
                [_instrumenter traceSelector:@selector(doSomethingNewWithThisString:) forClass:[VMTestsHelper class]];
                [[[helper doSomethingNewWithThisString:@"Test"] should] equal:@"Test___"];
            });
            
            it(@"should work with BOOL values", ^{
                [_instrumenter traceSelector:@selector(booleanTest) forClass:[VMTestsHelper class]];
                [[theValue([helper booleanTest]) should] beTrue];
            });
            
            it(@"should work with double and float values", ^{
                [_instrumenter traceSelector:@selector(floatTest) forClass:[VMTestsHelper class]];
                [[theValue([helper floatTest]) should] equal:theValue(1.5f)];
                
                [_instrumenter traceSelector:@selector(doubleTest) forClass:[VMTestsHelper class]];
                [[theValue([helper doubleTest]) should] equal:theValue(2.0)];
            });
            
            it(@"should work with class methods", ^{
                [_instrumenter traceSelector:@selector(classMethodTakesOneParameter:) forClass:[VMTestsHelper class]];
                [[[VMTestsHelper classMethodTakesOneParameter:@2] should] equal:@4];
            });
        });
    });

SPEC_END
