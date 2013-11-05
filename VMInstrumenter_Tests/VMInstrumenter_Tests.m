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
#import "VMTestsHelper.h"

@interface VMDInstrumenter (publicise)

- (const char *) signatureForSelector:(SEL)selector ofClass:(Class)clazz;

@end

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
                [_instrumenter suppressSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
                [[check shouldNot] receive:@selector(dontCallMe)];
                
                [helper canSafelyCallMe];
            });
            
            it(@"should not suppress method twice", ^{
                [_instrumenter suppressSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
                
                [[theBlock(^{
                    [_instrumenter suppressSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
                }) shouldNot] raise];
            });
            
            it(@"should restore suppressed selectors", ^{
                [[check should] receive:@selector(dontCallMe)];
                
                [_instrumenter restoreSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
                
                [helper canSafelyCallMe];
            });
            
            it(@"should not restore a selector twice", ^{
                [_instrumenter suppressSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
                [_instrumenter restoreSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
                
                [[theBlock(^{
                    [_instrumenter restoreSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
                }) should] raise];
                
            });
        });
        
        context(@"when in stable state", ^{
            it(@"should not restore methods not suppressed", ^{
                [[theBlock(^{
                    [_instrumenter restoreSelector:@selector(canSafelyCallMe) forInstancesOfClass:[VMTestsHelper class]];
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
            
            it(@"should restore the original implementation if called twice", ^{
                [_instrumenter replaceSelector:@selector(dontCallMe) ofClass:[VMTestsHelper class] withSelector:@selector(ifReplacedCalled) ofClass:[VMTestsHelper class]];
                
                [[helper2 shouldNot] receive:@selector(canSafelyCallMe)];
                
                [helper dontCallMe];
            });
        });
        
        context(@"when instrumenting selectors", ^{
            __block VMTestsHelper *helper;
            
            beforeEach(^{
                helper = [VMTestsHelper new];
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
            
            pending(@"should not impact return values", ^{
                [_instrumenter traceSelector:@selector(doAndReturnValue:) forClass:[VMTestsHelper class]];
                
                NSString *returnValue = [helper doAndReturnValue:@"Test"];
                [[returnValue should] equal:@"Test"];
            });
            
            pending(@"should instrument selectors that return primitive values", ^{
                [_instrumenter traceSelector:@selector(doAndReturnPrimitiveValue:) forClass:[VMTestsHelper class]];
                
                NSInteger returnValue = [helper doAndReturnPrimitiveValue:3];
                [[theValue(returnValue) should] equal:theValue(3)];
            });
            
            pending(@"should instrument selectors that take more than one parameter", ^{
                [_instrumenter traceSelector:@selector(doFoo:withMoreThanOneParameter:) forClass:[VMTestsHelper class]];
            
                VMTestsHelper *helper2 = [VMTestsHelper new];
                [[helper2 should] receive:@selector(dontCallMe)];
                helper.forwardCalls = helper2;
                
                [helper doFoo:@"Test" withMoreThanOneParameter:@1];
            });
        });
        
        context(@"internal methods", ^{
            it(@"should correctly return method signatures", ^{
                const char * signature = [_instrumenter signatureForSelector:@selector(alwaysReturn3) ofClass:[VMTestsHelper class]];
                NSString * signatureAsObject = [NSString stringWithUTF8String:signature];
                [[[signatureAsObject substringToIndex:1] should] equal:@"i"];
                
                const char * signature2 = [_instrumenter signatureForSelector:@selector(alwaysReturnTest) ofClass:[VMTestsHelper class]];
                NSString * signatureAsObject2 = [NSString stringWithUTF8String:signature2];
                [[[signatureAsObject2 substringToIndex:1] should] equal:@"@"];
                
                const char * signature3 = [_instrumenter signatureForSelector:@selector(doFoo:withMoreThanOneParameter:) ofClass:[VMTestsHelper class]];
                NSString * signatureAsObject3 = [NSString stringWithUTF8String:signature3];
                [[[signatureAsObject3 substringToIndex:1] should] equal:@"v"];
            });
        });
    });

SPEC_END
