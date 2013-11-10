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

- (char)alwaysReturnD {
    char D = 'D';
    return D;
}

- (unsigned char)alwaysReturnE {
    unsigned char E = 'E';
    return E;
}

- (BOOL)alwaysReturnYES {
    return YES;
}

- (SEL)alwaysReturnThisSelector {
    return @selector(alwaysReturnThisSelector);
}

- (Class)alwaysReturnThisClass {
    return [self class];
}

- (float)alwaysReturn5dot2 {
    return 5.2f;
}

- (double)alwaysReturn4dot34222 {
    return 4.34222;
}

- (int)alwaysReturnMinus3231 {
    int result = -3231;
    return result;
}

- (unsigned int)alwaysReturn4123 {
    unsigned int result = 4123;
    return result;
}

- (short)alwaysReturnMinus20 {
    short result = -20;
    return result;
}

- (unsigned short)alwaysReturn8 {
    unsigned short result = 8;
    return result;
}

- (long)alwaysReturnMinus1283129829 {
    long result = -1283129829l;
    return result;
}

- (unsigned long)alwaysReturn342452213 {
    unsigned long result = 342452213l;
    return result;
}

- (long long)alwaysReturnMinus9218391283 {
    long long result = -9218391283ll;
    return result;
}

- (unsigned long long)alwaysReturn2983192812 {
    unsigned long long result = 2983192812ll;
    return result;
}

- (void) voidNoArgs
{
    
}

- (NSString *) alwaysReturnTest {
    return @"Test";
}

- (NSString *)alwaysReturnSpecifiedString:(NSString *)specified {
    return specified;
}

- (char)alwaysReturnSpecifiedChar:(char)specified {
    return specified;
}

- (unsigned char)alwaysReturnSpecifiedUnsignedChar:(unsigned char)specified {
    return specified;
}

- (BOOL)alwaysReturnSpecifiedBoolean:(BOOL)specified {
    return specified;
}

- (SEL)alwaysReturnSpecifiedSelector:(SEL)specified {
    return specified;
}

- (Class)alwaysReturnSpecifiedClass:(Class)specified {
    return specified;
}

- (float)alwaysReturnSpecifiedFloat:(float)specified {
    return specified;
}

- (double)alwaysReturnSpecifiedDouble:(double)specified {
    return specified;
}

- (int)alwaysReturnSpecifiedInt:(int)specified {
    return specified;
}

- (unsigned int)alwaysReturnSpecifiedUnsignedInt:(unsigned int)specified {
    return specified;
}

- (short)alwaysReturnSpecifiedShort:(short)specified {
    return specified;
}

- (unsigned short)alwaysReturnSpecifiedUnsignedShort:(unsigned short)specified {
    return specified;
}

- (long)alwaysReturnSpecifiedLong:(long)specified {
    return specified;
}

- (unsigned long)alwaysReturnSpecifiedUnsignedLong:(unsigned long)specified {
    return specified;
}

- (long long)alwaysReturnSpecifiedLongLong:(long long)specified {
    return specified;
}

- (unsigned long long)alwaysReturnSpecifiedUnsignedLongLong:(unsigned long long)specified {
    return specified;
}

- (NSString *)alwaysReturn:(id)dummy specifiedString:(NSString *)specified {
    return specified;
}

- (char)alwaysReturn:(id)dummy specifiedChar:(char)specified {
    return specified;
}

- (unsigned char)alwaysReturn:(id)dummy specifiedUnsignedChar:(unsigned char)specified {
    return specified;
}

- (BOOL)alwaysReturn:(id)dummy specifiedBoolean:(BOOL)specified {
    return specified;
}

- (SEL)alwaysReturn:(id)dummy specifiedSelector:(SEL)specified {
    return specified;
}

- (Class)alwaysReturn:(id)dummy specifiedClass:(Class)specified {
    return specified;
}

- (float)alwaysReturn:(id)dummy specifiedFloat:(float)specified {
    return specified;
}

- (double)alwaysReturn:(id)dummy specifiedDouble:(double)specified {
    return specified;
}

- (int)alwaysReturn:(id)dummy specifiedInt:(int)specified {
    return specified;
}

- (unsigned int)alwaysReturn:(id)dummy specifiedUnsignedInt:(unsigned int)specified {
    return specified;
}

- (short)alwaysReturn:(id)dummy specifiedShort:(short)specified {
    return specified;
}

- (unsigned short)alwaysReturn:(id)dummy specifiedUnsignedShort:(unsigned short)specified {
    return specified;
}

- (long)alwaysReturn:(id)dummy specifiedLong:(long)specified {
    return specified;
}

- (unsigned long)alwaysReturn:(id)dummy specifiedUnsignedLong:(unsigned long)specified {
    return specified;
}

- (long long)alwaysReturn:(id)dummy specifiedLongLong:(long long)specified {
    return specified;
}

- (unsigned long long)alwaysReturn:(id)dummy specifiedUnsignedLongLong:(unsigned long long)specified {
    return specified;
}

- (void) ifReplacedCalled
{
    [self.forwardCalls canSafelyCallMe];
}

- (void) testPassingBlocks
{
    
}

@end
