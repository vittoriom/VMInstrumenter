#import <Kiwi/Kiwi.h>
#import <XCTest/XCTest.h>
#import "VMDHelper.h"

SPEC_BEGIN(VMDHelperTests)

describe(@"VMDHelper", ^{
    context(@"when generating names for selectors to suppress", ^{
        it(@"should generate different names for different selectors of the same class", ^{
            
        });
        
        it(@"should generate different names for same selector on different classes", ^{
            
        });
        
        it(@"should generate the same name if called twice with the same parameters", ^{
            
        });
    });
    
    context(@"when generating names for selectors to instrument", ^{
        it(@"should generate different names for different selectors of the same class", ^{
            
        });
        
        it(@"should generate different names for same selector on different classes", ^{
            
        });
        
        it(@"should generate different names for same selector on different instances of the same class", ^{
            
        });
        
        it(@"should generate the same name if called twice with the same parameters", ^{
            
        });
    });
    
    context(@"when getting Method object from a selector", ^{
        it(@"should raise an exception if the selector doesn't exist", ^{
            
        });
        
        it(@"should return a valid Method object otherwise", ^{
            
        });
    });
});

SPEC_END