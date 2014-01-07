//
//  VMDInstrumenter.h
//  VMDInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>

// constants and typedefs for blocks
extern const NSString * VMDInstrumenterSafetyException;

extern const NSString * VMDInstrumenterDefaultMethodExceptionReason;

typedef void(^VMDExecuteBefore)(id instance);
typedef void(^VMDExecuteAfter)(id instance);
typedef BOOL(^VMDTestBlock)(id instance);
typedef BOOL(^VMDClassTestBlock)(Class callingClass);

typedef NS_OPTIONS(NSUInteger, VMDInstrumenterTracingOptions)
{
    VMDInstrumenterTracingOptionsNone   = 0,
    VMDInstrumenterDumpStacktrace       = 1 << 0,
    VMDInstrumenterDumpObject           = 1 << 1,
    VMDInstrumenterTraceExecutionTime   = 1 << 2,
    VMDInstrumenterTracingOptionsAll    = 7
};

@interface VMDInstrumenter : NSObject

/**
 Access the shared VMDInstrumenter instance
 */
+ (instancetype) sharedInstance;

/**
 Instance methods, public API
 */

/**
 This method suppresses every call to the specified selector of the specified class
 This means that every time someone (also in 3rd party frameworks) makes a call to the selector,
 NOTHING will happen. Be warned
 
 @param selectorToSuppress the selector to suppress
 @param classToInspect the class on which you want to suppress the selector
 
 @discussion If the selector is already suppressed, this method will just throw a warning in the console.
 */
- (void) suppressSelector:(SEL)selectorToSuppress forClass:(Class)classToInspect;

/**
 This method just reverts what suppressSelector:forClass: does
 
 @param selectorToRestore the selector you want to restore
 @param classToInspect the class for which you want to restore the selector
 
 @discussion if the method is not suppressed, this will throw an exception because it means something went wrong at some point
 @throws NSInternalInconsistencyException if the selector is not suppressed
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
 
 @throws NSInternalInconsistencyException If the selector cannot be found in the specified class
 */
- (void) instrumentSelector:(SEL)selectorToInstrument forClass:(Class)classToInspect withBeforeBlock:(VMDExecuteBefore)beforeBlock afterBlock:(VMDExecuteAfter)afterBlock;

/**
 This method instruments calls to a specified selector on a specified object
 with beforeBlock and afterBlock parameters. Specifically, every time the selector is called on the instance,
 beforeBlock is executed before the selector is, and afterBlock is executed after the selector is.
 
 @param selectorToInstrument the selector that you'd like to instrument
 @param objectInstance the instance that gets the selector called on
 @param beforeBlock the block of code to execute before the call to the selector
 @param afterBlock the block of code to execute after the call to the selector
 
 @throws NSInternalInconsistencyException If the selector cannot be found in the class of the specified object
 */
- (void) instrumentSelector:(SEL)selectorToInstrument forObject:(id)objectInstance withBeforeBlock:(VMDExecuteBefore)beforeBlock afterBlock:(VMDExecuteAfter)afterBlock;

/**
 This method instruments calls to a specified selector on a specified object
 with beforeBlock and afterBlock parameters. Specifically, every time the selector is called on the instance,
 beforeBlock is executed before the selector is, and afterBlock is executed after the selector is.
 
 @param selectorToInstrument the selector that you'd like to instrument
 @param classToInspect the class to take the selector from
 @param testBlock the test block that the instances of the class have to pass to be traced
 @param beforeBlock the block of code to execute before the call to the selector
 @param afterBlock the block of code to execute after the call to the selector
 
 @throws NSInternalInconsistencyException If the selector cannot be found in the class of the specified object
 */
- (void) instrumentSelector:(SEL)selectorToInstrument forInstancesOfClass:(Class)classToInspect passingTest:(VMDTestBlock)testBlock withBeforeBlock:(VMDExecuteBefore)beforeBlock afterBlock:(VMDExecuteAfter)afterBlock;

/**
 This method instruments calls to a specified selector of a specified class and just logs execution
 
 You can use more specific methods if you want particular tracing to be done
 
 @param selectorToTrace the selector that you'd like to trace
 @param classToInspect the class to take the selector from
 
 @throws NSInternalInconsistencyException If the selector cannot be found in the specified class
 */
- (void) traceSelector:(SEL)selectorToTrace forClass:(Class)classToInspect;

/**
 This method instruments calls to a specified selector on a specified object
 
 You can use more specific methods if you want particular tracing to be done
 
 @param selectorToTrace the selector that you'd like to trace
 @param objectInstance the instance that gets the selector called on
 
 @throws NSInternalInconsistencyException If the selector cannot be found in the class of the specified object
 */
- (void) traceSelector:(SEL)selectorToTrace forObject:(id)objectInstance;

/**
 This method instruments calls to a specified selector of a specified class
 but only for instances of the class that pass the specified testBlock and just logs execution as the previous method
 
 @param selectorToTrace the selector that you'd like to trace
 @param classToInspect the class to take the selector from
 @param testBlock the test block that the instances of the class have to pass to be traced
 
 @throws NSInternalInconsistencyException If the selector cannot be found in the specified class
 */
- (void) traceSelector:(SEL)selectorToTrace forInstancesOfClass:(Class)classToInspect passingTest:(VMDTestBlock)testBlock;

/**
 This method instruments calls to a specified selector of a specified class and just logs execution as the previous method
 Moreover, if dumpStack is YES, it prints the stack trace after every execution
 
 @param selectorToTrace the selector that you'd like to trace
 @param classToInspect the class to take the selector from
 @param options you can choose what you want apart from tracing here (stacktrace, dump of self object, method execution time)
 
 @throws NSInternalInconsistencyException If the selector cannot be found in the specified class
 */
- (void) traceSelector:(SEL)selectorToTrace forClass:(Class)classToInspect withTracingOptions:(VMDInstrumenterTracingOptions)options;

/**
 This method instruments calls to a specified selector of a specified object and just logs execution as the previous method
 Moreover, if dumpStack is YES, it prints the stack trace after every execution
 
 @param selectorToTrace the selector that you'd like to trace
 @param objectInstance the instance that gets the selector called on
 @param options you can choose what you want apart from tracing here (stacktrace, dump of self object, method execution time)
 
 @throws NSInternalInconsistencyException If the selector cannot be found in the class of the specified object
 */
- (void) traceSelector:(SEL)selectorToTrace forObject:(id)objectInstance withTracingOptions:(VMDInstrumenterTracingOptions)options;

/**
 This method instruments calls to a specified selector of a specified class
 but only for instances of the class that pass the specified testBlock and just logs execution as the previous method
 
 @param selectorToTrace the selector that you'd like to trace
 @param classToInspect the class to take the selector from
 @param testBlock the test block that the instances of the class have to pass to be traced
 @param options you can choose what you want apart from tracing here (stacktrace, dump of self object, method execution time)
 
 @throws NSInternalInconsistencyException If the selector cannot be found in the specified class
 */
- (void) traceSelector:(SEL)selectorToTrace forInstancesOfClass:(Class)classToInspect passingTest:(VMDTestBlock)testBlock withTracingOptions:(VMDInstrumenterTracingOptions)options;

/**
 This method builds a barrier on the specified selector of the specified class, so that
 if any class other than the masterClass calls this selector, an exception is thrown for security reasons
 
 @param selectorToProtect the SEL you want to protect
 @param classToInspect the Class to which the SEL belongs
 @param masterClass the only Class allowed to call the SEL from now on
 
 @throws NSInternalInconsistencyException If the SEL is already protected, or if the SEL cannot be found in the specified Class.
 */
- (void) protectSelector:(SEL)selectorToProtect onClass:(Class)classToInspect fromBeingCalledFromSourcesOtherThanClass:(Class)masterClass;

/**
 This method builds a barrier on the specified selector of the specified class, so that
 if any class other than the masterClasses calls this selector, an exception is thrown for security reasons
 
 @param selectorToProtect the SEL you want to protect
 @param classToInspect the Class to which the SEL belongs
 @param masterClasses an NSArray of the only Classes allowed to call the SEL from now on
 
 @throws NSInternalInconsistencyException If the SEL is already protected, if the SEL cannot be found in the specified Class, or if the NSArray contains non-Class elements.
 */
- (void) protectSelector:(SEL)selectorToProtect onClass:(Class)classToInspect fromBeingCalledFromSourcesOtherThanClasses:(NSArray *)masterClasses;

/**
 This method builds a barrier on the specified selector of the specified class, so that
 if any class that doesn't pass the testBlock calls this selector, an exception is thrown for security reasons
 
 @param selectorToProtect the SEL you want to protect
 @param classToInspect the Class to which the SEL belongs
 @param testBlock the test block the Class calling the SEL should pass to be allowed to call the SEL
 
 @throws NSInternalInconsistencyException If the SEL is already protected, or if the SEL cannot be found in the specified Class.
 */
- (void) protectSelector:(SEL)selectorToProtect onClass:(Class)classToInspect fromBeingCalledFromSourcesOtherThanClassesPassingTest:(VMDClassTestBlock)testBlock;

/*
 @TODO: These methods could be included in the public API, I'm not yet sure if they are useful though. What could the use cases be?

- (void) protectSelectors:(NSArray *)selectorsToProtect onClass:(Class)classToInspect fromBeingCalledFromSourcesOtherThanClass:(Class)masterClass;

- (void) protectSelectors:(NSArray *)selectorsToProtect onClass:(Class)classToInspect fromBeingCalledFromSourcesOtherThanClasses:(NSArray *)masterClasses;

- (void) protectSelectors:(NSArray *)selectorsToProtect onClass:(Class)classToInspect fromBeingCalledFromSourcesOtherThanClassesPassingTest:(VMDClassTestBlock)testBlock;

- (void) protectSelector:(SEL)selectorToProtect onInstance:(id)instanceToInspect fromBeingCalledFromSourcesOtherThanClass:(Class)masterClass;

- (void) protectSelector:(SEL)selectorToProtect onInstance:(id)instanceToInspect fromBeingCalledFromSourcesOtherThanClasses:(NSArray *)masterClasses;

- (void) protectSelector:(SEL)selectorToProtect onInstance:(id)instanceToInspect fromBeingCalledFromSourcesOtherThanClassesPassingTest:(VMDClassTestBlock)testBlock;

- (void) protectSelectors:(NSArray *)selectorsToProtect onInstance:(id)instanceToInspect fromBeingCalledFromSourcesOtherThanClass:(Class)masterClass;

- (void) protectSelectors:(NSArray *)selectorsToProtect onInstance:(id)instanceToInspect fromBeingCalledFromSourcesOtherThanClasses:(NSArray *)masterClasses;

- (void) protectSelectors:(NSArray *)selectorsToProtect onInstance:(id)instanceToInspect fromBeingCalledFromSourcesOtherThanClassesPassingTest:(VMDClassTestBlock)testBlock;
*/

/*
 Probably not going to work: (I have to find a workaround)
 
 - (void) protectSelectors:(NSArray *)selectorsToProtect onInstance:(id)instanceToInspect fromBeingCalledFromSourcesOtherThanInstance:(id)masterInstance;
 
 - (void) protectSelectors:(NSArray *)selectorsToProtect onInstance:(id)instanceToInspect fromBeingCalledFromSourcesOtherThanInstances:(NSArray *)masterInstances;

 - (void) protectSelector:(SEL)selectorToProtect onInstance:(id)instanceToInspect fromBeingCalledFromSourcesOtherThanInstance:(id)masterInstance;
 
 - (void) protectSelector:(SEL)selectorToProtect onInstance:(id)instanceToInspect fromBeingCalledFromSourcesOtherThanInstances:(NSArray *)masterInstances;
 
 - (void) protectSelectors:(NSArray *)selectorsToProtect onClass:(Class)classToInspect fromBeingCalledFromSourcesOtherThanInstance:(id)masterInstance;
 
 - (void) protectSelectors:(NSArray *)selectorsToProtect onClass:(Class)classToInspect fromBeingCalledFromSourcesOtherThanInstances:(NSArray *)masterInstances;
 
 
 - (void) protectSelectors:(NSArray *)selectorsToProtect onClass:(Class)classToInspect fromBeingCalledFromSourcesOtherThanInstance:(id)masterInstance;
 
 - (void) protectSelectors:(NSArray *)selectorsToProtect onClass:(Class)classToInspect fromBeingCalledFromSourcesOtherThanInstances:(NSArray *)masterInstances;
*/
/**
 This method builds a barrier on the specified selector of the specified class, so that
 if any object other than the masterInstance calls this selector, an exception is thrown for security reasons
 
 @param selectorToProtect the SEL you want to protect
 @param classToInspect the Class to which the SEL belongs
 @param allowedInstance the only object allowed to call the SEL from now on
 
 @throws NSInternalInconsistencyException If the SEL is already protected, or if the SEL cannot be found in the specified Class.
 
 @discussion this method performs an exact pointer comparison, so copies of the instance won't be able to call the SEL
 */
/*- (void) protectSelector:(SEL)selectorToProtect onClass:(Class)classToInspect fromBeingCalledFromSourcesOtherThanInstance:(id)allowedInstance;
*/
/**
 This method builds a barrier on the specified selector of the specified class, so that
 if any object not contained in the masterInstances array calls this selector, an exception is thrown for security reasons
 
 @param selectorToProtect the SEL you want to protect
 @param classToInspect the Class to which the SEL belongs
 @param allowedInstances the only objects allowed to call the SEL from now on
 
 @throws NSInternalInconsistencyException If the SEL is already protected, if the SEL cannot be found in the specified Class, or if the NSArray contains non-object elements.
 
 @discussion this method performs an exact pointer comparison, so copies of the instance won't be able to call the SEL
 */
/*- (void) protectSelector:(SEL)selectorToProtect onClass:(Class)classToInspect fromBeingCalledFromSourcesOtherThanInstances:(NSArray *)allowedInstances;
 */

@end
