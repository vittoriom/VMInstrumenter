//
//  VMDInstrumenter.m
//  VMDInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMDInstrumenter.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <Foundation/NSObjCRuntime.h>
#import "NSObject+VMDInstrumenter.h"
#import "VMDHelper.h"
#import "NSInvocation+VMDInstrumenter.h"
#import "NSMethodSignature+VMDInstrumenter.h"

const NSString * VMDInstrumenterDefaultMethodExceptionReason = @"Trying to get signature for a selector that it's neither instance or class method (?)";

@interface VMDInstrumenter ()

@property (nonatomic, strong) NSMutableArray *suppressedMethods;
@property (nonatomic, strong) NSMutableArray *instrumentedMethods;

- (VMDExecuteBefore) VMDDefaultBeforeBlockForSelector:(SEL)selectorToTrace withTracingOptions:(VMDInstrumenterTracingOptions)options;
- (VMDExecuteAfter) VMDDefaultAfterBlockForSelector:(SEL)selectorToTrace;

- (void) addMethodToClass:(Class)classOrMetaclass forSelector:(SEL)instrumentedSelector withTestBlock:(VMDTestBlock)testBlock beforeBlock: (VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter andOriginalSelector:(SEL)selectorToInstrument ofClass:(Class)classToInspect;

@end

@implementation VMDInstrumenter

#pragma mark - Initialization

- (id) init
{
    self = [super init];
    
    if(self)
    {
#ifndef DEBUG
        NSLog(@"-- Warning: %@ is still enabled and you're not in Debug configuration! --", NSStringFromClass([VMDInstrumenter class]));
#endif
        self.suppressedMethods = [@[] mutableCopy];
        self.instrumentedMethods = [@[] mutableCopy];
    }
    
    return self;
}

+ (instancetype) sharedInstance
{
    static VMDInstrumenter *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [VMDInstrumenter new];
    });
    
    return sharedInstance;
}

#pragma mark - Public API

#pragma mark -- Suppressing selectors

- (void) suppressSelector:(SEL)selectorToSuppress forClass:(Class)classToInspect
{
    NSString *selectorName = NSStringFromSelector(selectorToSuppress);
    NSString *plausibleSuppressedSelectorName = [VMDHelper generatePlausibleSelectorNameForSelectorToSuppress:selectorToSuppress ofClass:classToInspect];
    
    if([self.suppressedMethods containsObject:plausibleSuppressedSelectorName])
    {
        NSLog(@"%@ - Warning: The SEL %@ is already suppressed", NSStringFromClass([VMDInstrumenter class]), selectorName);
        return;
    }
    
    Method originalMethod = [VMDHelper getMethodFromSelector:selectorToSuppress
                                                           ofClass:classToInspect
                                        orThrowExceptionWithReason:@"Trying to suppress a selector that it's neither instance or class method (?)"];
    
    SEL newSelector = NSSelectorFromString(plausibleSuppressedSelectorName);
   
    class_addMethod([self class], newSelector, imp_implementationWithBlock(^(){}), "v@:");
    
    Method replacedMethod = class_getInstanceMethod([self class], newSelector);
    
    method_exchangeImplementations(originalMethod, replacedMethod);
    
    [self.suppressedMethods addObject:plausibleSuppressedSelectorName];
}

- (void) restoreSelector:(SEL)selectorToRestore forClass:(Class)classToInspect
{
    NSString *selectorName = NSStringFromSelector(selectorToRestore);
    NSString *plausibleSuppressedSelectorName = [VMDHelper generatePlausibleSelectorNameForSelectorToSuppress:selectorToRestore ofClass:classToInspect];
    
    if(![self.suppressedMethods containsObject:plausibleSuppressedSelectorName])
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"%@ - Warning: The SEL %@ is not suppressed", NSStringFromClass([VMDInstrumenter class]), NSStringFromSelector(selectorToRestore)]
                                     userInfo:@{
                                                @"error" : @"selector is not suppressed",
                                                @"info" : selectorName
                                                }];
        return;
    }
    
    Method originalMethod = class_getInstanceMethod([self class], NSSelectorFromString(plausibleSuppressedSelectorName));
    
    Method replacedMethod = [VMDHelper getMethodFromSelector:selectorToRestore
                                                           ofClass:classToInspect
                                        orThrowExceptionWithReason:@"Trying to restore a selector that it's neither instance or class method (?)"];
    
    method_exchangeImplementations(originalMethod, replacedMethod);
    
    [self.suppressedMethods removeObject:plausibleSuppressedSelectorName];
}

#pragma mark -- Replacing selectors

- (void) replaceSelector:(SEL)sel1 ofClass:(Class)class1 withSelector:(SEL)sel2 ofClass:(Class)class2
{
    Method originalMethod = [VMDHelper getMethodFromSelector:sel1
                                                           ofClass:class1
                                        orThrowExceptionWithReason:@"Trying to replace selector that it's neither instance or class method (?)"];
    
    Method replacedMethod = [VMDHelper getMethodFromSelector:sel2
                                                           ofClass:class2
                                        orThrowExceptionWithReason:@"Trying to replace selector that it's neither instance or class method (?)"];
    
    method_exchangeImplementations(originalMethod, replacedMethod);
}

#pragma mark -- Instrumenting selectors

- (void) instrumentSelector:(SEL)selectorToInstrument forClass:(Class)classToInspect withBeforeBlock:(VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter
{
    [self instrumentSelector:selectorToInstrument forInstancesOfClass:classToInspect passingTest:nil withBeforeBlock:executeBefore afterBlock:executeAfter];
}

- (void) instrumentSelector:(SEL)selectorToInstrument forObject:(id)objectInstance withBeforeBlock:(VMDExecuteBefore)beforeBlock afterBlock:(VMDExecuteAfter)afterBlock
{
    Class classToInspect = [objectInstance class];
    __weak id objectInstanceWeak = objectInstance;
    [self instrumentSelector:selectorToInstrument forInstancesOfClass:classToInspect passingTest:^BOOL(id instance) {
        return instance == objectInstanceWeak;
    } withBeforeBlock:beforeBlock afterBlock:afterBlock];
}

- (void) instrumentSelector:(SEL)selectorToInstrument forInstancesOfClass:(Class)classToInspect passingTest:(VMDTestBlock)testBlock withBeforeBlock:(VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter
{
    NSString *selectorName = NSStringFromSelector(selectorToInstrument);
    NSString *instrumentedSelectorName = [VMDHelper generatePlausibleSelectorNameForSelectorToInstrument:selectorToInstrument ofClass:classToInspect];
    SEL instrumentedSelector = NSSelectorFromString(instrumentedSelectorName);
    
    if([self.instrumentedMethods containsObject:selectorName])
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"%@ - Selector is already instrumented", NSStringFromClass([VMDInstrumenter class])]
                                     userInfo:@{
                                                @"error" : @"Selector already instrumented",
                                                @"info" : selectorName
                                                }];
        return;
    }
    
    Class classOrMetaclass = classToInspect;
    
    Method methodToInstrument = class_getInstanceMethod(classToInspect, selectorToInstrument);
    if(!methodToInstrument)
    {
        methodToInstrument = class_getClassMethod(classToInspect, selectorToInstrument);
        classOrMetaclass = object_getClass(classToInspect);
    }
    
    if(!methodToInstrument)
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"%@ - Trying to instrument a selector that it's neither instance or class method (?)",NSStringFromClass([VMDInstrumenter class])]
                                     userInfo:@{
                                                @"error" : @"Unknown type of selector",
                                                @"info" : NSStringFromSelector(selectorToInstrument)
                                                }];
    }
    
    [self addMethodToClass:classOrMetaclass forSelector:instrumentedSelector withTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter andOriginalSelector:selectorToInstrument ofClass:classToInspect];
    
    Method instrumentedMethod = [VMDHelper getMethodFromSelector:instrumentedSelector
                                                               ofClass:classToInspect
                                            orThrowExceptionWithReason:@"Something weird happened during the instrumentation"];
    
    method_exchangeImplementations(methodToInstrument, instrumentedMethod);
    
    [self.instrumentedMethods addObject:selectorName];
}

#pragma mark -- Tracing selectors

- (void) _traceSelector:(SEL)selectorToTrace forInstancesOfClass:(Class)classToInspect passingTest:(VMDTestBlock)testBlock withBeforeBlock:(VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter withTracingOptions:(VMDInstrumenterTracingOptions)options
{
    BOOL traceTime = options & VMDInstrumenterTraceExecutionTime;
    
    __block NSDate *before = nil;
    [self instrumentSelector:selectorToTrace
         forInstancesOfClass:classToInspect
                 passingTest:testBlock
             withBeforeBlock:^(id instance){
                        VMDExecuteBefore defaultBeforeBlock = [self VMDDefaultBeforeBlockForSelector:selectorToTrace withTracingOptions:options];
                        if(defaultBeforeBlock)
                            defaultBeforeBlock(instance);
                        if(traceTime)
                            before = [NSDate date];
                  }
                  afterBlock:^(id instance){
                      if(before)
                      {
                          NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:before];
                          NSLog(@"Execution time for the selector %@ on %@ : %f", NSStringFromSelector(selectorToTrace), instance, elapsed);
                      }
                      
                      VMDExecuteAfter defaultAfterBlock = [self VMDDefaultAfterBlockForSelector:selectorToTrace];
                      if(defaultAfterBlock)
                          defaultAfterBlock(instance);
                  }];
}

- (void) traceSelector:(SEL)selectorToTrace forClass:(Class)classToInspect
{
    [self traceSelector:selectorToTrace forClass:classToInspect withTracingOptions:VMDInstrumenterTracingOptionsNone];
}

- (void) traceSelector:(SEL)selectorToTrace forClass:(Class)classToInspect withTracingOptions:(VMDInstrumenterTracingOptions)options;
{
    [self _traceSelector:selectorToTrace
     forInstancesOfClass:classToInspect
             passingTest:nil
         withBeforeBlock:[self VMDDefaultBeforeBlockForSelector:selectorToTrace withTracingOptions:options]
              afterBlock:[self VMDDefaultAfterBlockForSelector:selectorToTrace]
       withTracingOptions:options];
}

- (void) traceSelector:(SEL)selectorToTrace forObject:(id)objectInstance
{
    [self traceSelector:selectorToTrace forObject:objectInstance withTracingOptions:VMDInstrumenterTracingOptionsNone];
}

- (void) traceSelector:(SEL)selectorToTrace forObject:(id)objectInstance withTracingOptions:(VMDInstrumenterTracingOptions)options;
{
    __weak id objectInstanceWeak = objectInstance;
    Class classToInspect = [objectInstance class];
    
    [self _traceSelector:selectorToTrace
     forInstancesOfClass:classToInspect
             passingTest:^BOOL(id instance) {
                 return instance == objectInstanceWeak;
             }
         withBeforeBlock:[self VMDDefaultBeforeBlockForSelector:selectorToTrace withTracingOptions:options]
              afterBlock:[self VMDDefaultAfterBlockForSelector:selectorToTrace]
       withTracingOptions:options];
}

- (void) traceSelector:(SEL)selectorToTrace forInstancesOfClass:(Class)classToInspect passingTest:(VMDTestBlock)testBlock
{
    [self traceSelector:selectorToTrace forInstancesOfClass:classToInspect passingTest:testBlock withTracingOptions:VMDInstrumenterTracingOptionsNone];
}

- (void) traceSelector:(SEL)selectorToTrace forInstancesOfClass:(Class)classToInspect passingTest:(VMDTestBlock)testBlock withTracingOptions:(VMDInstrumenterTracingOptions)options;
{
    [self _traceSelector:selectorToTrace
     forInstancesOfClass:classToInspect
             passingTest:testBlock
         withBeforeBlock:[self VMDDefaultBeforeBlockForSelector:selectorToTrace withTracingOptions:options]
              afterBlock:[self VMDDefaultAfterBlockForSelector:selectorToTrace]
       withTracingOptions:options];
}

#pragma mark - Default tracing blocks

- (VMDExecuteBefore) VMDDefaultBeforeBlockForSelector:(SEL)selectorToTrace withTracingOptions:(VMDInstrumenterTracingOptions)options
{
    BOOL dumpStack = options & VMDInstrumenterDumpStacktrace;
    BOOL dumpObject = options & VMDInstrumenterDumpObject;
    
    return ^(id instance) {
        NSLog(@"%@ - Called selector %@ on %@", NSStringFromClass([VMDInstrumenter class]), NSStringFromSelector(selectorToTrace), instance);
        
        if (dumpStack) {
            NSLog(@"Executing on thread %@ (%@)",[NSThread currentThread], [NSThread isMainThread] ? @"Main thread" : @"Not main thread");
            NSLog(@"%@",[instance stacktrace]);
        }
        if (dumpObject) {
            NSLog(@"%@",[instance dumpInfo]);
        }
    };
}

- (VMDExecuteAfter) VMDDefaultAfterBlockForSelector:(SEL)selectorToTrace
{
    return ^(id instance) {
        NSLog(@"%@ - Finished executing selector %@ on %@",NSStringFromClass([VMDInstrumenter class]), NSStringFromSelector(selectorToTrace), instance);
    };
}

#pragma mark - Private helpers

- (void) addMethodToClass:(Class)classOrMetaclass forSelector:(SEL)instrumentedSelector withTestBlock:(VMDTestBlock)testBlock beforeBlock:(VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter andOriginalSelector:(SEL)selectorToInstrument ofClass:(Class)classToInspect
{
    Method methodToInstrument = [VMDHelper getMethodFromSelector:selectorToInstrument ofClass:classToInspect orThrowExceptionWithReason:VMDInstrumenterDefaultMethodExceptionReason];
    
    char returnType[3];
    method_getReturnType(methodToInstrument, returnType, 3);
    NSInteger argsCount = [NSMethodSignature numberOfArgumentsForSelector:selectorToInstrument ofClass:classToInspect];
    
    IMP methodImplementation = [self VMDImplementationForReturnType:returnType[0]
                                                      withTestBlock:testBlock
                                                        beforeBlock:executeBefore
                                                         afterBlock:executeAfter
                                            forInstrumentedSelector:instrumentedSelector
                                                       andArgsCount:argsCount];
    const char * methodSignature = [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect];
    
    class_addMethod(classOrMetaclass, instrumentedSelector, methodImplementation, methodSignature);
}

- (IMP) VMDImplementationForReturnType:(char)returnType withTestBlock:(VMDTestBlock)testBlock beforeBlock:(VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter forInstrumentedSelector:(SEL)instrumentedSelector andArgsCount:(NSInteger)argsCount
{
    id implementationBlock = nil;
    switch (returnType) {
        case 'v':
            implementationBlock = [self VMDImplementationBlockForVoidReturnTypeWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector andArgsCount:argsCount];
            break;
        case '@':
            implementationBlock = [self VMDImplementationBlockForObjectReturnTypeWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector andArgsCount:argsCount];
            break;
        case 'B':
        case 'c':
        case 'C':
        case 'i':
        case 'I':
        case 'l':
        case 'L':
        case 'q':
        case 'Q':
        case 's':
        case 'S':
            implementationBlock = [self VMDImplementationBlockForIntegerReturnTypeWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector andArgsCount:argsCount];
            break;
        case 'f':
            implementationBlock = [self VMDImplementationBlockForFloatReturnTypeWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector andArgsCount:argsCount];
            break;
        case 'd':
            implementationBlock = [self VMDImplementationBlockForDoubleReturnTypeWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector andArgsCount:argsCount];
            break;
        case ':':
            implementationBlock = [self VMDImplementationBlockForSELReturnTypeWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector andArgsCount:argsCount];
            break;
        case '#':
            implementationBlock = [self VMDImplementationBlockForClassReturnTypeWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector andArgsCount:argsCount];
            break;
        default:
            raise(11);
    }
    
    return imp_implementationWithBlock(implementationBlock);
}

- (NSInvocation *) preprocessAndPostprocessCallWithTestBlock:(VMDTestBlock)testBlock beforeBlock:(VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter forInstrumentedSelector:(SEL)instrumentedSelector withArgs:(va_list)args argsCount:(NSInteger)argsCount onRealSelf:(id)realSelf
{
    BOOL traceCall = !testBlock || testBlock(realSelf);
    
    if(traceCall && executeBefore)
        executeBefore(realSelf);
    
    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf];
    
    if(traceCall && executeAfter)
        executeAfter(realSelf);
    
    return invocation;
}

#pragma mark - IMP Blocks

- (id (^)(id realSelf,...)) VMDImplementationBlockForObjectReturnTypeWithTestBlock:(VMDTestBlock)testBlock beforeBlock:(VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter forInstrumentedSelector:(SEL)instrumentedSelector andArgsCount:(NSInteger)argsCount
{
    return (id)^(id realSelf,...)
    {
        va_list args;
        va_start(args, realSelf);
        NSInvocation *invocation = [self preprocessAndPostprocessCallWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector withArgs:args argsCount:argsCount onRealSelf:realSelf];
        va_end(args);
        
        id result = nil;
        [invocation getReturnValue:&result];
        
        return result;
    };
}

- (unsigned long long (^)(id realSelf,...)) VMDImplementationBlockForIntegerReturnTypeWithTestBlock:(VMDTestBlock)testBlock beforeBlock:(VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter forInstrumentedSelector:(SEL)instrumentedSelector andArgsCount:(NSInteger)argsCount
{
    return (id)^(id realSelf,...)
    {
        va_list args;
        va_start(args, realSelf);
        NSInvocation *invocation = [self preprocessAndPostprocessCallWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector withArgs:args argsCount:argsCount onRealSelf:realSelf];
        va_end(args);
        
        unsigned long long result = 0;
        [invocation getReturnValue:&result];
        
        return result;
    };
}

- (double (^)(id realSelf,...)) VMDImplementationBlockForDoubleReturnTypeWithTestBlock:(VMDTestBlock)testBlock beforeBlock:(VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter forInstrumentedSelector:(SEL)instrumentedSelector andArgsCount:(NSInteger)argsCount
{
    return (id)^(id realSelf,...)
    {
        va_list args;
        va_start(args, realSelf);
        NSInvocation *invocation = [self preprocessAndPostprocessCallWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector withArgs:args argsCount:argsCount onRealSelf:realSelf];
        va_end(args);
        
        double result = .0;
        [invocation getReturnValue:&result];
        
        return result;
    };
}

- (float (^)(id realSelf,...)) VMDImplementationBlockForFloatReturnTypeWithTestBlock:(VMDTestBlock)testBlock beforeBlock:(VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter forInstrumentedSelector:(SEL)instrumentedSelector andArgsCount:(NSInteger)argsCount
{
    return (id)^(id realSelf,...)
    {
        va_list args;
        va_start(args, realSelf);
        NSInvocation *invocation = [self preprocessAndPostprocessCallWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector withArgs:args argsCount:argsCount onRealSelf:realSelf];
        va_end(args);
        
        float result = .0;
        [invocation getReturnValue:&result];
        
        return result;
    };
}

- (SEL (^)(id realSelf,...)) VMDImplementationBlockForSELReturnTypeWithTestBlock:(VMDTestBlock)testBlock beforeBlock:(VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter forInstrumentedSelector:(SEL)instrumentedSelector andArgsCount:(NSInteger)argsCount
{
    return (id)^(id realSelf,...)
    {
        va_list args;
        va_start(args, realSelf);
        NSInvocation *invocation = [self preprocessAndPostprocessCallWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector withArgs:args argsCount:argsCount onRealSelf:realSelf];
        va_end(args);
        
        SEL result;
        [invocation getReturnValue:&result];
        
        return result;
    };
}

- (Class (^)(id realSelf,...)) VMDImplementationBlockForClassReturnTypeWithTestBlock:(VMDTestBlock)testBlock beforeBlock:(VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter forInstrumentedSelector:(SEL)instrumentedSelector andArgsCount:(NSInteger)argsCount
{
    return (id)^(id realSelf,...)
    {
        va_list args;
        va_start(args, realSelf);
        NSInvocation *invocation = [self preprocessAndPostprocessCallWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector withArgs:args argsCount:argsCount onRealSelf:realSelf];
        va_end(args);
        
        Class result = nil;
        [invocation getReturnValue:&result];
        
        return result;
    };
}

- (void (^)(id realSelf,...)) VMDImplementationBlockForVoidReturnTypeWithTestBlock:(VMDTestBlock)testBlock beforeBlock:(VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter forInstrumentedSelector:(SEL)instrumentedSelector andArgsCount:(NSInteger)argsCount
{
    return (id)^(id realSelf,...)
    {
        va_list args;
        va_start(args, realSelf);
        [self preprocessAndPostprocessCallWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector withArgs:args argsCount:argsCount onRealSelf:realSelf];
        va_end(args);
    };
}

@end
