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

- (void (^)(id instance)) VMDDefaultBeforeBlockForSelector:(SEL)selectorToTrace dumpingStackTrace:(BOOL)dumpStack dumpingObject:(BOOL)dumpObject;

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
//#warning -- Warning: VMDInstrumenter is still enabled and you're not in Debug configuration! --
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void) instrumentSelector:(SEL)selectorToInstrument forClass:(Class)classToInspect withBeforeBlock:(void (^)(id instance))executeBefore afterBlock:(void (^)(id instance))executeAfter
{
    [self instrumentSelector:selectorToInstrument forInstancesOfClass:classToInspect passingTest:nil withBeforeBlock:executeBefore afterBlock:executeAfter];
}

- (void) instrumentSelector:(SEL)selectorToInstrument forObject:(id)objectInstance withBeforeBlock:(void (^)(id instance))beforeBlock afterBlock:(void (^)(id instance))afterBlock
{
    Class classToInspect = [objectInstance class];
    __weak id objectInstanceWeak = objectInstance;
    [self instrumentSelector:selectorToInstrument forInstancesOfClass:classToInspect passingTest:^BOOL(id instance) {
        return instance == objectInstanceWeak;
    } withBeforeBlock:beforeBlock afterBlock:afterBlock];
}

- (void) instrumentSelector:(SEL)selectorToInstrument forInstancesOfClass:(Class)classToInspect passingTest:(BOOL (^)(id))testBlock withBeforeBlock:(void (^)(id))executeBefore afterBlock:(void (^)(id))executeAfter
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
    
    char returnType[3];
    method_getReturnType(methodToInstrument, returnType, 3);
    NSInteger argsCount = [NSMethodSignature numberOfArgumentsForSelector:selectorToInstrument ofClass:classToInspect];
    
    switch (returnType[0]) {
        case 'v':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^(id realSelf, ...){
                BOOL traceCall = !testBlock || testBlock(realSelf);
                
                if(traceCall && executeBefore)
                    executeBefore(realSelf);
                
                va_list args;
                va_start(args, realSelf);
                [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf];
                
                va_end(args);
            
                if(traceCall && executeAfter)
                    executeAfter(realSelf);
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case '@':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock((id)^(id realSelf,...){
                BOOL traceCall = !testBlock || testBlock(realSelf);
                
                if(traceCall && executeBefore)
                    executeBefore(realSelf);
                
                id result = nil;
                
                va_list args;
                va_start(args, realSelf);
                
                NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf];
                
                [invocation getReturnValue:&result];
                
                va_end(args);
            
                if(traceCall && executeAfter)
                    executeAfter(realSelf);
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'C':
        case 'c':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^char(id realSelf, ...){
                BOOL traceCall = !testBlock || testBlock(realSelf);
                
                if(traceCall && executeBefore)
                    executeBefore(realSelf);
                
                char result = 0;
                
                va_list args;
                va_start(args, realSelf);
                
                NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf];
                
                [invocation getReturnValue:&result];
                
                va_end(args);
            
                if(traceCall && executeAfter)
                    executeAfter(realSelf);
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'i':
        case 's':
        case 'l':
        case 'q':
        case 'I':
        case 'S':
        case 'L':
        case 'Q':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^unsigned long long(id realSelf, ...){
                BOOL traceCall = !testBlock || testBlock(realSelf);
                
                if(traceCall && executeBefore)
                    executeBefore(realSelf);
                
                unsigned long long result = 0ll;
                
                va_list args;
                va_start(args, realSelf);
                
                NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf];
                
                [invocation getReturnValue:&result];
                
                va_end(args);
            
                if(traceCall && executeAfter)
                    executeAfter(realSelf);
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'f':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^float(id realSelf, ...){
                BOOL traceCall = !testBlock || testBlock(realSelf);
                
                if(traceCall && executeBefore)
                    executeBefore(realSelf);
                
                float result = .0f;
                
                va_list args;
                va_start(args, realSelf);
                
                NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf];
                
                [invocation getReturnValue:&result];
                
                va_end(args);
            
                if(traceCall && executeAfter)
                    executeAfter(realSelf);
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'd':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^double(id realSelf, ...){
                BOOL traceCall = !testBlock || testBlock(realSelf);
                
                if(traceCall && executeBefore)
                    executeBefore(realSelf);
                
                double result = .0;
                
                va_list args;
                va_start(args, realSelf);
                
                NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf];
                
                [invocation getReturnValue:&result];
                
                va_end(args);
            
                if(traceCall && executeAfter)
                    executeAfter(realSelf);
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case ':':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^SEL(id realSelf, ...){
                BOOL traceCall = !testBlock || testBlock(realSelf);
                
                if(traceCall && executeBefore)
                    executeBefore(realSelf);
                
                SEL result;
                
                va_list args;
                va_start(args, realSelf);
                
                NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf];
                
                [invocation getReturnValue:&result];
                
                va_end(args);
            
                if(traceCall && executeAfter)
                    executeAfter(realSelf);
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case '#':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^Class(id realSelf, ...){
                BOOL traceCall = !testBlock || testBlock(realSelf);
                
                if(traceCall && executeBefore)
                    executeBefore(realSelf);
                
                Class result = nil;
                
                va_list args;
                va_start(args, realSelf);
                
                NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf];
                
                [invocation getReturnValue:&result];
                
                va_end(args);
            
                if(traceCall && executeAfter)
                    executeAfter(realSelf);
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'B':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^BOOL(id realSelf, ...){
                BOOL traceCall = !testBlock || testBlock(realSelf);
                
                if(traceCall && executeBefore)
                    executeBefore(realSelf);
                
                BOOL result = NO;
                
                va_list args;
                va_start(args, realSelf);
                
                NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf];
                
                [invocation getReturnValue:&result];
                
                va_end(args);
            
                if(traceCall && executeAfter)
                    executeAfter(realSelf);
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        default:
            raise(11);
            break;
    }
    
    Method instrumentedMethod = [VMDHelper getMethodFromSelector:instrumentedSelector
                                                               ofClass:classToInspect
                                            orThrowExceptionWithReason:@"Something weird happened during the instrumentation"];
    
    method_exchangeImplementations(methodToInstrument, instrumentedMethod);
    
    [self.instrumentedMethods addObject:selectorName];
}

#pragma clang diagnostic pop

#pragma mark -- Tracing selectors

- (void) traceSelector:(SEL)selectorToTrace forClass:(Class)classToInspect
{
    [self traceSelector:selectorToTrace forClass:classToInspect dumpingStackTrace:NO dumpingObject:NO];
}

- (void) traceSelector:(SEL)selectorToTrace forClass:(Class)classToInspect dumpingStackTrace:(BOOL)dumpStack dumpingObject:(BOOL)dumpObject
{
    [self instrumentSelector:selectorToTrace
         forInstancesOfClass:classToInspect
                 passingTest:nil
             withBeforeBlock:[self VMDDefaultBeforeBlockForSelector:selectorToTrace dumpingStackTrace:dumpStack dumpingObject:dumpObject]
                  afterBlock:^(id instance){
                      NSLog(@"%@ - Finished executing selector %@ on %@",NSStringFromClass([VMDInstrumenter class]), NSStringFromSelector(selectorToTrace), instance);
                  }];
}

- (void) traceSelector:(SEL)selectorToTrace forObject:(id)objectInstance
{
    [self traceSelector:selectorToTrace forObject:objectInstance dumpingStackTrace:NO dumpingObject:NO];
}

- (void) traceSelector:(SEL)selectorToTrace forObject:(id)objectInstance dumpingStackTrace:(BOOL)dumpStack dumpingObject:(BOOL)dumpObject
{
    __weak id objectInstanceWeak = objectInstance;
    Class classToInspect = [objectInstance class];
    [self instrumentSelector:selectorToTrace
         forInstancesOfClass:classToInspect
                 passingTest:^BOOL(id instance) {
                     return instance == objectInstanceWeak;
                 }
             withBeforeBlock:[self VMDDefaultBeforeBlockForSelector:selectorToTrace dumpingStackTrace:dumpStack dumpingObject:dumpObject]
                  afterBlock:^(id instance){
                      NSLog(@"%@ - Finished executing selector %@ on %@",NSStringFromClass([VMDInstrumenter class]), NSStringFromSelector(selectorToTrace), instance);
                  }];
}

- (void) traceSelector:(SEL)selectorToTrace forInstancesOfClass:(Class)classToInspect passingTest:(BOOL (^)(id))testBlock
{
    [self traceSelector:selectorToTrace forInstancesOfClass:classToInspect passingTest:testBlock dumpingStackTrace:NO dumpingObject:NO];
}

- (void) traceSelector:(SEL)selectorToTrace forInstancesOfClass:(Class)classToInspect passingTest:(BOOL (^)(id))testBlock dumpingStackTrace:(BOOL)dumpStack dumpingObject:(BOOL)dumpObject
{
    [self instrumentSelector:selectorToTrace
         forInstancesOfClass:classToInspect
                 passingTest:testBlock
             withBeforeBlock:[self VMDDefaultBeforeBlockForSelector:selectorToTrace dumpingStackTrace:dumpStack dumpingObject:dumpObject]
                  afterBlock:^(id instance){
                      NSLog(@"%@ - Finished executing selector %@ on %@",NSStringFromClass([VMDInstrumenter class]), NSStringFromSelector(selectorToTrace), instance);
                  }];
}

#pragma mark - Private helpers

- (void (^)(id instance)) VMDDefaultBeforeBlockForSelector:(SEL)selectorToTrace dumpingStackTrace:(BOOL)dumpStack dumpingObject:(BOOL)dumpObject
{
    return ^(id instance) {
        NSLog(@"%@ - Called selector %@ on %@", NSStringFromClass([VMDInstrumenter class]), NSStringFromSelector(selectorToTrace), instance);
        
        if (dumpStack)
        {
            NSLog(@"%@",[instance stacktrace]);
        }
        
        if (dumpObject)
        {
            NSLog(@"%@",[instance dumpInfo]);
        }
    };
}

@end
