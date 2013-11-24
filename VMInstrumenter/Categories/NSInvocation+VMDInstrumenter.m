//
//  NSInvocation+VMDInstrumenter.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 07/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "NSInvocation+VMDInstrumenter.h"
#import "NSMethodSignature+VMDInstrumenter.h"

@implementation NSInvocation (VMDInstrumenter)

+ (NSInvocation *) createAndInvokeSelector:(SEL)selector withArgsList:(va_list)args argsCount:(NSInteger)count onRealSelf:(id)realSelf 
{
    NSInvocation *invocation = [self invocationForSelector:selector ofClass:[realSelf class] onRealSelf:realSelf withArgsList:args argsCount:count];
    [invocation invoke];
    
    return invocation;
}

+ (NSInvocation *)invocationForSelector:(SEL)selector ofClass:(Class)classToInspect onRealSelf:(id)realSelf withArgsList:(va_list)args argsCount:(NSInteger)argsCount
{
    NSMethodSignature *methodSignature = [NSMethodSignature methodSignatureForSelector:selector ofClass:classToInspect];
    NSInvocation *invocationObject = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocationObject setTarget:realSelf];
    [invocationObject setSelector:selector];
    
    int argumentIndex = 2;
    for (int i=0; i<argsCount; i++)
    {
        
        char argumentType = [NSMethodSignature typeOfArgumentInSignature:methodSignature atIndex:argumentIndex];
        
        switch (argumentType) {
            case VMDEncodedTypeObject:
            {
                id object = va_arg(args, id);
                [invocationObject setArgument:&object atIndex:argumentIndex];
            }
                break;
                //All these types get promoted to int anyway when calling va_arg
            case VMDEncodedTypeShort:
            case VMDEncodedTypeChar:
            case VMDEncodedTypeInt:
            case VMDEncodedTypeUnsignedChar:
            case VMDEncodedTypeBool:
            case VMDEncodedTypeUnsignedShort:
            {
                NSInteger number = va_arg(args, NSInteger);
                [invocationObject setArgument:&number atIndex:argumentIndex];
            }
                break;
            case VMDEncodedTypeVoid: //Can it be?
                break;
            case VMDEncodedTypeLong:
            {
                long number = va_arg(args, long);
                [invocationObject setArgument:&number atIndex:argumentIndex];
            }
                break;
            case VMDEncodedTypeLongLong:
            {
                long long number = va_arg(args, long long);
                [invocationObject setArgument:&number atIndex:argumentIndex];
            }
                break;
            case VMDEncodedTypeUnsignedInt:
            {
                unsigned int number = va_arg(args,unsigned int);
                [invocationObject setArgument:&number atIndex:argumentIndex];
            }
                break;
            case VMDEncodedTypeUnsignedLong:
            {
                unsigned long number = va_arg(args, unsigned long);
                [invocationObject setArgument:&number atIndex:argumentIndex];
            }
                break;
            case VMDEncodedTypeUnsignedLongLong:
            {
                unsigned long long number = va_arg(args, unsigned long long);
                [invocationObject setArgument:&number atIndex:argumentIndex];
            }
                break;
            case VMDEncodedTypeFloat:
            case VMDEncodedTypeDouble:
            {
                double number = va_arg(args, double);
                [invocationObject setArgument:&number atIndex:argumentIndex];
            }
                break;
            case VMDEncodedTypeSEL:
            {
                SEL selector = va_arg(args, SEL);
                [invocationObject setArgument:&selector atIndex:argumentIndex];
            }
                break;
            case VMDEncodedTypeClass:
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

@end
