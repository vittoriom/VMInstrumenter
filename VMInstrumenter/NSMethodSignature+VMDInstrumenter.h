//
//  NSMethodSignature+VMDInstrumenter.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 07/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    VMDClassMethodType,
    VMDInstanceMethodType,
    VMDUnknownMethodType
} VMDMethodType;

@interface NSMethodSignature (VMDInstrumenter)

+ (const char *) constCharSignatureForSelector:(SEL)selector ofClass:(Class)clazz;
+ (NSInteger) numberOfArgumentsForSelector:(SEL)selector ofClass:(Class)clazz;
+ (NSMethodSignature *) NSMethodSignatureForSelector:(SEL)selector ofClass:(Class)clazz;
+ (char) typeOfArgumentInSignature:(NSMethodSignature *)signature atIndex:(NSUInteger)index;
+ (VMDMethodType) typeOfMethodForSelector:(SEL)selector ofClass:(Class)classToInspect;

@end
