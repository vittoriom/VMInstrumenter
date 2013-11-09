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

- (NSString *) doAndReturnValue:(NSString *)value;

- (NSInteger) doAndReturnPrimitiveValue:(NSInteger)pValue;

- (NSString *) alwaysReturnTest;

- (NSInteger) alwaysReturn3;

- (unsigned int) doAndReturnUnsignedInteger:(unsigned int)param;

- (void) doFoo:(NSString *)foo withMoreThanOneParameter:(NSObject *)second;

- (float) floatTest;

- (double) doubleTest;

- (BOOL) booleanTest;

- (NSString *)doSomethingNewWithThisString:(NSString *)thisStr;

@end
