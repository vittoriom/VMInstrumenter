//
//  VMDMethod.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 12/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMDMethod.h"
#import "VMDClass.h"

@implementation VMDMethod {
    Method _method;
}

+ (VMDMethod *) methodWithMethod:(Method)method
{
    if (!method)
        return nil;
    
    VMDMethod *methodToReturn = [VMDMethod new];
    methodToReturn->_method = method;
    
    return methodToReturn;
}

+ (VMDMethod *) methodWithName:(NSString *)methodNameAsString forClass:(Class)classToInspect
{
    VMDClass *wrapper = [VMDClass classWithClass:classToInspect];
    return [self methodWithName:methodNameAsString forVMDClass:wrapper];
}

+ (VMDMethod *) methodWithName:(NSString *)methodNameAsString forVMDClass:(VMDClass *)classToInspect
{
    if(!methodNameAsString || !classToInspect)
        return nil;

    NSArray *methods = [classToInspect methods];
    VMDMethod *foundElement = nil;
    for(VMDMethod *element in methods)
    {
        if([element.name isEqualToString:methodNameAsString])
        {
            foundElement = element;
            break;
        }
    }
    
    return [self methodWithMethod:foundElement.underlyingMethod];
}

- (void) exchangeImplementationWithMethod:(VMDMethod *)newMethod
{
    if(!newMethod || [newMethod isEqual:self])
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:newMethod ? @"Method specified is the same as self" : @"No valid method provided"
                                     userInfo:nil];
    
    method_exchangeImplementations(_method, newMethod.underlyingMethod);
}

- (SEL) selector
{
    SEL selector = method_getName(_method);
    return selector;
}

- (NSString *) name
{
    const char* methodName = sel_getName(self.selector);
    return [NSString stringWithCString:methodName encoding:NSUTF8StringEncoding];
}

- (Method) underlyingMethod
{
    return _method;
}

- (const char *) typeEncoding
{
    return method_getTypeEncoding(_method);
}

- (VMDEncodedType) returnType
{
    char returnType[3];
    method_getReturnType(_method, returnType, 3);
    
    return returnType[0];
}

@end
