#import "VMDProperty.h"
#import "VMDClass.h"

@interface VMDProperty_Helper : NSObject

@property (nonatomic, strong) NSString *testProperty;
@property (nonatomic, assign) BOOL trueProperty;
@property (nonatomic, strong) NSNumber *twoProperty;

@end

@implementation VMDProperty_Helper

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        self.testProperty = @"Test";
        self.trueProperty = YES;
        self.twoProperty = @2;
    }
    return self;
}

@end

SPEC_BEGIN(VMDPropertyTests)

describe(@"VMDProperty",^{
    __block VMDProperty_Helper *helper;
    __block VMDClass *classHelper;
    __block VMDProperty *sut;
    __block NSArray *properties;
    
    beforeAll(^{
        helper = [VMDProperty_Helper new];
        classHelper = [VMDClass classWithClass:[VMDProperty_Helper class]];
        properties = [classHelper properties];
        sut = properties[0];
    });
    
    afterAll(^{
        helper = nil;
        classHelper = nil;
        sut = nil;
        properties = nil;
    });
    
    context(@"when getting properties", ^{
        it(@"should correctly return property name",^{
            [[[sut name] should] equal:@"testProperty"];
        });
        
        it(@"should correctly return the underlying property",^{
            [[theValue(sut.underlyingProperty) shouldNot] beNil];
        });
    });
    
    context(@"when creating new instances",^{
        context(@"with propertyWithObjectiveCProperty: constructor", ^{
            it(@"should return nil if the instance is not valid",^{
                [[[VMDProperty propertyWithObjectiveCProperty:nil] should] beNil];
            });
            
            it(@"should return a valid VMDProperty otherwise",^{
                VMDProperty *test = [VMDProperty propertyWithObjectiveCProperty:sut.underlyingProperty];
                [[test shouldNot] beNil];
                [[test.name should] equal:@"testProperty"];
            });
        });
        
        context(@"with propertyWithName:forClass: constructor", ^{
            it(@"should return nil if the name is not valid", ^{
                [[[VMDProperty propertyWithName:@"notExisting" forClass:[VMDProperty_Helper class]] should] beNil];
            });
            
            it(@"should return a valid VMDProperty otherwise", ^{
                VMDProperty *test = [VMDProperty propertyWithName:@"testProperty" forClass:[VMDProperty_Helper class]];
                [[test shouldNot] beNil];
                [[test.name should] equal:@"testProperty"];
            });
            
            it(@"should return nil if a nil parameter is specified", ^{
                [[[VMDProperty propertyWithName:nil forClass:[VMDProperty_Helper class]] should] beNil];
                [[[VMDProperty propertyWithName:@"testProperty" forClass:nil] should] beNil];
            });
        });
        
        context(@"with propertyWithName:forVMDClass: constructor", ^{
            it(@"should return nil if the name is not valid", ^{
                [[[VMDProperty propertyWithName:@"notExisting" forVMDClass:[VMDClass classWithClass:[VMDProperty_Helper class]]] should] beNil];
            });
            
            it(@"should return a valid VMDProperty otherwise", ^{
                VMDProperty *test = [VMDProperty propertyWithName:@"testProperty" forVMDClass:[VMDClass classWithClass:[VMDProperty_Helper class]]];
                [[test shouldNot] beNil];
                [[test.name should] equal:@"testProperty"];
            });
            
            it(@"should return nil if a nil parameter is specified", ^{
                [[[VMDProperty propertyWithName:nil forVMDClass:[VMDClass classWithClass:[VMDProperty_Helper class]]] should] beNil];
                [[[VMDProperty propertyWithName:@"testProperty" forClass:nil] should] beNil];
            });
        });
    });
    
    context(@"when getting property value",^{
        it(@"should correctly return the property value otherwise",^{
            [[[sut valueForObject:helper] should] equal:@"Test"];
            sut = properties[1];
            [[[sut valueForObject:helper] should] beTrue];
            sut = properties[2];
            [[[sut valueForObject:helper] should] equal:@2];
        });
    });
});

SPEC_END