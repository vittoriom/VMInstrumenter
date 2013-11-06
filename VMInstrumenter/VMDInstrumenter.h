//
//  VMDInstrumenter.h
//  VMDInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VMDInstrumenter : NSObject

/**
 Of course this is a singleton, no point in doing some other alloc init stuff
 */
+ (instancetype) sharedInstance;

/**
 Instance methods
 */

/**
 This method suppresses every call to the specified selector of the specified class
 This means that every time someone (also in 3rd party frameworks) makes a call to the selector,
 NOTHING will happen. Be warned
 
 @param selectorToSuppress the selector to suppress
 @param classToInspect the class on which you want to suppress the selector
 */
- (void) suppressSelector:(SEL)selectorToSuppress forClass:(Class)classToInspect;

/**
 This method just reverts what suppressSelector:forClass: does
 
 @param selectorToRestore the selector you want to restore
 @param classToInspect the class for which you want to restore the selector
 */
- (void) restoreSelector:(SEL)selectorToRestore forClass:(Class)classToInspect;

/**
 This method replaces the implementation of the two specified selectors from the two specified classes
 
 @discussion From the time you call this method, every call to sel1 will be treated as a call to sel2 and viceversa
 
 @param sel1 the selector to replace
 @param class1 the class where sel1 is taken
 @param sel2 the selector to replace with sel1
 @param class2 the class where sel2 is taken
 */
- (void) replaceSelector:(SEL)sel1 ofClass:(Class)class1 withSelector:(SEL)sel2 ofClass:(Class)class2;

/**
 This method instruments calls to a specified selector of a specified class and does something
 with beforeBlock and afterBlock parameters. Specifically, every time the selector is called on any instance of the class passed,
 beforeBlock is executed before the selector is, and afterBlock is executed after the selector is.
 
 @param selectorToInstrument the selector that you'd like to instrument
 @param classToInspect the class to take the selector from
 @param beforeBlock the block of code to execute before the call to the selector
 @param afterBlock the block of code to execute after the call to the selector
 */
- (void) instrumentSelector:(SEL)selectorToInstrument forClass:(Class)classToInspect withBeforeBlock:(void(^)())beforeBlock afterBlock:(void(^)())afterBlock;

/**
 This method instruments calls to a specified selector of a specified class and just logs execution
 
 You can use more specific methods if you want particular tracing to be done
 
 @param selectorToTrace the selector that you'd like to trace
 @classToInspect the class to take the selector from
 */
- (void) traceSelector:(SEL)selectorToTrace forClass:(Class)classToInspect;

/**
 This method instruments calls to a specified selector of a specified class and just logs execution as the previous method
 Moreover, if dumpStack is YES, it prints the stack trace after every execution
 
 @param selectorToTrace the selector that you'd like to trace
 @classToInspect the class to take the selector from
 */
- (void) traceSelector:(SEL)selectorToTrace forClass:(Class)classToInspect dumpingStackTrace:(BOOL)dumpStack;

@end
