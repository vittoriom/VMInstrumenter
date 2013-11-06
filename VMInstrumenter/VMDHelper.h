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
#import <execinfo.h>

typedef enum {
    VMDClassMethodType,
    VMDInstanceMethodType,
    VMDUnknownMethodType
} VMDMethodType;

@interface VMDHelper : NSObject

+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToSuppress:(SEL)selectorToSuppress ofClass:(Class)classToInspect;
+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToInstrument:(SEL)selectorToInstrument ofClass:(Class)classToInspect;

+ (Method) getMethodFromSelector:(SEL)selector ofClass:(Class)classToInspect orThrowExceptionWithReason:(const NSString *)reason;

+ (const char *) constCharSignatureForSelector:(SEL)selector ofClass:(Class)clazz;
+ (NSInteger) numberOfArgumentsForSelector:(SEL)selector ofClass:(Class)clazz;
+ (NSMethodSignature *) NSMethodSignatureForSelector:(SEL)selector ofClass:(Class)clazz;
+ (char) typeOfArgumentInSignature:(NSMethodSignature *)signature atIndex:(NSUInteger)index;

+ (NSInvocation *)invocationForSelector:(SEL)selector ofClass:(Class)classToInspect onRealSelf:(id)realSelf withArgsList:(va_list)args argsCount:(NSInteger)count;
+ (NSInvocation *)createAndInvokeSelector:(SEL)instrumentedSelector withArgsList:(va_list)args argsCount:(NSInteger)count onRealSelf:(id)realSelf withRealSelector:(SEL)realSelector;
+ (VMDMethodType) typeOfMethodForSelector:(SEL)selector ofClass:(Class)classToInspect;

+ (NSString *) stacktraceForSelector:(SEL)selector ofClass:(Class)classToInspect;

@end
