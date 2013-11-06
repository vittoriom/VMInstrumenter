//
//  VMDInstrumenter.m
//  VMDInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMDInstrumenter.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "NSObject+DumpInfo.h"
#import <execinfo.h>

typedef enum {
    VMDClassMethodType,
    VMDInstanceMethodType,
    VMDUnknownMethodType
} VMDMethodType;

static const NSString * VMDInstrumenterDefaultMethodExceptionReason = @"Trying to get signature for a selector that it's neither instance or class method (?)";

@interface VMDInstrumenter ()

@property (nonatomic, strong) NSMutableArray *suppressedMethods;
@property (nonatomic, strong) NSMutableArray *instrumentedMethods;

+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToSuppress:(SEL)selectorToSuppress ofClass:(Class)classToInspect;
+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToInstrument:(SEL)selectorToInstrument ofClass:(Class)classToInspect;

+ (Method) getMethodFromSelector:(SEL)selector ofClass:(Class)classToInspect orThrowExceptionWithReason:(const NSString *)reason;

+ (const char *) constCharSignatureForSelector:(SEL)selector ofClass:(Class)clazz;
+ (NSInteger) numberOfArgumentsForSelector:(SEL)selector ofClass:(Class)clazz;
+ (NSMethodSignature *) NSMethodSignatureForSelector:(SEL)selector ofClass:(Class)clazz;
+ (char) typeOfArgumentInSignature:(NSMethodSignature *)signature atIndex:(NSUInteger)index;

+ (NSInvocation *)invocationForSelector:(SEL)selector ofClass:(Class)classToInspect onRealSelf:(id)realSelf withArgsList:(va_list)args argsCount:(NSInteger)count;
+ (NSInvocation *)createAndInvokeSelector:(SEL)instrumentedSelector withArgsList:(va_list)args argsCount:(NSInteger)count onRealSelf:(id)realSelf withRealSelector:(SEL)realSelector;
+ (VMDMethodType) typeOfMethodForSelector:(SEL)selector ofClass:(Class)classToInspect;

- (NSString *) stacktraceForSelector:(SEL)selector ofClass:(Class)classToInspect;

- (void) instrumentSelector:(SEL)selectorToInstrument forClass:(Class)classToInspect withBeforeBlock:(void(^)())beforeBlock afterBlock:(void(^)())afterBlock dumpingRealSelf:(BOOL)dumpObject;

@end

@implementation VMDInstrumenter

#pragma mark - Private methods and helpers

+ (VMDMethodType) typeOfMethodForSelector:(SEL)selector ofClass:(Class)classToInspect
{
    if(class_getInstanceMethod(classToInspect, selector))
        return VMDInstanceMethodType;
    else if(class_getClassMethod(classToInspect, selector))
        return VMDClassMethodType;
    else
        return VMDUnknownMethodType;
}

- (NSString *) stacktraceForSelector:(SEL)selector ofClass:(Class)classToInspect
{
    NSMutableString * backtraceStr = [NSMutableString string];
    
    void *_callstack[128];
    int _frames = backtrace(_callstack, sizeof(_callstack)/sizeof(*_callstack));
    char** strs = backtrace_symbols(_callstack, _frames);
    for (int i = 0; i < _frames; ++i) {
        [backtraceStr appendFormat:@"%s\n", strs[i]];
    }
    free(strs);

    return backtraceStr;
}

+ (Method) getMethodFromSelector:(SEL)selector ofClass:(Class)classToInspect orThrowExceptionWithReason:(const NSString *)reason
{
    Method method = class_getInstanceMethod(classToInspect, selector);
    
    if(!method)
    {
        method = class_getClassMethod(classToInspect, selector);
    
        if(!method)
        {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:[NSString stringWithFormat:@"%@ - %@",NSStringFromClass([VMDInstrumenter class]), reason]
                                         userInfo:@{
                                                    @"error" : @"Unknown type of selector",
                                                    @"info" : NSStringFromSelector(selector)
                                                    }];
        }
    }
    
    return method;
}

+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToInstrument:(SEL)selectorToInstrument ofClass:(Class)classToInspect
{
    return [NSStringFromSelector(selectorToInstrument) stringByAppendingFormat:@"_%@_InstrumentedMethod",NSStringFromClass(classToInspect)];
}

+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToSuppress:(SEL)selectorToSuppress ofClass:(Class)classToInspect
{
    return [NSStringFromSelector(selectorToSuppress) stringByAppendingFormat:@"_%@_SuppressedMethod",NSStringFromClass(classToInspect)];
}

#pragma mark Invocation related methods

+ (NSInvocation *) createAndInvokeSelector:(SEL)selector withArgsList:(va_list)args argsCount:(NSInteger)count onRealSelf:(id)realSelf withRealSelector:(SEL)realSelector
{
    NSInvocation *invocation = [self invocationForSelector:selector ofClass:[realSelf class] onRealSelf:realSelf withArgsList:args argsCount:count];
    [invocation invoke];
    
    return invocation;
}

+ (NSInvocation *)invocationForSelector:(SEL)selector ofClass:(Class)classToInspect onRealSelf:(id)realSelf withArgsList:(va_list)args argsCount:(NSInteger)argsCount
{
    NSMethodSignature *methodSignature = [[self class] NSMethodSignatureForSelector:selector ofClass:classToInspect];
    NSInvocation *invocationObject = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocationObject setTarget:realSelf];
    [invocationObject setSelector:selector];
    
    int argumentIndex = 2;
    for (int i=0; i<argsCount; i++)
    {
        char argumentType = [[self class] typeOfArgumentInSignature:methodSignature atIndex:argumentIndex];
        
        switch (argumentType) {
            case '@':
            {
                id object = va_arg(args, id);
                [invocationObject setArgument:&object atIndex:argumentIndex];
            }
                break;
            //All these types get promoted to int anyway when calling va_arg
            case 'S':
            case 'c':
            case 'i':
            case 'C':
            case 'B':
            case 's':
            {
                NSInteger number = va_arg(args, int);
                [invocationObject setArgument:&number atIndex:argumentIndex];
            }
                break;
            case 'v': //Can it be?
                break;
            case 'l':
            {
                long number = va_arg(args, long);
                [invocationObject setArgument:&number atIndex:argumentIndex];
            }
                break;
            case 'q':
            {
                long long number = va_arg(args, long long);
                [invocationObject setArgument:&number atIndex:argumentIndex];
            }
                break;
            case 'I':
            {
                unsigned int number = va_arg(args,unsigned int);
                [invocationObject setArgument:&number atIndex:argumentIndex];
            }
                break;
            case 'L':
            {
                unsigned long number = va_arg(args, unsigned long);
                [invocationObject setArgument:&number atIndex:argumentIndex];
            }
                break;
            case 'Q':
            {
                unsigned long long number = va_arg(args, unsigned long long);
                [invocationObject setArgument:&number atIndex:argumentIndex];
            }
                break;
            case 'f':
            case 'd':
            {
                double number = va_arg(args, double);
                [invocationObject setArgument:&number atIndex:argumentIndex];
            }
                break;
            case ':':
            {
                SEL selector = va_arg(args, SEL);
                [invocationObject setArgument:&selector atIndex:argumentIndex];
            }
                break;
            case '#':
            {
                Class class = va_arg(args, Class);
                [invocationObject setArgument:&class atIndex:argumentIndex];
            }
                break;
            default:
                break;
        }
        
        argumentIndex++;
    }
    
    return invocationObject;
}

#pragma mark Signature related methods

+ (char) typeOfArgumentInSignature:(NSMethodSignature *)signature atIndex:(NSUInteger)index
{
    return [signature getArgumentTypeAtIndex:index][0];
}

+ (NSMethodSignature *) NSMethodSignatureForSelector:(SEL)selector ofClass:(Class)classToInspect
{
    Method method = [self getMethodFromSelector:selector
                                        ofClass:classToInspect
                     orThrowExceptionWithReason:VMDInstrumenterDefaultMethodExceptionReason];
    
    const char * encoding = method_getTypeEncoding(method);
    return [NSMethodSignature signatureWithObjCTypes:encoding];
}

+ (NSInteger) numberOfArgumentsForSelector:(SEL)selector ofClass:(Class)classToInspect
{
    NSMethodSignature * signature = [self NSMethodSignatureForSelector:selector ofClass:classToInspect];
    
    return [signature numberOfArguments] - 2; //0 is self, 1 is _cmd, we only care about real arguments here
}

+ (const char *) constCharSignatureForSelector:(SEL)selector ofClass:(Class)classToInspect
{
    NSMethodSignature * signature = [self NSMethodSignatureForSelector:selector ofClass:classToInspect];
    NSMutableString *signatureBuilder = [[NSMutableString alloc] initWithCapacity:10];
    
    [signatureBuilder appendFormat:@"%s",[signature methodReturnType]];
    for(int i=0; i<[signature numberOfArguments];i++)
    {
        [signatureBuilder appendFormat:@"%s",[signature getArgumentTypeAtIndex:i]];
    }
    
    return [signatureBuilder cStringUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark - Initialization

- (id) init
{
    self = [super init];
    
    if(self)
    {
#ifndef DEBUG
        NSLog(@"-- Warning: %@ is still enabled and you're not in Debug configuration! --", NSStringFromClass([VMDInstrumenter class]));
#warning -- Warning: VMDInstrumenter is still enabled and you're not in Debug configuration! --
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

- (void) suppressSelector:(SEL)selectorToSuppress forClass:(Class)classToInspect
{
    NSString *selectorName = NSStringFromSelector(selectorToSuppress);
    NSString *plausibleSuppressedSelectorName = [VMDInstrumenter generateRandomPlausibleSelectorNameForSelectorToSuppress:selectorToSuppress ofClass:classToInspect];
    
    if([self.suppressedMethods containsObject:plausibleSuppressedSelectorName])
    {
        NSLog(@"%@ - Warning: The SEL %@ is already suppressed", NSStringFromClass([VMDInstrumenter class]), selectorName);
        return;
    }
    
    Method originalMethod = [VMDInstrumenter getMethodFromSelector:selectorToSuppress
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
    NSString *plausibleSuppressedSelectorName = [VMDInstrumenter generateRandomPlausibleSelectorNameForSelectorToSuppress:selectorToRestore ofClass:classToInspect];
    
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
    
    Method replacedMethod = [VMDInstrumenter getMethodFromSelector:selectorToRestore
                                                           ofClass:classToInspect
                                        orThrowExceptionWithReason:@"Trying to restore a selector that it's neither instance or class method (?)"];
    
    method_exchangeImplementations(originalMethod, replacedMethod);
    
    [self.suppressedMethods removeObject:plausibleSuppressedSelectorName];
}

- (void) replaceSelector:(SEL)sel1 ofClass:(Class)class1 withSelector:(SEL)sel2 ofClass:(Class)class2
{
    Method originalMethod = [VMDInstrumenter getMethodFromSelector:sel1
                                                           ofClass:class1
                                        orThrowExceptionWithReason:@"Trying to replace selector that it's neither instance or class method (?)"];
    
    Method replacedMethod = [VMDInstrumenter getMethodFromSelector:sel2
                                                           ofClass:class2
                                        orThrowExceptionWithReason:@"Trying to replace selector that it's neither instance or class method (?)"];
    
    method_exchangeImplementations(originalMethod, replacedMethod);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void) instrumentSelector:(SEL)selectorToInstrument forClass:(Class)classToInspect withBeforeBlock:(void (^)())executeBefore afterBlock:(void (^)())executeAfter
{
    [self instrumentSelector:selectorToInstrument forClass:classToInspect withBeforeBlock:executeBefore afterBlock:executeAfter dumpingRealSelf:NO];
}

- (void) instrumentSelector:(SEL)selectorToInstrument forClass:(Class)classToInspect withBeforeBlock:(void (^)())executeBefore afterBlock:(void (^)())executeAfter dumpingRealSelf:(BOOL)dumpObject
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
    
    SEL instrumentedSelector = NSSelectorFromString([VMDInstrumenter generateRandomPlausibleSelectorNameForSelectorToInstrument:selectorToInstrument ofClass:classToInspect]);
    
    char returnType[3];
    method_getReturnType(methodToInstrument, returnType, 3);
    NSInteger argsCount = [[self class] numberOfArgumentsForSelector:selectorToInstrument ofClass:classToInspect];
    
    switch (returnType[0]) {
        case 'v':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    va_end(args);
                }
                else
                    objc_msgSend(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case '@':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock((id)^(id realSelf,...){
                if(executeBefore)
                    executeBefore();
                
                id result = nil;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                } else
                    result = objc_msgSend(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'c':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^char(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                char result = 0;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (char)objc_msgSend(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'C':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^unsigned char(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                unsigned char result = 0;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned char)objc_msgSend(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'i':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^int(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                int result = 0;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (int)objc_msgSend(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 's':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^short(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                short result = 0;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (short)objc_msgSend(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'l':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^long(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                long result = 0l;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (long)objc_msgSend(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'q':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^long long(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                long long result = 0ll;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (long long)objc_msgSend(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'I':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^unsigned int(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                unsigned int result = 0;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned int)objc_msgSend(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'S':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^unsigned short(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                unsigned short result = 0;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned short)objc_msgSend(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'L':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^unsigned long(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                unsigned long result = 0l;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned long)objc_msgSend(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'Q':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^unsigned long long(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                unsigned long long result = 0ll;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned long long)objc_msgSend(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'f':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^float(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                float result = .0f;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = objc_msgSend_fpret(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'd':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^double(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                double result = .0;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = objc_msgSend_fpret(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case ':':
            break;
        case '#':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^Class(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                Class result = nil;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (Class)objc_msgSend(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        case 'B':
        {
            class_addMethod(classOrMetaclass, instrumentedSelector, imp_implementationWithBlock(^BOOL(id realSelf, ...){
                if(executeBefore)
                    executeBefore();
                
                BOOL result = NO;
                
                if(dumpObject)
                    [realSelf dumpInfo];
                
                if(argsCount > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [VMDInstrumenter createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:argsCount onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (BOOL)objc_msgSend(realSelf, instrumentedSelector);
                
                if(executeAfter)
                    executeAfter();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:classToInspect]);
        }
            break;
        default:
            raise(11);
            break;
    }
    
    Method instrumentedMethod = [VMDInstrumenter getMethodFromSelector:NSSelectorFromString([VMDInstrumenter generateRandomPlausibleSelectorNameForSelectorToInstrument:selectorToInstrument ofClass:classToInspect])
                                                               ofClass:classToInspect
                                            orThrowExceptionWithReason:@"Something weird happened during the instrumentation"];
    
    method_exchangeImplementations(methodToInstrument, instrumentedMethod);
    
    [self.instrumentedMethods addObject:selectorName];
}

#pragma clang diagnostic pop

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
            NSLog(@"%@",[self stacktraceForSelector:selectorToTrace ofClass:classToInspect]);
        }
    } afterBlock:^{
        NSLog(@"%@ - Finished executing selector %@",NSStringFromClass([VMDInstrumenter class]), NSStringFromSelector(selectorToTrace));
    } dumpingRealSelf:dumpObject];
}

@end
