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
#import "VMDClass.h"
#import "VMDIvar.h"
#import "VMDProperty.h"
#import "VMDMethod.h"

@implementation NSObject (VMDInstrumenter)

-(NSString *) dumpInfo
{
    VMDClass *classToInspect = [VMDClass classWithClass:[self class]];
    
    NSMutableArray* ivarArray = [NSMutableArray new];
    for (VMDIvar *ivar in [classToInspect ivars])
    {
        [ivarArray addObject:ivar.name];
    }
    
    NSMutableArray* propertyArray = [NSMutableArray new];
    for (VMDProperty *property in [classToInspect properties])
    {
        [propertyArray addObject:@{ property.name : [property valueForObject:self] }];
    }
    
    NSMutableArray* methodArray = [NSMutableArray new];
    for (VMDMethod *method in [classToInspect methods])
    {
        [methodArray addObject:method.name];
    }
    
    NSDictionary* classDump = @{ @"ivars" : ivarArray,
                                 @"properties" : propertyArray,
                                 @"methods" : methodArray };
    
    return [classDump description];
}

- (NSString *) stacktrace
{
    NSMutableString * backtraceStr = [NSMutableString stringWithString:@"\n"];
    
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
