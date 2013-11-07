//
//  NSObject+DumpInfo.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 06/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "NSObject+VMDInstrumenter.h"
#import <objc/runtime.h>
#import <execinfo.h>

@implementation NSObject (VMDInstrumenter)

-(void) dumpInfo
{
    Class clazz = [self class];
    u_int count;
    
    Ivar* ivars = class_copyIvarList(clazz, &count);
    NSMutableArray* ivarArray = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count ; i++)
    {
        const char* ivarName = ivar_getName(ivars[i]);
        [ivarArray addObject:[NSString  stringWithCString:ivarName encoding:NSUTF8StringEncoding]];
    }
    free(ivars);
    
    objc_property_t* properties = class_copyPropertyList(clazz, &count);
    NSMutableArray* propertyArray = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        id value = [self valueForKey:[NSString stringWithUTF8String:propertyName]];
        [propertyArray addObject:@{
                                   [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding]
                                   : value
                                   }];
        
    }
    free(properties);
    
    Method* methods = class_copyMethodList(clazz, &count);
    NSMutableArray* methodArray = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count ; i++)
    {
        SEL selector = method_getName(methods[i]);
        const char* methodName = sel_getName(selector);
        [methodArray addObject:[NSString  stringWithCString:methodName encoding:NSUTF8StringEncoding]];
    }
    free(methods);
    
    NSDictionary* classDump = @{ @"ivars" : ivarArray,
                                 @"properties" : propertyArray,
                                 @"methods" : methodArray };
    
    NSLog(@"%@", classDump);
}

- (NSString *) stacktrace
{
    NSMutableString * backtraceStr = [NSMutableString string];
    
    void *_callstack[128];
    int _frames = backtrace(_callstack, sizeof(_callstack)/sizeof(*_callstack));
    char** strs = backtrace_symbols(_callstack, _frames);
    for (int i = 0; i < _frames; ++i) {
        [backtraceStr appendFormat:@"%s\n", strs[i]];
    }
    free(strs);
    
    return backtraceStr;
}

@end
