//
//  NSInvocation+VMDInstrumenter.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 07/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSInvocation (VMDInstrumenter)

/**
 @param selector the selector you want to set for the NSInvocation object
 @param classToInspect the Class associated to the selector
 @param realSelf the target of the NSInvocation object
 @param args the va_list of arguments the NSInvocation object should take
 @param count the number of arguments in the va_list
 
 @return NSInvocation the NSInvocation object with the specified values
 */
+ (NSInvocation *)invocationForSelector:(SEL)selector ofClass:(Class)classToInspect onRealSelf:(id)realSelf withArgsList:(va_list)args argsCount:(NSInteger)count;

/**
 @see invocationForSelector:ofClass:onRealSelf:withArgsList:argsCount:
 @discussion this method just forwards the call to the above method and then invokes the NSInvocation object
 
 @return NSInvocation the NSInvocation object already invoked
 */
+ (NSInvocation *)createAndInvokeSelector:(SEL)instrumentedSelector withArgsList:(va_list)args argsCount:(NSInteger)count onRealSelf:(id)realSelf withRealSelector:(SEL)realSelector;

@end
