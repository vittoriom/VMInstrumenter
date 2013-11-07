//
//  NSInvocation+VMDInstrumenter.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 07/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSInvocation (VMDInstrumenter)

+ (NSInvocation *)invocationForSelector:(SEL)selector ofClass:(Class)classToInspect onRealSelf:(id)realSelf withArgsList:(va_list)args argsCount:(NSInteger)count;
+ (NSInvocation *)createAndInvokeSelector:(SEL)instrumentedSelector withArgsList:(va_list)args argsCount:(NSInteger)count onRealSelf:(id)realSelf withRealSelector:(SEL)realSelector;

@end
