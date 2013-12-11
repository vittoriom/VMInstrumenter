#import "VMDIvar.h"
#import "VMDClass.h"

@interface VMDIvar_Helper : NSObject

@end

@implementation VMDIvar_Helper {
    NSString *strIvar;
    NSNumber *numIvar;
    BOOL boolIvar;
    char charIvar;
    Class classIvar;
    NSInteger intIvar;
    long longIvar;
}

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        strIvar = @"Test";
        numIvar = @2;
        boolIvar = YES;
        charIvar = 'V';
        classIvar = [self class];
        intIvar = 2;
        longIvar = 123456789l;
    }
    return self;
}

@end

SPEC_BEGIN(VMDIvar_Tests)

describe(@"VMDIvar", ^{
    __block VMDIvar_Helper *helper;
    __block VMDClass *classHelper;
    __block VMDIvar *sut;
    __block NSArray *ivars;
    
    beforeAll(^{
        helper = [VMDIvar_Helper new];
        classHelper = [VMDClass classWithClass:[VMDIvar_Helper class]];
        ivars = [classHelper ivars];
        sut = ivars[0];
    });
    
    afterAll(^{
        helper = nil;
        classHelper = nil;
        sut = nil;
    });
    
    context(@"when getting properties", ^{
        it(@"should correctly return the ivar name", ^{
            [[[sut name] should] equal:@"strIvar"];
        });
        
        it(@"should correctly return the underlying Ivar value", ^{
            [[theValue(sut.underlyingIvar) shouldNot] beNil];
        });
        
        it(@"should correctly return the encoded type", ^{
            [[theValue(sut.type) should] equal:theValue(VMDEncodedTypeObject)];
        });
    });
    
    context(@"when creating new instances", ^{
        context(@"sith ivarWithIvar: constructor", ^{
            it(@"should return nil if the ivar is not valid or nil", ^{
                VMDIvar *ivar = [VMDIvar ivarWithIvar:nil];
                [[ivar should] beNil];
            });
            
            it(@"should return a valid VMDIvar wrapper otherwise", ^{
                VMDIvar *ivar = [VMDIvar ivarWithIvar:sut.underlyingIvar];
                [[ivar shouldNot] beNil];
                [[ivar.name should] equal:@"strIvar"];
            });
        });
        
        context(@"with ivarWithName:fromClass: constructor", ^{
            it(@"should return a valid VMDIvar if a correct ivar name is specified", ^{
                VMDIvar *sut = [VMDIvar ivarWithName:@"numIvar" fromClass:[VMDIvar_Helper class]];
                [[sut shouldNot] beNil];
                [[[sut name] should] equal:@"numIvar"];
            });
            
            it(@"should return nil if a non-existing ivar name is specified", ^{
                VMDIvar *sut = [VMDIvar ivarWithName:@"Idontexist" fromClass:[VMDIvar_Helper class]];
                [[sut should] beNil];
            });
            
            it(@"should return nil if a nil parameter is specified", ^{
                VMDIvar *sut = [VMDIvar ivarWithName:nil fromClass:[VMDIvar_Helper class]];
                [[sut should] beNil];
                
                sut = [VMDIvar ivarWithName:@"Test" fromClass:nil];
                [[sut should] beNil];
            });
        });
        
        context(@"with ivarWithName:fromVMDClass: constructor", ^{
            it(@"should return a valid VMDIvar if a correct ivar name is specified", ^{
                VMDIvar *sut = [VMDIvar ivarWithName:@"numIvar" fromVMDClass:[VMDClass classWithClass:[VMDIvar_Helper class]]];
                [[sut shouldNot] beNil];
                [[[sut name] should] equal:@"numIvar"];
            });
            
            it(@"should return nil if a non-existing ivar name is specified", ^{
                VMDIvar *sut = [VMDIvar ivarWithName:@"Idontexist" fromVMDClass:[VMDClass classWithClass:[VMDIvar_Helper class]]];
                [[sut should] beNil];
            });
            
            it(@"should return nil if a nil parameter is specified", ^{
                VMDIvar *sut = [VMDIvar ivarWithName:nil fromVMDClass:[VMDClass classWithClass:[VMDIvar_Helper class]]];
                [[sut should] beNil];
                
                sut = [VMDIvar ivarWithName:@"Test" fromClass:nil];
                [[sut should] beNil];
            });
        });
    });
    
    context(@"when returning the ivar value", ^{
        it(@"should raise if using the wrong method", ^{
            [[theValue([sut intValueForObject:helper]) shouldNot] equal:theValue(2)];
        });
        
        it(@"should correctly return id values for id properties", ^{
            NSString *test = [sut valueForObject:helper];
            [[test should] equal:@"Test"];
        });
        
        it(@"should correctly return char values for char properties", ^{
            VMDIvar *test = ivars[3];
            NSNumber *result = @([test charValueForObject:helper]);
            [[result should] equal:theValue('V')];
        });
        
        it(@"should correctly return int values for int properties", ^{
            VMDIvar *test = ivars[5];
            NSNumber *result = @([test intValueForObject:helper]);
            [[result should] equal:theValue(2)];
        });
        
        it(@"should correctly return Class values for Class properties", ^{
            VMDIvar *test = ivars[4];
            [[theValue([test classValueForObject:helper]) should] equal:theValue([VMDIvar_Helper class])];
        });
        
        it(@"should correctly return long values for long properties", ^{
            VMDIvar *test = ivars[6];
            NSNumber *result = [NSNumber numberWithLong:[test longValueForObject:helper]];
            [[result should] equal:@(123456789l)];
        });
        
        it(@"should correctly return BOOL values for BOOL properties", ^{
            VMDIvar *test = ivars[2];
            [[theValue([test boolValueForObject:helper]) should] beTrue];
        });
    });
});

SPEC_END