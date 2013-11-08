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
            
        });
        
        it(@"should correctly return signature 5", ^{
            
        });
        
        it(@"should correctly return signature 6", ^{
            
        });
        
        it(@"should correctly return signature 7", ^{
            
        });
        
        it(@"should correctly return signature 8", ^{
            
        });
        
        it(@"should raise an exception if the selector doesn't exist", ^{
        
        });
    });
    
    context(@"when returning the number of arguments of a selector", ^{
        it(@"should work with 0 arguments", ^{
            
        });
        
        it(@"should work with 1 argument", ^{
            
        });
        
        it(@"should work with more than 1 argument", ^{
            
        });
        
        it(@"should raise an exception if the selector doesn't exist", ^{
            
        });
    });
    
    context(@"when returning the NSMethodSignature of a selector", ^{
        it(@"should work with selector 1", ^{
            
        });
        
        it(@"should work with selector 2", ^{
            
        });
        
        it(@"should work with selector 3", ^{
            
        });
        
        it(@"should work with selector 4", ^{
            
        });
        
        it(@"should work with selector 5", ^{
            
        });
        
        it(@"should raise an exception if the selector doesn't exist", ^{
            
        });
    });
    
    context(@"when returning the type of the argument in a selector", ^{
        it(@"should work with the self implicit argument", ^{
            
        });
        
        it(@"should work with the _cmd implicit argument", ^{
            
        });
        
        it(@"should work with object arguments", ^{
            
        });
        
        it(@"should work with primitive arguments", ^{
            
        });
    });
    
    context(@"when getting Method type", ^{
        it(@"should correctly distinguish between instance and class methods", ^{
            
        });
        
        it(@"should throw an exception if called with a class that doesn't respond to the selector", ^{
            
        });
    });
});

SPEC_END