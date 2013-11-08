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

- (void) instrumentSelector:(SEL)selectorToInstrument forClass:(Class)classToInspect withBeforeBlock:(void(^)())beforeBlock afterBlock:(void(^)())afterBlock dumpingRealSelf:(BOOL)dumpObject;

- (void) instrumentSelector:(SEL)selectorToInstrument forClass:(Class)classToInspect onObject:(id)objectInstance withBeforeBlock:(void(^)())beforeBlock afterBlock:(void(^)())afterBlock dumpingRealSelf:(BOOL)dumpObject;

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

- (void) instrumentSelector:(SEL)selectorToInstrument forClass:(Class)classToInspect withBeforeBlock:(void (^)())executeBefore afterBlock:(void (^)())executeAfter
{
    [self instrumentSelector:selectorToInstrument forClass:classToInspect withBeforeBlock:executeBefore afterBlock:executeAfter dumpingRealSelf:NO];
}

- (void) instrumentSelector:(SEL)selectorToInstrument forObject:(id)objectInstance withBeforeBlock:(void (^)())beforeBlock afterBlock:(void (^)())afterBlock
{
    Class classToInspect = [objectInstance class];
    __weak id objectInstanceWeak = objectInstance;
    [self instrumentSelector:selectorToInstrument forClass:classToInspect onObject:objectInstanceWeak withBeforeBlock:beforeBlock afterBlock:afterBlock dumpingRealSelf:NO];
}

#pragma mark --- Private methods

- (void) instrumentSelector:(SEL)selectorToInstrument forClass:(Class)classToInspect withBeforeBlock:(void (^)())executeBefore afterBlock:(void (^)())executeAfter dumpingRealSelf:(BOOL)dumpObject
{
    [self instrumentSelector:selectorToInstrument forClass:classToInspect onObject:nil withBeforeBlock:executeBefore afterBlock:executeAfter dumpingRealSelf:dumpObject];
}

- (void) instrumentSelector:(SEL)selectorToInstrument forClass:(Class)classToInspect onObject:(id)objectInstance withBeforeBlock:(void (^)())executeBefore afterBlock:(void (^)())executeAfter dumpingRealSelf:(BOOL)dumpObject
{
    NSString *selectorName = NSStringFromSelector(selectorToInstrument);
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
    
    SEL instrumentedSelector = NSSelectorFromString([VMDHelper generatePlausibleSelectorNameForSelectorToInstrument:selectorToInstrument ofClass:classToInspect]);
    
    char returnType[3];
    method_getReturnType(methodToInstrument, returnType, 3);
    NSInteger argsCount = [NSMethodSignature numberOfArgumentsForSelector:selectorToInstrument ofClass:classToInspect];
    
    switch (returnType[0]) {
        case 'v':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    va_end(args);
                }
                else
                    objc_msgSend(realSelf, instrumentedSelector);
                
                if(traceCall && executeAfter)
                    executeAfter();
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case '@':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock((id)^(id realSelf,...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                id result = nil;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                } else
                    result = objc_msgSend(realSelf, instrumentedSelector);
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'c':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^char(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                char result = 0;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (char)objc_msgSend(realSelf, instrumentedSelector);
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'C':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^unsigned char(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                unsigned char result = 0;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned char)objc_msgSend(realSelf, instrumentedSelector);
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'i':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^int(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                int result = 0;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (int)objc_msgSend(realSelf, instrumentedSelector);
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 's':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^short(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                short result = 0;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (short)objc_msgSend(realSelf, instrumentedSelector);
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'l':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^long(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                long result = 0l;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (long)objc_msgSend(realSelf, instrumentedSelector);
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'q':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^long long(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                long long result = 0ll;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (long long)objc_msgSend(realSelf, instrumentedSelector);
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'I':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^unsigned int(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                unsigned int result = 0;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned int)objc_msgSend(realSelf, instrumentedSelector);
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'S':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^unsigned short(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                unsigned short result = 0;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned short)objc_msgSend(realSelf, instrumentedSelector);
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'L':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^unsigned long(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                unsigned long result = 0l;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned long)objc_msgSend(realSelf, instrumentedSelector);
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'Q':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^unsigned long long(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                unsigned long long result = 0ll;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned long long)objc_msgSend(realSelf, instrumentedSelector);
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'f':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^float(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                float result = .0f;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                {
                    float (*action)(id, SEL) = (float (*)(id, SEL)) objc_msgSend;
                    result = action(realSelf, instrumentedSelector);
                }
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'd':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^double(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                double result = .0;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else {
                    double (*action)(id, SEL) = (double (*)(id, SEL)) objc_msgSend;
                    result = action(realSelf, instrumentedSelector);
                }
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case ':':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^SEL(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                SEL result;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else {
                    SEL (*action)(id, SEL) = (SEL (*)(id, SEL)) objc_msgSend;
                    result = action(realSelf, instrumentedSelector);
                }
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case '#':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^Class(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                Class result = nil;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (Class)objc_msgSend(realSelf, instrumentedSelector);
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'B':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^BOOL(id realSelf, ...){
                BOOL traceCall = !objectInstance || (realSelf == objectInstance);
                
                if(traceCall && executeBefore)
                    executeBefore();
                
                BOOL result = NO;
                
                if(traceCall && dumpObject)
                    NSLog(@"%@",[realSelf dumpInfo]);
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [NSInvocation createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (BOOL)objc_msgSend(realSelf, instrumentedSelector);
                
                if(traceCall && executeAfter)
                    executeAfter();
                
                return result;
            }), [NSMethodSignature constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        default:
            raise(11);
            break;
    }
    
    Method instrumentedMethod = [VMDHelper getMethodFromSelector:NSSelectorFromString([VMDHelper generatePlausibleSelectorNameForSelectorToInstrument:selectorToInstrument ofClass:classToInspect])
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
    [self instrumentSelector:selectorToTrace forClass:classToInspect withBeforeBlock:^{
        NSLog(@"%@ - Called selector %@", NSStringFromClass([VMDInstrumenter class]), NSStringFromSelector(selectorToTrace));
        
        if (dumpStack)
        {
            NSLog(@"%@",[self stacktrace]);
        }
    } afterBlock:^{
        NSLog(@"%@ - Finished executing selector %@",NSStringFromClass([VMDInstrumenter class]), NSStringFromSelector(selectorToTrace));
    } dumpingRealSelf:dumpObject];
}

- (void) traceSelector:(SEL)selectorToTrace forObject:(id)objectInstance
{
    [self traceSelector:selectorToTrace forObject:objectInstance dumpingStackTrace:NO dumpingObject:NO];
}

- (void) traceSelector:(SEL)selectorToTrace forObject:(id)objectInstance dumpingStackTrace:(BOOL)dumpStack dumpingObject:(BOOL)dumpObject
{
    __weak id objectInstanceWeak = objectInstance;
    Class classToInspect = [objectInstance class];
    [self instrumentSelector:selectorToTrace forClass:classToInspect onObject:objectInstanceWeak withBeforeBlock:^{
        NSLog(@"%@ - Called selector %@ on %@", NSStringFromClass([VMDInstrumenter class]), NSStringFromSelector(selectorToTrace),objectInstanceWeak);
        
        if (dumpStack)
        {
            NSLog(@"%@",[self stacktrace]);
        }
    } afterBlock:^{
        NSLog(@"%@ - Finished executing selector %@ on %@",NSStringFromClass([VMDInstrumenter class]), NSStringFromSelector(selectorToTrace), objectInstanceWeak);
    } dumpingRealSelf:dumpObject];
}

@end
