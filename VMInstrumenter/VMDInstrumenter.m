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
#import "VMDClass.h"
#import "VMDMethod.h"
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
    VMDClass *classToInspectWrapper = [VMDClass classWithClass:classToInspect];
    VMDClass *selfClassWrapper = [VMDClass classWithClass:[self class]];
    NSString *selectorName = NSStringFromSelector(selectorToSuppress);
    NSString *plausibleSuppressedSelectorName = [VMDHelper generatePlausibleSelectorNameForSelectorToSuppress:selectorToSuppress ofClass:classToInspect];
    
    if([self.suppressedMethods containsObject:plausibleSuppressedSelectorName])
    {
        NSLog(@"%@ - Warning: The SEL %@ is already suppressed", NSStringFromClass([VMDInstrumenter class]), selectorName);
        return;
    }
    
    VMDMethod *originalMethod = [classToInspectWrapper getMethodFromSelector:selectorToSuppress
                                     orThrowExceptionWithReason:@"Trying to suppress a selector that it's neither instance or class method (?)"];
    
    SEL newSelector = NSSelectorFromString(plausibleSuppressedSelectorName);
   
    [selfClassWrapper addMethodWithSelector:newSelector implementation:imp_implementationWithBlock(^(){}) andSignature:"v@:"];
    
    VMDMethod *replacedMethod = [selfClassWrapper getMethodFromInstanceSelector:newSelector];
    
    [originalMethod exchangeImplementationWithMethod:replacedMethod];
    
    [self.suppressedMethods addObject:plausibleSuppressedSelectorName];
}

- (void) restoreSelector:(SEL)selectorToRestore forClass:(Class)classToInspect
{
    VMDClass *selfClassWrapper = [VMDClass classWithClass:[self class]];
    VMDClass *classToInspectWrapper = [VMDClass classWithClass:classToInspect];
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
    
    VMDMethod *originalMethod = [selfClassWrapper getMethodFromInstanceSelector:NSSelectorFromString(plausibleSuppressedSelectorName)];
    
    VMDMethod *replacedMethod = [classToInspectWrapper getMethodFromSelector:selectorToRestore
                                     orThrowExceptionWithReason:@"Trying to restore a selector that it's neither instance or class method (?)"];
    
    [originalMethod exchangeImplementationWithMethod:replacedMethod];
    
    [self.suppressedMethods removeObject:plausibleSuppressedSelectorName];
}

#pragma mark -- Replacing selectors

- (void) replaceSelector:(SEL)sel1 ofClass:(Class)class1 withSelector:(SEL)sel2 ofClass:(Class)class2
{
    VMDClass *class1Wrapper = [VMDClass classWithClass:class1];
    VMDClass *class2Wrapper = [VMDClass classWithClass:class2];
    VMDMethod *originalMethod = [class1Wrapper getMethodFromSelector:sel1
                                      orThrowExceptionWithReason:@"Trying to replace selector that it's neither instance or class method (?)"];
    
    VMDMethod *replacedMethod = [class2Wrapper getMethodFromSelector:sel2
                                      orThrowExceptionWithReason:@"Trying to replace selector that it's neither instance or class method (?)"];
    
    [originalMethod exchangeImplementationWithMethod:replacedMethod];
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
    VMDClass *classToInspectWrapper = [VMDClass classWithClass:classToInspect];
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
    VMDMethod *methodToInstrument;
    
    if([classToInspectWrapper isClassMethod:selectorToInstrument])
    {
        classOrMetaclass = [classToInspectWrapper metaclass];
        methodToInstrument = [classToInspectWrapper getMethodFromClassSelector:selectorToInstrument];
    } else
        methodToInstrument = [classToInspectWrapper getMethodFromInstanceSelector:selectorToInstrument];
    
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
    
    VMDMethod *instrumentedMethod = [classToInspectWrapper getMethodFromSelector:instrumentedSelector
                                         orThrowExceptionWithReason:@"Something weird happened during the instrumentation"];
    
    [methodToInstrument exchangeImplementationWithMethod:instrumentedMethod];
    
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
    VMDClass *classWrapper = [VMDClass classWithClass:classToInspect];
    VMDMethod *methodToInstrument = [classWrapper getMethodFromSelector:selectorToInstrument
                                         orThrowExceptionWithReason:VMDInstrumenterDefaultMethodExceptionReason];
    
    NSInteger argsCount = [NSMethodSignature numberOfArgumentsForSelector:selectorToInstrument ofClass:classToInspect];
    
    IMP methodImplementation = [self VMDImplementationForReturnType:methodToInstrument.returnType
                                                      withTestBlock:testBlock
                                                        beforeBlock:executeBefore
                                                         afterBlock:executeAfter
                                            forInstrumentedSelector:instrumentedSelector
                                                       andArgsCount:argsCount];
    const char * methodSignature = [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect];
    
    classWrapper = [VMDClass classWithClass:classOrMetaclass];
    [classWrapper addMethodWithSelector:instrumentedSelector implementation:methodImplementation andSignature:methodSignature];
}

- (IMP) VMDImplementationForReturnType:(char)returnType withTestBlock:(VMDTestBlock)testBlock beforeBlock:(VMDExecuteBefore)executeBefore afterBlock:(VMDExecuteAfter)executeAfter forInstrumentedSelector:(SEL)instrumentedSelector andArgsCount:(NSInteger)argsCount
{
    id implementationBlock = nil;
    switch (returnType) {
        case VMDReturnTypeVoid:
            implementationBlock = [self VMDImplementationBlockForVoidReturnTypeWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector andArgsCount:argsCount];
            break;
        case VMDReturnTypeObject:
            implementationBlock = [self VMDImplementationBlockForObjectReturnTypeWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector andArgsCount:argsCount];
            break;
        case VMDReturnTypeBool:
        case VMDReturnTypeChar:
        case VMDReturnTypeUnsignedChar:
        case VMDReturnTypeInt:
        case VMDReturnTypeUnsignedInt:
        case VMDReturnTypeLong:
        case VMDReturnTypeUnsignedLong:
        case VMDReturnTypeLongLong:
        case VMDReturnTypeUnsignedLongLong:
        case VMDReturnTypeShort:
        case VMDReturnTypeUnsignedShort:
            implementationBlock = [self VMDImplementationBlockForIntegerReturnTypeWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector andArgsCount:argsCount];
            break;
        case VMDReturnTypeFloat:
            implementationBlock = [self VMDImplementationBlockForFloatReturnTypeWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector andArgsCount:argsCount];
            break;
        case VMDReturnTypeDouble:
            implementationBlock = [self VMDImplementationBlockForDoubleReturnTypeWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector andArgsCount:argsCount];
            break;
        case VMDReturnTypeSEL:
            implementationBlock = [self VMDImplementationBlockForSELReturnTypeWithTestBlock:testBlock beforeBlock:executeBefore afterBlock:executeAfter forInstrumentedSelector:instrumentedSelector andArgsCount:argsCount];
            break;
        case VMDReturnTypeClass:
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
