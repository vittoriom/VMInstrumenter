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
    return [NSStringFromSelector(selectorToInstrument) stringByAppendingFormat:@"_%@_InstrumentedMethod",NSStringFromClass(classToInspect)];
}

+ (NSString *) generatePlausibleSelectorNameForSelectorToSuppress:(SEL)selectorToSuppress ofClass:(Class)classToInspect
{
    return [NSStringFromSelector(selectorToSuppress) stringByAppendingFormat:@"_%@_SuppressedMethod",NSStringFromClass(classToInspect)];
}

@end
