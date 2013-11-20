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
        it(@"should return nil if the instance is not valid",^{
            [[[VMDProperty propertyWithObjectiveCProperty:nil] should] beNil];
        });
        
        it(@"should return a valid VMDProperty otherwise",^{
            VMDProperty *test = [VMDProperty propertyWithObjectiveCProperty:sut.underlyingProperty];
            [[test shouldNot] beNil];
            [[test.name should] equal:@"testProperty"];
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