//
//  VMTestsHelper.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VMTestsHelper : NSObject

@property (nonatomic, strong) VMTestsHelper *forwardCalls;

+ (void) classMethodToSuppress;

+ (NSNumber *) classMethodReturnsObject;

+ (NSNumber *) classMethodTakesOneParameter:(NSNumber *)param;

- (void) dontCallMe;

- (void) canSafelyCallMe;

- (void) ifReplacedCalled;

- (void) testPassingBlocks;

// 0 arguments

//void
- (void) voidNoArgs;
//object
- (NSString *) alwaysReturnTest;
//char
- (char) alwaysReturnD;
//unsigned char
- (unsigned char) alwaysReturnE;
//bool
- (BOOL) alwaysReturnYES;
//selector
- (SEL) alwaysReturnThisSelector;
//Class
- (Class) alwaysReturnThisClass;
//float
- (float) alwaysReturn5dot2;
//double
- (double) alwaysReturn4dot34222;
//int
- (int) alwaysReturnMinus3231;
//unsigned int
- (unsigned int) alwaysReturn4123;
//short
- (short) alwaysReturnMinus20;
//unsigned short
- (unsigned short) alwaysReturn8;
//long
- (long) alwaysReturnMinus1283129829;
//unsigned long
- (unsigned long) alwaysReturn342452213;
//long long
- (long long) alwaysReturnMinus9218391283;
//unsigned long long
- (unsigned long long) alwaysReturn2983192812;

// 1 argument
//object
- (NSString *) alwaysReturnSpecifiedString:(NSString *)specified;
//char
- (char) alwaysReturnSpecifiedChar:(char)specified;
//unsigned char
- (unsigned char) alwaysReturnSpecifiedUnsignedChar:(unsigned char)specified;
//bool
- (BOOL) alwaysReturnSpecifiedBoolean:(BOOL)specified;
//selector
- (SEL) alwaysReturnSpecifiedSelector:(SEL)specified;
//Class
- (Class) alwaysReturnSpecifiedClass:(Class)specified;
//float
- (float) alwaysReturnSpecifiedFloat:(float)specified;
//double
- (double) alwaysReturnSpecifiedDouble:(double)specified;
//int
- (int) alwaysReturnSpecifiedInt:(int)specified;
//unsigned int
- (unsigned int) alwaysReturnSpecifiedUnsignedInt:(unsigned int)specified;
//short
- (short) alwaysReturnSpecifiedShort:(short)specified;
//unsigned short
- (unsigned short) alwaysReturnSpecifiedUnsignedShort:(unsigned short)specified;
//long
- (long) alwaysReturnSpecifiedLong:(long)specified;
//unsigned long
- (unsigned long) alwaysReturnSpecifiedUnsignedLong:(unsigned long)specified;
//long long
- (long long) alwaysReturnSpecifiedLongLong:(long long)specified;
//unsigned long long
- (unsigned long long) alwaysReturnSpecifiedUnsignedLongLong:(unsigned long long)specified;

// 2 arguments or more
//object
- (NSString *) alwaysReturn:(id)dummy specifiedString:(NSString *)specified;
//char
- (char) alwaysReturn:(id)dummy specifiedChar:(char)specified;
//unsigned char
- (unsigned char) alwaysReturn:(id)dummy specifiedUnsignedChar:(unsigned char)specified;
//bool
- (BOOL) alwaysReturn:(id)dummy specifiedBoolean:(BOOL)specified;
//selector
- (SEL) alwaysReturn:(id)dummy specifiedSelector:(SEL)specified;
//Class
- (Class) alwaysReturn:(id)dummy specifiedClass:(Class)specified;
//float
- (float) alwaysReturn:(id)dummy specifiedFloat:(float)specified;
//double
- (double) alwaysReturn:(id)dummy specifiedDouble:(double)specified;
//int
- (int) alwaysReturn:(id)dummy specifiedInt:(int)specified;
//unsigned int
- (unsigned int) alwaysReturn:(id)dummy specifiedUnsignedInt:(unsigned int)specified;
//short
- (short) alwaysReturn:(id)dummy specifiedShort:(short)specified;
//unsigned short
- (unsigned short) alwaysReturn:(id)dummy specifiedUnsignedShort:(unsigned short)specified;
//long
- (long) alwaysReturn:(id)dummy specifiedLong:(long)specified;
//unsigned long
- (unsigned long) alwaysReturn:(id)dummy specifiedUnsignedLong:(unsigned long)specified;
//long long
- (long long) alwaysReturn:(id)dummy specifiedLongLong:(long long)specified;
//unsigned long long
- (unsigned long long) alwaysReturn:(id)dummy specifiedUnsignedLongLong:(unsigned long long)specified;

@end
