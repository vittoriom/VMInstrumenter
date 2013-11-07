//
//  VMDHelper.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 06/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface VMDHelper : NSObject

+ (NSString *) generatePlausibleSelectorNameForSelectorToSuppress:(SEL)selectorToSuppress ofClass:(Class)classToInspect;
+ (NSString *) generatePlausibleSelectorNameForSelectorToInstrument:(SEL)selectorToInstrument ofClass:(Class)classToInspect;

/**
 @param selector the selector you want to get the Method from
 @param classToInspect the class associated to the selector
 @param reason the reason in case the selector doesn't belong to the class
 
 @return Method the Method object associated to the selector specified
 */
+ (Method) getMethodFromSelector:(SEL)selector ofClass:(Class)classToInspect orThrowExceptionWithReason:(const NSString *)reason;

@end
