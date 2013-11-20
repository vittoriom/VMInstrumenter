#import "VMDMethod.h"
#import "VMDClass.h"

@interface VMDMethod_Helper : NSObject

- (void) voidMethodNoArgs;

- (NSString *) stringMethodOnePrimitiveArg:(NSInteger)arg;

- (BOOL) boolMethodOnePrimitiveArg:(char)arg andOneObjectArg:(NSNumber *)arg2;

@end

@implementation VMDMethod_Helper

- (void) voidMethodNoArgs
{}

- (NSString *) stringMethodOnePrimitiveArg:(NSInteger)arg
{
    return [NSString stringWithFormat:@"%d",arg];
}

- (BOOL) boolMethodOnePrimitiveArg:(char)arg andOneObjectArg:(NSNumber *)arg2
{
    return [arg2 boolValue];
}

@end

SPEC_BEGIN(VMDMethod_Tests)

describe(@"VMDMethod", ^{
    __block VMDMethod_Helper *helper;
    __block VMDClass *classHelper;
    __block VMDMethod *sut;
    __block NSArray *methods;
    
    beforeAll(^{
        helper = [VMDMethod_Helper new];
        classHelper = [VMDClass classWithClass:[VMDMethod_Helper class]];
        methods = [classHelper methods];
        for(VMDMethod *method in methods)
        {
            if([method.name isEqualToString:NSStringFromSelector(@selector(voidMethodNoArgs))])
                sut = method;
        }
    });
    
    context(@"when getting properties", ^{
        it(@"should correctly return the selector", ^{
            [[theValue([sut selector]) should] equal:theValue(@selector(voidMethodNoArgs))];
        });
        
        it(@"should correctly return the method name", ^{
            [[sut.name should] equal:NSStringFromSelector(@selector(voidMethodNoArgs))];
        });
        
        it(@"should correctly the underlying Method value", ^{
            [[theValue(sut.underlyingMethod) shouldNot] beNil];
        });
        
        it(@"should correctly return the full method type encoding", ^{
            [[[NSString stringWithUTF8String:sut.typeEncoding] should] equal:@"v8@0:4"];
        });
        
        it(@"should correctly return the encoded return type", ^{
            [[theValue(sut.returnType) should] equal:theValue(VMDEncodedTypeVoid)];
        });
    });
    
    context(@"when creating new instances", ^{
        it(@"should return nil if the method is not valid", ^{
            VMDMethod *test = [VMDMethod methodWithMethod:nil];
            [[test should] beNil];
        });
        
        it(@"should return a valid VMDMethod otherwise", ^{
            VMDMethod *test = [VMDMethod methodWithMethod:sut.underlyingMethod];
            [[test shouldNot] beNil];
        });
    });
    
    context(@"when exchanging implementations", ^{
        it(@"should raise if the argument is not valid", ^{
            [[theBlock(^{
                [sut exchangeImplementationWithMethod:nil];
            }) should] raise];
        });
        
        it(@"should raise if the argument is the same method", ^{
            [[theBlock(^{
                [sut exchangeImplementationWithMethod:sut];
            }) should] raise];
        });
        
        it(@"should correctly exchange implementations otherwise", ^{
            [[theBlock(^{
                [sut exchangeImplementationWithMethod:methods[1]];
            }) shouldNot] raise];
        });
    });
});

SPEC_END