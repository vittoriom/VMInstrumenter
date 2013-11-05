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
+ (char) typeOfArgumentInSignature:(NSMethodSignature *)signature atIndex:(NSUInteger)index;

- (NSInvocation *)invocationForSelector:(SEL)selector withArgsList:(va_list)args argsCount:(NSInteger)count;
- (NSInvocation *) createAndInvokeSelector:(SEL)instrumentedSelector withArgsList:(va_list)args argsCount:(NSInteger)count onRealSelf:(id)realSelf withRealSelector:(SEL)realSelector;

@end

@implementation VMDInstrumenter

#pragma mark - Private methods and helpers

+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToInstrument:(SEL)selectorToInstrument
{
    return [NSStringFromSelector(selectorToInstrument) stringByAppendingFormat:@"_VMDInstrumenter_InstrumentedMethod"];
}

+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToSuppress:(SEL)selectorToSuppress
{
    return [NSStringFromSelector(selectorToSuppress) stringByAppendingFormat:@"_VMDInstrumenter_SuppressedMethod"];
}

#pragma mark Invocation related methods

- (NSInvocation *) createAndInvokeSelector:(SEL)instrumentedSelector withArgsList:(va_list)args argsCount:(NSInteger)count onRealSelf:(id)realSelf withRealSelector:(SEL)realSelector
{
    NSInvocation *invocation = [self invocationForSelector:instrumentedSelector withArgsList:args argsCount:count];
    
    [invocation invoke];
    
    return invocation;
}

- (NSInvocation *)invocationForSelector:(SEL)selector withArgsList:(va_list)args argsCount:(NSInteger)count
{
    NSMethodSignature *signature = [[self class] NSMethodSignatureForSelector:selector ofClass:[self class]];
    NSInvocation *invocationObject = [NSInvocation invocationWithMethodSignature:signature];
    [invocationObject setTarget:self];
    [invocationObject setSelector:selector];
    
    int index = 2;
    for (int i=0; i<count;i++)
    {
        char type = [[self class] typeOfArgumentInSignature:signature atIndex:index];
        
        switch (type) {
            case '@':
            {
                id object = va_arg(args, id);
                [invocationObject setArgument:&object atIndex:index];
            }
                break;
            //All these types get promoted to int anyway when calling va_arg
            case 'S':
            case 'c':
            case 'i':
            case 'C':
            case 'B':
            case 's':
            {
                NSInteger number = va_arg(args, int);
                [invocationObject setArgument:&number atIndex:index];
            }
                break;
            case 'v': //Can it be?
                break;
            case 'l':
            {
                long number = va_arg(args, long);
                [invocationObject setArgument:&number atIndex:index];
            }
                break;
            case 'q':
            {
                long long number = va_arg(args, long long);
                [invocationObject setArgument:&number atIndex:index];
            }
                break;
            case 'I':
            {
                unsigned int number = va_arg(args,unsigned int);
                [invocationObject setArgument:&number atIndex:index];
            }
                break;
            case 'L':
            {
                unsigned long number = va_arg(args, unsigned long);
                [invocationObject setArgument:&number atIndex:index];
            }
                break;
            case 'Q':
            {
                unsigned long long number = va_arg(args, unsigned long long);
                [invocationObject setArgument:&number atIndex:index];
            }
                break;
            case 'f':
            case 'd':
            {
                double number = va_arg(args, double);
                [invocationObject setArgument:&number atIndex:index];
            }
                break;
            case ':':
            {
                SEL selector = va_arg(args, SEL);
                [invocationObject setArgument:&selector atIndex:index];
            }
                break;
            case '#':
            {
                Class class = va_arg(args, Class);
                [invocationObject setArgument:&class atIndex:index];
            }
                break;
            default:
                break;
        }
        
        index++;
    }
    return invocationObject;
}

#pragma mark Signature related methods

+ (char) typeOfArgumentInSignature:(NSMethodSignature *)signature atIndex:(NSUInteger)index
{
    return [signature getArgumentTypeAtIndex:index][0];
}

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
    
    return [signature numberOfArguments] - 2;
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
    NSInteger count = [[self class] numberOfArgumentsForSelector:selectorToInstrument ofClass:clazz];
    
    switch (returnType[0]) {
        case 'v':
        {
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    va_end(args);
                }
                else
                    objc_msgSend(self, instrumentedSelector);                
                
                if(afterBlock)
                    afterBlock();
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case '@':
        {
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock((id)^(id realSelf,...){
                if(beforeBlock)
                    beforeBlock();
                
                id result = nil;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
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
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^char(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                char result = 0;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (char)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'C':
        {
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^unsigned char(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned char result = 0;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned char)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'i':
        {
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^int(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                int result = 0;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (int)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 's':
        {
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^short(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                short result = 0;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (short)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'l':
        {
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^long(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                long result = 0l;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (long)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'q':
        {
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^long long(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                long long result = 0ll;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (long long)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'I':
        {
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^unsigned int(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned int result = 0;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned int)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'S':
        {
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^unsigned short(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned short result = 0;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned short)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'L':
        {
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^unsigned long(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned long result = 0l;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned long)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'Q':
        {
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^unsigned long long(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned long long result = 0ll;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (unsigned long long)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'f':
        {
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^float(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                float result = .0f;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = objc_msgSend_fpret(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'd':
        {
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^double(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                double result = .0;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = objc_msgSend_fpret(self, instrumentedSelector);
                
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
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^Class(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                Class result = nil;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (Class)objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [[self class] constCharSignatureForSelector:selectorToInstrument ofClass:clazz]);
        }
            break;
        case 'B':
        {
            class_addMethod(clazz, instrumentedSelector, imp_implementationWithBlock(^BOOL(id realSelf, ...){
                if(beforeBlock)
                    beforeBlock();
                
                BOOL result = NO;
                
                if(count > 0)
                {
                    va_list args;
                    va_start(args, realSelf);
                    
                    NSInvocation *invocation = [self createAndInvokeSelector:instrumentedSelector withArgsList:args argsCount:count onRealSelf:realSelf withRealSelector:selectorToInstrument];
                    
                    [invocation getReturnValue:&result];
                    
                    va_end(args);
                }
                else
                    result = (BOOL)objc_msgSend(self, instrumentedSelector);
                
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
