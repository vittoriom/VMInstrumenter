//
//  VMDClass.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 12/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@class VMDMethod;

@interface VMDClass : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSArray *methods;
@property (nonatomic, readonly) NSArray *ivars;
@property (nonatomic, readonly) NSArray *properties;

@property (nonatomic, readonly) Class metaclass;
@property (nonatomic, readonly) Class underlyingClass;

/**
 @param classToInspect the Class you want a wrapper for
 @return VMDClass a wrapper for the specified Class
 */
+ (VMDClass *) classWithClass:(Class)classToInspect;

/**
 @param classNameAsString the name of the class you want to wrap
 @return VMDClass a wrapper for the specified class
 
 @example VMDClass *classExample = [VMDClass classFromString:@"NSURLConnection"];
 */
+ (VMDClass *) classFromString:(NSString *)classNameAsString;

/**
 Adds a new selector with specified implementation to the class
 
 @param selector the SEL you want to add to the class
 @param implementation the IMP of the method you want to add
 @param signature the C string that encodes the signature of the new method
 */
- (void) addMethodWithSelector:(SEL)selector implementation:(IMP)implementation andSignature:(const char*)signature;

/**
 @param selector the selector you want to get the Method from
 @param reason the reason in case the selector doesn't belong to the class
 
 @return VMDMethod the VMDMethod object associated to the specified SEL or nil
 */
- (VMDMethod *) getMethodFromSelector:(SEL)selector orThrowExceptionWithReason:(const NSString *)reason;

/**
 @param selector the SEL you want to get the Method from
 
 @return VMDMethod the VMDMethod object associated to the specified SEL or nil
 */
- (VMDMethod *) getMethodFromClassSelector:(SEL)selector;

/**
 @param selector the SEL you want to get the Method from
 
 @return VMDMethod the VMDMethod object associated to the specified SEL or nil
 */
- (VMDMethod *) getMethodFromInstanceSelector:(SEL)selector;

/**
 @param selector the SEL you are interested in
 
 @return YES if selector is an instance method, NO otherwise
 @discussion Please note that this method will return NO even if the selector doesn't belong to the class
 */
- (BOOL) isInstanceMethod:(SEL)selector;

/**
 @param selector the SEL you are interested in
 
 @return YES if selector is a class method, NO otherwise
 @discussion Please note that this method will return NO even if the selector doesn't belong to the class
 */
- (BOOL) isClassMethod:(SEL)selector;

@end
