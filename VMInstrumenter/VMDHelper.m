//
//  VMDHelper.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 06/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMDHelper.h"
#import "VMDInstrumenter.h"

@implementation VMDHelper

+ (VMDMethodType) typeOfMethodForSelector:(SEL)selector ofClass:(Class)classToInspect
{
    if(class_getInstanceMethod(classToInspect, selector))
        return VMDInstanceMethodType;
    else if(class_getClassMethod(classToInspect, selector))
        return VMDClassMethodType;
    else
        return VMDUnknownMethodType;
}

+ (NSString *) stacktraceForSelector:(SEL)selector ofClass:(Class)classToInspect
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

@end
