#import "VMTestsHelper.h"
#import "NSInvocation+VMDInstrumenter.h"

@interface NSInvocationVMDInstrumenterHelper : NSObject

- (void) doFoo;

@end

@implementation NSInvocationVMDInstrumenterHelper

- (void) doFoo {}

@end

SPEC_BEGIN(NSInvocationVMDInstrumenterTests)

describe(@"NSInvocation categrory", ^{
    __block VMTestsHelper *helper;
    
    context(@"when creating the NSInvocation object", ^{
        beforeEach(^{
            helper = [VMTestsHelper new];
        });
        
        afterEach(^{
            helper = nil;
        });
        
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
        it(@"it should contain the correct return value if void", ^{
            
        });
        
        it(@"it should contain the correct return value if object", ^{
            
        });
        
        it(@"it should contain the correct return value if char", ^{
            
        });
        
        it(@"it should contain the correct return value if unsigned char", ^{
            
        });
        
        it(@"it should contain the correct return value if bool", ^{
            
        });
        
        it(@"it should contain the correct return value if selector", ^{
            
        });
        
        it(@"it should contain the correct return value if Class", ^{
            
        });
        
        it(@"it should contain the correct return value if float", ^{
            
        });
        
        it(@"it should contain the correct return value if double", ^{
            
        });
        
        it(@"it should contain the correct return value if int", ^{
            
        });
        
        it(@"it should contain the correct return value if unsigned int", ^{
            
        });
        
        it(@"it should contain the correct return value if short", ^{
            
        });
        
        it(@"it should contain the correct return value if unsigned short", ^{
            
        });
        
        it(@"it should contain the correct return value if long", ^{
            
        });
        
        it(@"it should contain the correct return value if unsigned long", ^{
            
        });
        
        it(@"it should contain the correct return value if long long", ^{
            
        });
        
        it(@"it should contain the correct return value if unsigned long long", ^{
            
        });
        
        it(@"should raise an exception if the selector doesn't exist", ^{
            [[theBlock(^{
                [NSInvocation createAndInvokeSelector:@selector(doFoo) withArgsList:nil argsCount:0 onRealSelf:self]; }) should] raise];
        });
    });
});

SPEC_END