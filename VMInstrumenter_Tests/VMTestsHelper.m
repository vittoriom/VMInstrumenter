//
//  VMTestsHelper.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMTestsHelper.h"

@implementation VMTestsHelper

- (void) dontCallMe
{
    //You did!
}

- (void) canSafelyCallMe
{
    [self.forwardCalls dontCallMe];
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

@end
