#import <Kiwi/Kiwi.h>
#import <XCTest/XCTest.h>
#import "VMTestsHelper.h"
#import "NSMethodSignature+VMDInstrumenter.h"

SPEC_BEGIN(NSMethodSignatureVMDInstrumenterTests)

describe(@"NSMethodSignature category",^{
    context(@"when returning const char signature", ^{
        it(@"should correctly return signature 1", ^{
            const char * signature = [NSMethodSignature constCharSignatureForSelector:@selector(alwaysReturn3) ofClass:[VMTestsHelper class]];
            NSString * signatureAsObject = [NSString stringWithUTF8String:signature];
            [[[signatureAsObject substringToIndex:1] should] equal:@"i"];
        });
        
        it(@"should correctly return signature 2", ^{
            const char * signature2 = [NSMethodSignature constCharSignatureForSelector:@selector(alwaysReturnTest) ofClass:[VMTestsHelper class]];
            NSString * signatureAsObject2 = [NSString stringWithUTF8String:signature2];
            [[[signatureAsObject2 substringToIndex:1] should] equal:@"@"];
        });
        
        it(@"should correctly return signature 3", ^{
            const char * signature3 = [NSMethodSignature constCharSignatureForSelector:@selector(doFoo:withMoreThanOneParameter:) ofClass:[VMTestsHelper class]];
            NSString * signatureAsObject3 = [NSString stringWithUTF8String:signature3];
            [[[signatureAsObject3 substringToIndex:1] should] equal:@"v"];
        });
        
        it(@"should correctly return signature 4", ^{
            const char * signature = [NSMethodSignature constCharSignatureForSelector:@selector(alwaysReturn3) ofClass:[VMTestsHelper class]];
            NSString * signatureAsObject = [NSString stringWithUTF8String:signature];
            [[signatureAsObject should] equal:@"i@:"];
        });
        
        it(@"should correctly return signature 5", ^{
            const char * signature3 = [NSMethodSignature constCharSignatureForSelector:@selector(doFoo:withMoreThanOneParameter:) ofClass:[VMTestsHelper class]];
            NSString * signatureAsObject3 = [NSString stringWithUTF8String:signature3];
            [[signatureAsObject3 should] equal:@"v@:@@"];
        });
        
        it(@"should correctly return signature 6", ^{
            const char * signature3 = [NSMethodSignature constCharSignatureForSelector:@selector(floatTest) ofClass:[VMTestsHelper class]];
            NSString * signatureAsObject3 = [NSString stringWithUTF8String:signature3];
            [[signatureAsObject3 should] equal:@"f@:"];
        });
        
        it(@"should raise an exception if the selector doesn't exist", ^{
            [[theBlock(^{
                [NSMethodSignature constCharSignatureForSelector:@selector(floatTest) ofClass:[self class]];
            }) should] raise];
        });
    });
    
    context(@"when returning the number of arguments of a selector", ^{
        it(@"should work with 0 arguments", ^{
            NSInteger number = [NSMethodSignature numberOfArgumentsForSelector:@selector(dontCallMe) ofClass:[VMTestsHelper class]];
            [[theValue(number) should] equal:theValue(0)];
        });
        
        it(@"should work with 1 argument", ^{
            NSInteger number = [NSMethodSignature numberOfArgumentsForSelector:@selector(doAndReturnPrimitiveValue:) ofClass:[VMTestsHelper class]];
            [[theValue(number) should] equal:theValue(1)];
        });
        
        it(@"should work with more than 1 argument", ^{
            NSInteger number = [NSMethodSignature numberOfArgumentsForSelector:@selector(doFoo:withMoreThanOneParameter:) ofClass:[VMTestsHelper class]];
            [[theValue(number) should] equal:theValue(2)];
        });
        
        it(@"should raise an exception if the selector doesn't exist", ^{
            [[theBlock(^{
                [NSMethodSignature numberOfArgumentsForSelector:@selector(dontCallMe) ofClass:[self class]];
            }) should] raise];
        });
    });
    
    context(@"when returning the NSMethodSignature of a selector", ^{
        it(@"should work with selector 1", ^{
            NSMethodSignature *signature = [NSMethodSignature methodSignatureForSelector:@selector(floatTest) ofClass:[VMTestsHelper class]];
            [[theValue([signature numberOfArguments]) should] equal:theValue(2)];
            [[[[NSString stringWithUTF8String:[signature methodReturnType]] substringToIndex:1] should] equal:@"f"];
        });
        
        it(@"should work with selector 2", ^{
            NSMethodSignature *signature = [NSMethodSignature methodSignatureForSelector:@selector(doFoo:withMoreThanOneParameter:) ofClass:[VMTestsHelper class]];
            [[theValue([signature numberOfArguments]) should] equal:theValue(4)];
            [[[[NSString stringWithUTF8String:[signature methodReturnType]] substringToIndex:1] should] equal:@"v"];
        });
        
        it(@"should work with selector 3", ^{
            NSMethodSignature *signature = [NSMethodSignature methodSignatureForSelector:@selector(doAndReturnValue:) ofClass:[VMTestsHelper class]];
            [[theValue([signature numberOfArguments]) should] equal:theValue(3)];
            [[[[NSString stringWithUTF8String:[signature methodReturnType]] substringToIndex:1] should] equal:@"@"];
        });
        
        it(@"should work with selector 4", ^{
            NSMethodSignature *signature = [NSMethodSignature methodSignatureForSelector:@selector(doAndReturnPrimitiveValue:) ofClass:[VMTestsHelper class]];
            [[theValue([signature numberOfArguments]) should] equal:theValue(3)];
            [[[[NSString stringWithUTF8String:[signature methodReturnType]] substringToIndex:1] should] equal:@"i"];
        });
        
        it(@"should raise an exception if the selector doesn't exist", ^{
            [[theBlock(^{
                [NSMethodSignature methodSignatureForSelector:@selector(doFoo:withMoreThanOneParameter:) ofClass:[self class]];
            }) should] raise];
        });
    });
    
    context(@"when returning the type of the argument in a selector", ^{
        it(@"should work with the self implicit argument", ^{
            NSMethodSignature *signature = [NSMethodSignature methodSignatureForSelector:@selector(doFoo:withMoreThanOneParameter:) ofClass:[VMTestsHelper class]];
            char type = [NSMethodSignature typeOfArgumentInSignature:signature atIndex:0];
            NSString *typeString = [NSString stringWithFormat:@"%c",type];
            
            [[typeString should] equal:@"@"];
        });
        
        it(@"should work with the _cmd implicit argument", ^{
            NSMethodSignature *signature = [NSMethodSignature methodSignatureForSelector:@selector(doFoo:withMoreThanOneParameter:) ofClass:[VMTestsHelper class]];
            char type = [NSMethodSignature typeOfArgumentInSignature:signature atIndex:1];
            NSString *typeString = [NSString stringWithFormat:@"%c",type];
            
            [[typeString should] equal:@":"];
        });
        
        it(@"should work with object arguments", ^{
            NSMethodSignature *signature = [NSMethodSignature methodSignatureForSelector:@selector(doFoo:withMoreThanOneParameter:) ofClass:[VMTestsHelper class]];
            char type = [NSMethodSignature typeOfArgumentInSignature:signature atIndex:2];
            NSString *typeString = [NSString stringWithFormat:@"%c",type];
            
            [[typeString should] equal:@"@"];
        });
        
        it(@"should work with primitive arguments", ^{
            NSMethodSignature *signature = [NSMethodSignature methodSignatureForSelector:@selector(doAndReturnPrimitiveValue:) ofClass:[VMTestsHelper class]];
            char type = [NSMethodSignature typeOfArgumentInSignature:signature atIndex:2];
            NSString *typeString = [NSString stringWithFormat:@"%c",type];
            
            [[typeString should] equal:@"i"];
        });
    });
    
    context(@"when getting Method type", ^{
        it(@"should correctly distinguish between instance and class methods (instance)", ^{
            VMDMethodType type = [NSMethodSignature typeOfMethodForSelector:@selector(doFoo:withMoreThanOneParameter:) ofClass:[VMTestsHelper class]];
            [[theValue(type) should] equal:theValue(VMDInstanceMethodType)];
        });
        
        it(@"should correctly distinguish between instance and class methods (class)", ^{
            VMDMethodType type = [NSMethodSignature typeOfMethodForSelector:@selector(classMethodReturnsObject) ofClass:[VMTestsHelper class]];
            [[theValue(type) should] equal:theValue(VMDClassMethodType)];
        });
        
        it(@"should return Unknown if called with a class that doesn't respond to the selector", ^{
            VMDMethodType type = [NSMethodSignature typeOfMethodForSelector:@selector(classMethodReturnsObject) ofClass:[self class]];
            [[theValue(type) should] equal:theValue(VMDUnknownMethodType)];
        });
    });
});

SPEC_END