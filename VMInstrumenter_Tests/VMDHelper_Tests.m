#import "VMDHelper.h"
#import "VMDMethod.h"
#import "VMDClass.h"

@interface VMDHelperClass1 : NSObject

- (void) doFoo;
- (void) doBar;

@end

@interface VMDHelperClass2 : NSObject

- (void) doFoo;
- (void) doBar;

@end

@implementation VMDHelperClass1

- (void) doFoo {}
- (void) doBar {}

@end

@implementation VMDHelperClass2

- (void) doFoo {}
- (void) doBar {}

@end

SPEC_BEGIN(VMDHelperTests)

describe(@"VMDHelper", ^{
    context(@"when generating names for selectors to instrument", ^{
        it(@"should generate different names for different selectors of the same class", ^{
            NSString *selector1 = [VMDHelper generatePlausibleSelectorNameForSelectorToInstrument:@selector(doFoo) ofClass:[VMDHelperClass1 class]];
            NSString *selector2 = [VMDHelper generatePlausibleSelectorNameForSelectorToInstrument:@selector(doBar) ofClass:[VMDHelperClass1 class]];
            [[selector1 shouldNot] equal:selector2];
        });
        
        it(@"should generate different names for same selector on different classes", ^{
            NSString *selector1 = [VMDHelper generatePlausibleSelectorNameForSelectorToInstrument:@selector(doFoo) ofClass:[VMDHelperClass1 class]];
            NSString *selector2 = [VMDHelper generatePlausibleSelectorNameForSelectorToInstrument:@selector(doFoo) ofClass:[VMDHelperClass2 class]];
            [[selector1 shouldNot] equal:selector2];
        });
        
        it(@"should generate the same name if called twice with the same parameters", ^{
            NSString *selector1 = [VMDHelper generatePlausibleSelectorNameForSelectorToInstrument:@selector(doFoo) ofClass:[VMDHelperClass1 class]];
            NSString *selector2 = [VMDHelper generatePlausibleSelectorNameForSelectorToInstrument:@selector(doFoo) ofClass:[VMDHelperClass1 class]];
            [[selector1 should] equal:selector2];
        });
    });
    
    context(@"when generating names for selectors to suppress", ^{
        it(@"should generate different names for different selectors of the same class", ^{
            NSString *selector1 = [VMDHelper generatePlausibleSelectorNameForSelectorToSuppress:@selector(doFoo) ofClass:[VMDHelperClass1 class]];
            NSString *selector2 = [VMDHelper generatePlausibleSelectorNameForSelectorToSuppress:@selector(doBar) ofClass:[VMDHelperClass1 class]];
            [[selector1 shouldNot] equal:selector2];
        });
        
        it(@"should generate different names for same selector on different classes", ^{
            NSString *selector1 = [VMDHelper generatePlausibleSelectorNameForSelectorToSuppress:@selector(doFoo) ofClass:[VMDHelperClass1 class]];
            NSString *selector2 = [VMDHelper generatePlausibleSelectorNameForSelectorToSuppress:@selector(doFoo) ofClass:[VMDHelperClass2 class]];
            [[selector1 shouldNot] equal:selector2];
        });
        
        it(@"should generate the same name if called twice with the same parameters", ^{
            NSString *selector1 = [VMDHelper generatePlausibleSelectorNameForSelectorToSuppress:@selector(doFoo) ofClass:[VMDHelperClass1 class]];
            NSString *selector2 = [VMDHelper generatePlausibleSelectorNameForSelectorToSuppress:@selector(doFoo) ofClass:[VMDHelperClass1 class]];
            [[selector1 should] equal:selector2];
        });
    });
    
    context(@"when getting Method object from a selector", ^{
        it(@"should raise an exception if the selector doesn't exist", ^{
            [[theBlock(^{
                [[VMDClass classWithClass:[self class]] getMethodFromSelector:@selector(doBar) orThrowExceptionWithReason:@"Tests reason"];
            }) should] raise];
        });
        
        it(@"should return a valid Method object otherwise", ^{
            __block Method methodObject;
            [[theBlock(^{
               methodObject = [[VMDClass classWithClass:[VMDHelperClass1 class]] getMethodFromSelector:@selector(doFoo) orThrowExceptionWithReason:@"Test reason"].underlyingMethod;
            }) shouldNot] raise];
            [[theValue(methodObject) shouldNot] beNil];
        });
    });
});

SPEC_END