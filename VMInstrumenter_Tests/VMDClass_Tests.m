#import "VMDClass.h"
#import "VMDHelper.h"
#import "VMDMethod.h"

@interface VMDClass_Test : NSObject

@property (nonatomic, strong) NSString *testProperty;

- (void) doFoo;

@end

@implementation VMDClass_Test {
    NSNumber *testIvar;
}

- (void) doFoo
{
    
}

@end

SPEC_BEGIN(VMDClass_Tests)

describe(@"VMDClass", ^{
    context(@"when creating a wrapper", ^{
        context(@"with classWithClass: constructor", ^{
            it(@"Should not return nil if a class is specified", ^{
                VMDClass *sut = [VMDClass classWithClass:[self class]];
                [[sut shouldNot] beNil];
            });
            
            it(@"Should return nil if a class is not specified", ^{
                VMDClass *sut = [VMDClass classWithClass:nil];
                [[sut should] beNil];
                sut = [VMDClass classWithClass:NSClassFromString(@"Nonexisting_Class")];
                [[sut should] beNil];
            });
        });
        
        context(@"with classFromString: constructor", ^{
            it(@"should not return nil if a correct class name is specified", ^{
                VMDClass *sut = [VMDClass classFromString:@"NSURLConnection"];
                [[sut shouldNot] beNil];
            });
            
            it(@"should return nil if a non-existing class is specified", ^{
                VMDClass *sut = [VMDClass classFromString:@"IdontExistAnywhere"];
                [[sut should] beNil];
            });
            
            it(@"Should return nil if a nil parameter is specified", ^{
                VMDClass *sut = [VMDClass classFromString:nil];
                [[sut should] beNil];
            });
        });
    });
    
    context(@"when adding a new method", ^{
        it(@"should raise when arguments are not valid", ^{
            VMDClass *sut = [VMDClass classWithClass:[self class]];
            [[theBlock(^{
                [sut addMethodWithSelector:nil implementation:imp_implementationWithBlock(^{}) andSignature:"v:@"];
            }) should] raise];
        });
        
        it(@"Should correctly add a new method otherwise", ^{
            VMDClass *sut = [VMDClass classWithClass:[self class]];
            [[theBlock(^{
                [sut addMethodWithSelector:@selector(fileType) implementation:imp_implementationWithBlock(^{}) andSignature:"v:@"];
            }) shouldNot] raise];
        });
    });
    
    context(@"when getting a VMDMethod", ^{
        __block VMDClass *sut;
        
        beforeEach(^{
            sut = [VMDClass classWithClass:[VMDHelper class]];
        });
        
        it(@"Should raise if the method doesn't exist", ^{
            [[theBlock(^{
                [sut getMethodFromSelector:@selector(fileType) orThrowExceptionWithReason:@"No reason"];
            }) should] raise];
        });
        
        it(@"Should return a valid VMDMethod for class methods", ^{
            VMDMethod *method = [sut getMethodFromSelector:@selector(generatePlausibleSelectorNameForSelectorToInstrument:ofClass:) orThrowExceptionWithReason:@"no reason"];
            [[method shouldNot] beNil];
            [[[method name] should] equal:NSStringFromSelector(@selector(generatePlausibleSelectorNameForSelectorToInstrument:ofClass:))];
        });
        
        it(@"Should return a valid VMDMethod for instance methods", ^{
            VMDClass *anotherSut = [VMDClass classWithClass:[VMDClass_Test class]];
            VMDMethod *method = [anotherSut getMethodFromSelector:@selector(doFoo) orThrowExceptionWithReason:@"No reason"];
            [[method shouldNot] beNil];
            [[[method name] should] equal:NSStringFromSelector(@selector(doFoo))];
        });
    });
    
    context(@"when getting a class method", ^{
        __block VMDClass *sut;
        
        beforeEach(^{
            sut = [VMDClass classWithClass:[VMDHelper class]];
        });
        
        it(@"Should return nil if the method is not valid", ^{
            VMDMethod *method = [sut getMethodFromClassSelector:@selector(doFoo)];
            [[method should] beNil];
        });
        
        it(@"Should return a valid VMDMethod otherwise", ^{
            VMDMethod *method = [sut getMethodFromClassSelector:@selector(generatePlausibleSelectorNameForSelectorToInstrument:ofClass:)];
            [[method shouldNot] beNil];
            [[method.name should] equal:NSStringFromSelector(@selector(generatePlausibleSelectorNameForSelectorToInstrument:ofClass:))];
        });
    });
    
    context(@"when getting an instance method", ^{
        __block VMDClass *sut;
        
        beforeEach(^{
            sut = [VMDClass classWithClass:[VMDClass_Test class]];
        });
        
        it(@"Should return nil if the method is not valid", ^{
            VMDMethod *method = [sut getMethodFromInstanceSelector:@selector(dominantLanguage)];
            [[method should] beNil];
        });
        
        it(@"Should return a valid VMDMethod otherwise", ^{
            VMDMethod *method = [sut getMethodFromInstanceSelector:@selector(doFoo)];
            [[method shouldNot] beNil];
            [[method.name should] equal:NSStringFromSelector(@selector(doFoo))];
        });
    });
    
    context(@"when checking if the method is an instance or a class method", ^{
        it(@"Should correctly return if the method is an instance method", ^{
            VMDClass *sut = [VMDClass classWithClass:[VMDClass_Test class]];
            [[theValue([sut isInstanceMethod:@selector(doFoo)]) should] beTrue];
        });
        
        it(@"Should correctly return if the method is a class method", ^{
            VMDClass *sut = [VMDClass classWithClass:[VMDHelper class]];
            [[theValue([sut isClassMethod:@selector(generatePlausibleSelectorNameForSelectorToInstrument:ofClass:)]) should] beTrue];
        });
        
        it(@"Should return NO if the method doesn't belong to the class", ^{
            //2 tests here
            VMDClass *sut = [VMDClass classWithClass:[VMDClass_Test class]];
            [[theValue([sut isClassMethod:@selector(generatePlausibleSelectorNameForSelectorToInstrument:ofClass:)]) should] beFalse];
            [[theValue([sut isInstanceMethod:@selector(generatePlausibleSelectorNameForSelectorToInstrument:ofClass:)]) should] beFalse];
        });
    });
    
    context(@"when getting properties", ^{
        __block VMDClass *sut;
        
        beforeEach(^{
            sut = [VMDClass classWithClass:[VMDClass_Test class]];
        });
    
        it(@"should correctly return the method list", ^{
            NSArray *methods = [sut methods];
            //Getter, setter, doFoo and .cxx_destruct
            [[theValue(methods.count) should] equal:theValue(4)];
        });
        
        it(@"should correctly return the ivars list", ^{
            NSArray *ivars = [sut ivars];
            //The ivar, the ivar backing the property
            [[theValue(ivars.count) should] equal:theValue(2)];
        });
        
        it(@"should correctly return the properties list", ^{
            NSArray *properties = [sut properties];
            [[theValue(properties.count) should] equal:theValue(1)];
        });
        
        it(@"should correctly return the underlying Class value", ^{
            Class underlying = [sut underlyingClass];
            [[theValue(underlying) should] equal:theValue([VMDClass_Test class])];
        });
    });
});

SPEC_END