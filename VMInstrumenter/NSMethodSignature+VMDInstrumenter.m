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
#import "VMDMethod.h"
#import "VMDClass.h"
#import <objc/runtime.h>

@implementation NSMethodSignature (VMDInstrumenter)

+ (char) typeOfArgumentInSignature:(NSMethodSignature *)signature atIndex:(NSUInteger)index
{
    return [signature getArgumentTypeAtIndex:index][0];
}

+ (NSMethodSignature *) methodSignatureForSelector:(SEL)selector ofClass:(Class)classToInspect
{
    VMDClass *classWrapper = [VMDClass classWithClass:classToInspect];
    VMDMethod *method = [classWrapper getMethodFromSelector:selector
                             orThrowExceptionWithReason:VMDInstrumenterDefaultMethodExceptionReason];
    
    const char * encoding = [method typeEncoding];
    return [NSMethodSignature signatureWithObjCTypes:encoding];
}

+ (NSInteger) numberOfArgumentsForSelector:(SEL)selector ofClass:(Class)classToInspect
{
    NSMethodSignature * signature = [self methodSignatureForSelector:selector ofClass:classToInspect];
    
    return [signature numberOfArguments] - 2; //0 is self, 1 is _cmd, we only care about real arguments here
}

+ (const char *) constCharSignatureForSelector:(SEL)selector ofClass:(Class)classToInspect
{
    NSMethodSignature * signature = [self methodSignatureForSelector:selector ofClass:classToInspect];
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
    VMDClass *classWrapper = [VMDClass classWithClass:classToInspect];
    if([classWrapper isInstanceMethod:selector])
        return VMDInstanceMethodType;
    else if([classWrapper isClassMethod:selector])
        return VMDClassMethodType;
    else
        return VMDUnknownMethodType;
}

@end
