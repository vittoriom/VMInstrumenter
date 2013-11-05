//
//  VMDInstrumenter.m
//  VMDInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMDInstrumenter.h"
#import "NSObject+Dump.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface VMDInstrumenter ()

@property (nonatomic, strong) NSMutableArray *suppressedMethods;
@property (nonatomic, strong) NSMutableArray *instrumentedMethods;

+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToSuppress:(SEL)selectorToSuppress;
+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToInstrument:(SEL)selectorToInstrument;

+ (const char *) constCharSignatureForSelector:(SEL)selector ofClass:(Class)clazz;
+ (NSInteger) numberOfArgumentsForSelector:(SEL)selector ofClass:(Class)clazz;
+ (NSMethodSignature *) NSMethodSignatureForSelector:(SEL)selector ofClass:(Class)clazz;

@end

@implementation VMDInstrumenter

#pragma mark - Private methods

+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToInstrument:(SEL)selectorToInstrument
{
    return [NSStringFromSelector(selectorToInstrument) stringByAppendingFormat:@"_VMDInstrumenter_InstrumentedMethod"];
}

+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToSuppress:(SEL)selectorToSuppress
{
    return [NSStringFromSelector(selectorToSuppress) stringByAppendingFormat:@"_VMDInstrumenter_SuppressedMethod"];
}

#pragma mark - Initialization

- (id) init
{
    self = [super init];
    
    if(self)
    {
        self.suppressedMethods = [@[] mutableCopy];
        self.instrumentedMethods = [@[] mutableCopy];
    }
    
    return self;
}

+ (instancetype) sharedInstance
{
    static VMDInstrumenter *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [VMDInstrumenter new];
    });
    
    return sharedInstance;
}

#pragma mark - Public API

- (void) suppressSelector:(SEL)selectorToSuppress forInstancesOfClass:(Class)clazz
{
    NSString *selectorName = NSStringFromSelector(selectorToSuppress);
    NSString *plausibleSuppressedSelectorName = [VMDInstrumenter generateRandomPlausibleSelectorNameForSelectorToSuppress:selectorToSuppress];
    
    if([self.suppressedMethods containsObject:plausibleSuppressedSelectorName])
    {
        NSLog(@"VMDInstrumenter - Warning: The SEL %@ is already suppressed", selectorName);
        return;
    }
    
    Method originalMethod = class_getInstanceMethod(clazz, selectorToSuppress);
    
    SEL newSelector = NSSelectorFromString(plausibleSuppressedSelectorName);
    
    class_addMethod([self class], newSelector, imp_implementationWithBlock(^(){}), "v@:");
    
    Method replacedMethod = class_getInstanceMethod([self class], newSelector);
    
    method_exchangeImplementations(originalMethod, replacedMethod);
    
    [self.suppressedMethods addObject:plausibleSuppressedSelectorName];
}

- (void) restoreSelector:(SEL)selectorToRestore forInstancesOfClass:(Class)clazz
{
    NSString *selectorName = NSStringFromSelector(selectorToRestore);
    NSString *plausibleSuppressedSelectorName = [VMDInstrumenter generateRandomPlausibleSelectorNameForSelectorToSuppress:selectorToRestore];
    
    if(![self.suppressedMethods containsObject:plausibleSuppressedSelectorName])
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"VMDInstrumenter - Warning: The SEL %@ is not suppressed"
                                     userInfo:@{
                                                @"error" : @"selector is not suppressed",
                                                @"info" : selectorName
                                                }];
        return;
    }
    
    Method originalMethod = class_getInstanceMethod([self class], NSSelectorFromString(plausibleSuppressedSelectorName));
    
    Method replacedMethod = class_getInstanceMethod(clazz, selectorToRestore);
    
    method_exchangeImplementations(originalMethod, replacedMethod);
    
    [self.suppressedMethods removeObject:plausibleSuppressedSelectorName];
}

- (void) replaceSelector:(SEL)sel1 ofClass:(Class)class1 withSelector:(SEL)sel2 ofClass:(Class)class2
{
    Method originalMethod = class_getInstanceMethod(class1, sel1);
    Method replacedMethod = class_getInstanceMethod(class2, sel2);
    
    method_exchangeImplementations(originalMethod, replacedMethod);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void) instrumentSelector:(SEL)selectorToInstrument forClass:(Class)clazz withBeforeBlock:(void (^)())beforeBlock afterBlock:(void (^)())afterBlock
{
    NSString *selectorName = NSStringFromSelector(selectorToInstrument);
    if([self.instrumentedMethods containsObject:selectorName])
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"VMDInstrumenter - Selector is already instrumented"
                                     userInfo:@{
                                                @"error" : @"Selector already instrumented",
                                                @"info" : selectorName
                                                }];
        return;
    }
    
    Method methodToInstrument = class_getInstanceMethod(clazz, selectorToInstrument);
    SEL instrumentedSelector = NSSelectorFromString([VMDInstrumenter generateRandomPlausibleSelectorNameForSelectorToInstrument:selectorToInstrument]);
    
    char returnType[3];
    method_getReturnType(methodToInstrument, returnType, 3);
    
    switch (returnType[0]) {
        case 'v':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                va_list args;
                NSInteger count = [[self class] numberOfArgumentsForSelector:selectorToInstrument ofClass:clazz] - 2;
                
                if(count > 0)
                {
                    va_start(args, realSelf);
                    objc_msgSend(self, instrumentedSelector, args);
                    va_end(args);
                } else
                    objc_msgSend(self, instrumentedSelector);                
                
                if(afterBlock)
                    afterBlock();
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case '@':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock((id)^(id realSelf,...){
                if(beforeBlock)
                    beforeBlock();
                
                id result = nil;
                
                va_list args;
                NSInteger count = [[self class] numberOfArgumentsForSelector:selectorToInstrument ofClass:clazz] - 2;
                
                if(count > 0)
                {
                    va_start(args, realSelf);
                    result = objc_msgSend(self, instrumentedSelector, args);
                    va_end(args);
                    
                } else
                    result = objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'c':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^char(){
                if(beforeBlock)
                    beforeBlock();
                
                char result = (char)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'C':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^unsigned char(){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned char result = (unsigned char)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'i':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^int(){
                if(beforeBlock)
                    beforeBlock();
                
                int result = (int)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 's':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^short(){
                if(beforeBlock)
                    beforeBlock();
                
                short result = (short)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'l':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^long(){
                if(beforeBlock)
                    beforeBlock();
                
                long result = (long)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'q':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^long long(){
                if(beforeBlock)
                    beforeBlock();
                
                long long result = (long long)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'I':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^unsigned int(){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned int result = (unsigned int)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'S':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^unsigned short(){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned short result = (unsigned short)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'L':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^unsigned long(){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned long result = (unsigned long)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'Q':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^unsigned long long(){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned long long result = (unsigned long long)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'f':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^float(){
                if(beforeBlock)
                    beforeBlock();
                
                float result = objc_msgSend_fpret(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'd':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^double(){
                if(beforeBlock)
                    beforeBlock();
                
                double result = objc_msgSend_fpret(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case ':':
            break;
        case '#':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^Class(){
                if(beforeBlock)
                    beforeBlock();
                
                Class result = (Class)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'B':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^BOOL(){
                if(beforeBlock)
                    beforeBlock();
                
                BOOL result = (BOOL)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        default:
            raise(11);
            break;
    }
    
    Method instrumentedMethod = class_getInstanceMethod([self class], NSSelectorFromString([VMDInstrumenter generateRandomPlausibleSelectorNameForSelectorToInstrument:selectorToInstrument]));
    
    method_exchangeImplementations(methodToInstrument, instrumentedMethod);
    
    [self.instrumentedMethods addObject:selectorName];
}

#pragma clang diagnostic pop

+ (NSMethodSignature *) NSMethodSignatureForSelector:(SEL)selector ofClass:(Class)clazz
{
    Method method = class_getInstanceMethod(clazz, selector);
    if(!method)
        method = class_getClassMethod(clazz, selector);
    
    if(!method)
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"VMDInstrumenter - Trying to get signature for a selector that it's neither instance or class method (?)"
                                     userInfo:@{
                                                @"error" : @"Unknown type of selector",
                                                @"info" : NSStringFromSelector(selector)
                                                }];
    }
    
    const char * encoding = method_getTypeEncoding(method);
    return [NSMethodSignature signatureWithObjCTypes:encoding];
}

+ (NSInteger) numberOfArgumentsForSelector:(SEL)selector ofClass:(Class)clazz
{
    NSMethodSignature * signature = [self NSMethodSignatureForSelector:selector ofClass:clazz];
    
    return [signature numberOfArguments];
}

+ (const char *) constCharSignatureForSelector:(SEL)selector ofClass:(Class)clazz
{
    NSMethodSignature * signature = [self NSMethodSignatureForSelector:selector ofClass:clazz];
    NSMutableString *signatureBuilder = [[NSMutableString alloc] initWithCapacity:10];
    
    [signatureBuilder appendFormat:@"%s",[signature methodReturnType]];
    for(int i=0; i<[signature numberOfArguments];i++)
    {
        [signatureBuilder appendFormat:@"%s",[signature getArgumentTypeAtIndex:i]];
    }
    
    return [signatureBuilder cStringUsingEncoding:NSUTF8StringEncoding];
}

- (void) traceSelector:(SEL)selectorToTrace forClass:(Class)clazz
{
    [self traceSelector:selectorToTrace forClass:clazz dumpingStackTrace:NO];
}

- (void) traceSelector:(SEL)selectorToTrace forClass:(Class)clazz dumpingStackTrace:(BOOL)dumpStack
{
    [self instrumentSelector:selectorToTrace forClass:clazz withBeforeBlock:^{
        NSLog(@"VMDInstrumenter - Called selector %@", NSStringFromSelector(selectorToTrace));
        
        if (dumpStack)
        {
            NSLog(@"%@",[NSThread callStackSymbols]);
        }
    } afterBlock:^{
        NSLog(@"VMDInstrumenter - Finished executing selector %@",NSStringFromSelector(selectorToTrace));
    }];
}

@end
