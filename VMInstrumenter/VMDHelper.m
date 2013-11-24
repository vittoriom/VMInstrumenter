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

+ (NSString *) generatePlausibleSelectorNameForSelectorToInstrument:(SEL)selectorToInstrument ofClass:(Class)classToInspect
{
    return [NSStringFromSelector(selectorToInstrument) stringByAppendingFormat:@"_%@_%@_InstrumentedMethod",NSStringFromClass(classToInspect),NSStringFromClass(classToInspect)];
}

+ (NSString *) generatePlausibleSelectorNameForSelectorToSuppress:(SEL)selectorToSuppress ofClass:(Class)classToInspect
{
    return [NSStringFromSelector(selectorToSuppress) stringByAppendingFormat:@"_%@_%@_SuppressedMethod",NSStringFromClass(classToInspect),NSStringFromClass(classToInspect)];
}

+ (NSString *) generatePlausibleSelectorNameForSelectorToProtect:(SEL)selectorToProtect ofClass:(Class)classToInspect
{
    return [NSStringFromSelector(selectorToProtect) stringByAppendingFormat:@"_%@_%@_ProtectedMethod",NSStringFromClass(classToInspect),NSStringFromClass(classToInspect)];
}

@end
