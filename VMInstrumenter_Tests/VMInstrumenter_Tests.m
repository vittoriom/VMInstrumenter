//
//  VMInstrumenter_Tests.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

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
                    [_instrumenter suppressSelector:@selector(alwaysReturnTest) forClass:[self class]];
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
            
            beforeAll(^{
                _instrumenter = [VMDInstrumenter new];
            });
            
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
                    [_instrumenter replaceSelector:@selector(alwaysReturnTest) ofClass:[self class] withSelector:@selector(alwaysReturn2983192812) ofClass:[VMTestsHelper class]];
                }) should] raise];
            });
            
            it(@"should restore the original implementation if called twice", ^{
                [_instrumenter replaceSelector:@selector(dontCallMe) ofClass:[VMTestsHelper class] withSelector:@selector(ifReplacedCalled) ofClass:[VMTestsHelper class]];
                
                [[helper2 shouldNot] receive:@selector(canSafelyCallMe)];
                
                [helper dontCallMe];
            });
        });
        
        context(@"when tracing selectors for a class", ^{
            __block VMTestsHelper *helper;
            
            beforeAll(^{
                _instrumenter = [VMDInstrumenter new];
            });
            
            beforeEach(^{
                helper = [VMTestsHelper new];
            });
            
            afterEach(^{
                helper = nil;
            });
            
            it(@"should not trace a selector twice", ^{
                [_instrumenter traceSelector:@selector(dontCallMe) forClass:[VMTestsHelper class]];
                
                [[theBlock(^{
                    [_instrumenter traceSelector:@selector(dontCallMe) forClass:[VMTestsHelper class]];
                }) should] raise];
            });
            
            context(@"that don't take any argument", ^{
                it(@"should work with object return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnTest) forClass:[VMTestsHelper class]];
                    
                    [[[helper alwaysReturnTest] should] equal:@"Test"];
                });
                
                it(@"should work with char return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnD) forClass:[VMTestsHelper class]];
                    char returnChar = [helper alwaysReturnD];
                    [[theValue(returnChar == 'D') should] beTrue];
                });
                
                it(@"should work with unsigned char return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnE) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnE]) should] equal:@('E')];
                });
                
                it(@"should work with SEL return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnThisSelector) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnThisSelector]) should] equal:theValue(@selector(alwaysReturnThisSelector))];
                });
                
                it(@"should work with Class return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnThisClass) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnThisClass]) should] equal:theValue([helper class])];
                });
                
                it(@"should work with unsigned int return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn4123) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturn4123]) should] equal:@(4123)];
                });
                
                it(@"should work with short return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnMinus20) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnMinus20]) should] equal:@(-20)];
                });
                
                it(@"should work with unsigned short return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn8) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturn8]) should] equal:@(8)];
                });
                
                it(@"should work with long return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnMinus1283129829) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnMinus1283129829]) should] equal:@(-1283129829l)];
                });
                
                it(@"should work with unsigned long return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn342452213) forClass:[VMTestsHelper class]];
                    unsigned long returnULong = [helper alwaysReturn342452213];
                    [[theValue(returnULong == 342452213l) should] beTrue];
                });
                
                it(@"should work with long long return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnMinus9218391283) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnMinus9218391283]) should] equal:@(-9218391283ll)];
                });
                
                it(@"should work with unsigned long long return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn2983192812) forClass:[VMTestsHelper class]];
                    unsigned long long returnULLong = [helper alwaysReturn2983192812];
                    [[theValue(returnULLong == 2983192812ll) should] beTrue];
                });
                
                it(@"should work with int return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnMinus3231) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnMinus3231]) should] equal:@(-3231)];
                });
                
                it(@"should work with BOOL return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnYES) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnYES]) should] beTrue];
                });
                
                it(@"should work with double return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn4dot34222) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturn4dot34222]) should] equal:theValue(4.34222)];
                });
                
                it(@"should work with float return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn5dot2) forClass:[VMTestsHelper class]];
                    float value = [helper alwaysReturn5dot2];
                    [[theValue(value) should] equal:theValue(5.2f)];
                });
            });
            
            context(@"that take one argument", ^{
                it(@"should work with object return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedString:) forClass:[VMTestsHelper class]];
                    
                    [[[helper alwaysReturnSpecifiedString:@"Test"] should] equal:@"Test"];
                });
                
                it(@"should work with char return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedChar:) forClass:[VMTestsHelper class]];
                    char returnChar = [helper alwaysReturnSpecifiedChar:'f'];
                    [[theValue(returnChar == 'f') should] beTrue];
                });
                
                it(@"should work with unsigned char return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedUnsignedChar:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnSpecifiedUnsignedChar:'u']) should] equal:@('u')];
                });
                
                it(@"should work with SEL return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedSelector:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnSpecifiedSelector:@selector(voidNoArgs)]) should] equal:theValue(@selector(voidNoArgs))];
                });
                
                it(@"should work with Class return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedClass:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnSpecifiedClass:[VMDHelper class]]) should] equal:theValue([VMDHelper class])];
                });
                
                it(@"should work with unsigned int return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedUnsignedInt:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnSpecifiedUnsignedInt:22132]) should] equal:@(22132)];
                });
                
                it(@"should work with short return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedShort:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnSpecifiedShort:-30]) should] equal:@(-30)];
                });
                
                it(@"should work with unsigned short return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedUnsignedShort:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnSpecifiedUnsignedShort:10]) should] equal:@(10)];
                });
                
                it(@"should work with long return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedLong:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnSpecifiedLong:121212l]) should] equal:@(121212l)];
                });
                
                it(@"should work with unsigned long return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedUnsignedLong:) forClass:[VMTestsHelper class]];
                    unsigned long returnULong = [helper alwaysReturnSpecifiedUnsignedLong:1231231l];
                    [[theValue(returnULong == 1231231l) should] beTrue];
                });
                
                it(@"should work with long long return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedLongLong:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnSpecifiedLongLong:-123123123ll]) should] equal:@(-123123123ll)];
                });
                
                it(@"should work with unsigned long long return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedUnsignedLongLong:) forClass:[VMTestsHelper class]];
                    unsigned long long returnULLong = [helper alwaysReturnSpecifiedUnsignedLongLong:123123123ll];
                    [[theValue(returnULLong == 123123123ll) should] beTrue];
                });
                
                it(@"should work with int return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedInt:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnSpecifiedInt:-987]) should] equal:@(-987)];
                });
                
                it(@"should work with BOOL return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedBoolean:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnSpecifiedBoolean:NO]) should] beFalse];
                });
                
                it(@"should work with double return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedDouble:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturnSpecifiedDouble:12.1230]) should] equal:theValue(12.1230)];
                });
                
                it(@"should work with float return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturnSpecifiedFloat:) forClass:[VMTestsHelper class]];
                    float value = [helper alwaysReturnSpecifiedFloat:-12.2f];
                    [[theValue(value) should] equal:theValue(-12.2f)];
                });
            });
            
            context(@"that take two or more argument", ^{
                it(@"should work with object return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedString:) forClass:[VMTestsHelper class]];
                    
                    [[[helper alwaysReturn:nil specifiedString:@"Test"] should] equal:@"Test"];
                });
                
                it(@"should work with char return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedChar:) forClass:[VMTestsHelper class]];
                    char returnChar = [helper alwaysReturn:nil specifiedChar:'f'];
                    [[theValue(returnChar == 'f') should] beTrue];
                });
                
                it(@"should work with unsigned char return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedUnsignedChar:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturn:nil specifiedUnsignedChar:'u']) should] equal:@('u')];
                });
                
                it(@"should work with SEL return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedSelector:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturn:nil specifiedSelector:@selector(voidNoArgs)]) should] equal:theValue(@selector(voidNoArgs))];
                });
                
                it(@"should work with Class return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedClass:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturn:nil specifiedClass:[VMDHelper class]]) should] equal:theValue([VMDHelper class])];
                });
                
                it(@"should work with unsigned int return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedUnsignedInt:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturn:nil specifiedUnsignedInt:22132]) should] equal:@(22132)];
                });
                
                it(@"should work with short return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedShort:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturn:nil specifiedShort:-30]) should] equal:@(-30)];
                });
                
                it(@"should work with unsigned short return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedUnsignedShort:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturn:nil specifiedUnsignedShort:10]) should] equal:@(10)];
                });
                
                it(@"should work with long return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedLong:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturn:nil specifiedLong:121212l]) should] equal:@(121212l)];
                });
                
                it(@"should work with unsigned long return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedUnsignedLong:) forClass:[VMTestsHelper class]];
                    unsigned long returnULong = [helper alwaysReturn:nil specifiedUnsignedLong:1231231l];
                    [[theValue(returnULong == 1231231l) should] beTrue];
                });
                
                it(@"should work with long long return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedLongLong:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturn:nil specifiedLongLong:-123123123ll]) should] equal:@(-123123123ll)];
                });
                
                it(@"should work with unsigned long long return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedUnsignedLongLong:) forClass:[VMTestsHelper class]];
                    unsigned long long returnULLong = [helper alwaysReturn:nil specifiedUnsignedLongLong:123123123ll];
                    [[theValue(returnULLong == 123123123ll) should] beTrue];
                });
                
                it(@"should work with int return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedInt:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturn:nil specifiedInt:-987]) should] equal:@(-987)];
                });
                
                it(@"should work with BOOL return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedBoolean:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturn:nil specifiedBoolean:NO]) should] beFalse];
                });
                
                it(@"should work with double return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedDouble:) forClass:[VMTestsHelper class]];
                    [[theValue([helper alwaysReturn:nil specifiedDouble:12.1230]) should] equal:theValue(12.1230)];
                });
                
                it(@"should work with float return values", ^{
                    [_instrumenter traceSelector:@selector(alwaysReturn:specifiedFloat:) forClass:[VMTestsHelper class]];
                    float value = [helper alwaysReturn:nil specifiedFloat:-12.2f];
                    [[theValue(value) should] equal:theValue(-12.2f)];
                });
            });
            
            it(@"should work with class methods", ^{
                [_instrumenter traceSelector:@selector(classMethodTakesOneParameter:) forClass:[VMTestsHelper class]];
                [[[VMTestsHelper classMethodTakesOneParameter:@2] should] equal:@4];
            });
            
            it(@"should work with class methods that return values", ^{
                [_instrumenter traceSelector:@selector(classMethodReturnsObject) forClass:[VMTestsHelper class]];
                [[[VMTestsHelper classMethodReturnsObject] should] equal:@5];
            });
        });
        
        
        context(@"when instrumenting selectors for a specific instance", ^{
            beforeAll(^{
                _instrumenter = [VMDInstrumenter new];
            });
            
            it(@"should work only with that specific instance", ^{
                VMTestsHelper *helper = [VMTestsHelper new];
                VMTestsHelper *notHelper = [VMTestsHelper new];
                VMTestsHelper *checker = [VMTestsHelper new];
                helper.forwardCalls = checker;
                notHelper.forwardCalls = checker;
                [_instrumenter instrumentSelector:@selector(voidNoArgs) forObject:helper withBeforeBlock:^(id instance) {
                    [checker dontCallMe];
                } afterBlock:nil];
                
                [[checker should] receive:@selector(dontCallMe) withCount:1];
                [helper voidNoArgs];
                [notHelper voidNoArgs];
            });
        });
        
        context(@"when instrumenting selectors for specific instances of a class", ^{
            beforeAll(^{
                _instrumenter = [VMDInstrumenter new];
            });
            
            it(@"should work only with instances passing the test", ^{
                VMTestsHelper *helper = [VMTestsHelper new];
                VMTestsHelper *helper2 = [VMTestsHelper new];
                VMTestsHelper *checker = [VMTestsHelper new];
                VMTestsHelper *dummy = [VMTestsHelper new];
                VMTestsHelper *notHelper = [VMTestsHelper new];
                helper.forwardCalls = checker;
                helper2.forwardCalls = checker;
                notHelper.forwardCalls = dummy;
                [_instrumenter instrumentSelector:@selector(testPassingBlocks) forInstancesOfClass:[VMTestsHelper class] passingTest:^BOOL(id instance) {
                    return ((VMTestsHelper *)instance).forwardCalls == checker;
                } withBeforeBlock:^(id instance) {
                    [checker dontCallMe];
                } afterBlock:nil];
                
                [[checker should] receive:@selector(dontCallMe) withCount:2];
                [helper testPassingBlocks];
                [helper2 testPassingBlocks];
                [notHelper testPassingBlocks];
            });
        });
    });

SPEC_END
