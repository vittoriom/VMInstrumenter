//
//  VMTestsHelper.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMTestsHelper.h"

@implementation VMTestsHelper

+ (void) classMethodToSuppress
{
    [self classMethodReturnsObject];
}

+ (NSNumber *) classMethodReturnsObject
{
    return @5;
}

+ (NSNumber *) classMethodTakesOneParameter:(NSNumber *)param {
    return @([param intValue] * 2);
}

- (void) dontCallMe
{
    //You did!
}

- (void) canSafelyCallMe
{
    [self.forwardCalls dontCallMe];
}

- (NSInteger) alwaysReturn3
{
    return 3;
}

- (NSString *) alwaysReturnTest
{
    return @"Test";
}

- (void) ifReplacedCalled
{
    [self.forwardCalls canSafelyCallMe];
}

- (NSString *) doAndReturnValue:(NSString *)value
{
    return value;
}

- (NSInteger) doAndReturnPrimitiveValue:(NSInteger)pValue
{
    return pValue;
}

- (void) doFoo:(NSString *)foo withMoreThanOneParameter:(NSObject *)second
{
    [self.forwardCalls dontCallMe];
}

- (float) floatTest
{
    return 1.5f;
}

- (double) doubleTest
{
    return 2.0;
}

- (BOOL) booleanTest
{
    return YES;
}

- (NSString *)doSomethingNewWithThisString:(NSString *)thisStr
{
    return [thisStr stringByAppendingString:@"___"];
}

@end
