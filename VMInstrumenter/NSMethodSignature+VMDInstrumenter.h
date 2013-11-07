//
//  NSMethodSignature+VMDInstrumenter.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 07/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    VMDClassMethodType,
    VMDInstanceMethodType,
    VMDUnknownMethodType
} VMDMethodType;

@interface NSMethodSignature (VMDInstrumenter)

/**
 @param selector the selector you want to get the signature of
 @param classToInspect the Class associated to the selector
 
 @return const char* the encoded signature for the specified selector
 */
+ (const char *) constCharSignatureForSelector:(SEL)selector ofClass:(Class)classToInspect;

/**
 @param selector the selector you want to get the number of argument from
 @param classToInspect the Class associated to the selector
 
 @return NSInteger the number of arguments the selector takes
 @discussion the return value already takes into account the implicit self and _cmd parameters 
 so that they don't contribute to the final result
 */
+ (NSInteger) numberOfArgumentsForSelector:(SEL)selector ofClass:(Class)classToInspect;

/**
 @param selector the selector you want to get the signature for
 @param classToInspect the Class associated to the selector
 
 @return NSMethodSignature the NSMethodSignature object for the specified selector
 */
+ (NSMethodSignature *) methodSignatureForSelector:(SEL)selector ofClass:(Class)classToInspect;

/**
 @param signature the NSMethodSignature object you're interested in
 @param index the index of the argument you want to get the type of
 
 @return char the encoded type of the argument
 */
+ (char) typeOfArgumentInSignature:(NSMethodSignature *)signature atIndex:(NSUInteger)index;

/**
 @param selector the selector you want to get the type of
 @param classToInspect the Class associated to the selector
 
 @return VMDMethodType the type of the selector specified
 
 @discussion this method returns VMDClassMethodType if selector is a class method; 
 VMDInstanceMethodType if selector is an instance method;
 VMDUnknownMethodType if the selector doesn't belong to the specified class
 */
+ (VMDMethodType) typeOfMethodForSelector:(SEL)selector ofClass:(Class)classToInspect;

@end
