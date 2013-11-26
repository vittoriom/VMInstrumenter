//
//  VMDMethod.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 12/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "NSMethodSignature+VMDInstrumenter.h"

@class VMDClass;

@interface VMDMethod : NSObject

///The selector for this method
@property (nonatomic, readonly) SEL selector;

///The name of the method
@property (nonatomic, readonly) NSString *name;

///The backing Method pointer
@property (nonatomic, readonly) Method underlyingMethod;

///The complete type encoding for the Method
@property (nonatomic, readonly) const char * typeEncoding;

///The encoded return type of the method
@property (nonatomic, readonly) VMDEncodedType returnType;

/**
 @param method the Method pointer 
 
 @return VMDMethod a VMDMethod wrapper for the specified Method
 */
+ (VMDMethod *) methodWithMethod:(Method)method;

/**
 @param methodNameAsString the name of the method you want to wrap
 @param classToInspect the class the method belongs to
 
 @return VMDMethod the method wrapper or nil if no method is found
 
 @example VMDMethod *methodExample = [VMDMethod methodWithName:@"start" forClass:[NSURLConnection class]];
 */
+ (VMDMethod *) methodWithName:(NSString *)methodNameAsString forClass:(Class)classToInspect;

/**
 @param methodNameAsString the name of the method you want to wrap
 @param classToInspect the VMDClass wrapper the method belongs to
 
 @return VMDMethod the method wrapper or nil if no method is found
 */
+ (VMDMethod *) methodWithName:(NSString *)methodNameAsString forVMDClass:(VMDClass *)classToInspect;

/**
 @param method the new Method you want to exchange the implementation with
 */
- (void) exchangeImplementationWithMethod:(VMDMethod *)method;

@end
