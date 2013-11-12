//
//  VMDMethod.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 12/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMDMethod.h"

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

- (void) exchangeImplementationWithMethod:(VMDMethod *)newMethod
{
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

- (char) returnType
{
    char returnType[3];
    method_getReturnType(_method, returnType, 3);
    
    return returnType[0];
}

@end
