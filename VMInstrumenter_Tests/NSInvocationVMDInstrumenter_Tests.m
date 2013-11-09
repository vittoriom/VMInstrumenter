#import <Kiwi/Kiwi.h>
#import <XCTest/XCTest.h>
#import "NSInvocation+VMDInstrumenter.h"

@interface NSInvocationVMDInstrumenterHelper : NSObject

- (void) doFoo;

@end

@implementation NSInvocationVMDInstrumenterHelper

- (void) doFoo {}

@end

SPEC_BEGIN(NSInvocationVMDInstrumenterTests)

describe(@"NSInvocation categrory", ^{
    context(@"when creating the NSInvocation object", ^{
        it(@"should correctly work with multiple arguments", ^{
            
        });
        
        it(@"should correctly work with a single argument", ^{
            
        });
        
        it(@"should correctly work with no arguments", ^{
            
        });
        
        it(@"should raise an exception if the selector doesn't exist", ^{
            [[theBlock(^{
                [NSInvocation invocationForSelector:@selector(doFoo) ofClass:[self class] onRealSelf:self withArgsList:nil argsCount:0];
            }) should] raise];
        });
        
        it(@"should work with primitive arguments", ^{
            
        });
        
        it(@"should work with object arguments", ^{
            
        });
    });
    
    context(@"when invoking the NSInvocation other than returning it", ^{
        it(@"it should contain the correct return value", ^{
            
        });
        
        it(@"it should contain the correct return value if primitive", ^{
            
        });
        
        //@TODO all primitive types
        
        it(@"should raise an exception if the selector doesn't exist", ^{
            [[theBlock(^{
                [NSInvocation createAndInvokeSelector:@selector(doFoo) withArgsList:nil argsCount:0 onRealSelf:self]; }) should] raise];
        });
    });
});

SPEC_END