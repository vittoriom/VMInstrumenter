//
//  NSMethodSignature+VMDInstrumenter.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 07/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "NSMethodSignature+VMDInstrumenter.h"
#import "VMDInstrumenter.h"
#import "VMDHelper.h"
#import <objc/runtime.h>

@implementation NSMethodSignature (VMDInstrumenter)

+ (char) typeOfArgumentInSignature:(NSMethodSignature *)signature atIndex:(NSUInteger)index
{
    return [signature getArgumentTypeAtIndex:index][0];
}

+ (NSMethodSignature *) NSMethodSignatureForSelector:(SEL)selector ofClass:(Class)classToInspect
{
    Method method = [VMDHelper getMethodFromSelector:selector
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

+ (VMDMethodType) typeOfMethodForSelector:(SEL)selector ofClass:(Class)classToInspect
{
    if(class_getInstanceMethod(classToInspect, selector))
        return VMDInstanceMethodType;
    else if(class_getClassMethod(classToInspect, selector))
        return VMDClassMethodType;
    else
        return VMDUnknownMethodType;
}

@end
