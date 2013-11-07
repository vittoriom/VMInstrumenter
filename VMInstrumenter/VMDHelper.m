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

+ (NSString *) generatePlausibleSelectorNameForSelectorToInstrument:(SEL)selectorToInstrument ofClass:(Class)classToInspect
{
    return [NSStringFromSelector(selectorToInstrument) stringByAppendingFormat:@"_%@_InstrumentedMethod",NSStringFromClass(classToInspect)];
}

+ (NSString *) generatePlausibleSelectorNameForSelectorToSuppress:(SEL)selectorToSuppress ofClass:(Class)classToInspect
{
    return [NSStringFromSelector(selectorToSuppress) stringByAppendingFormat:@"_%@_SuppressedMethod",NSStringFromClass(classToInspect)];
}

@end
