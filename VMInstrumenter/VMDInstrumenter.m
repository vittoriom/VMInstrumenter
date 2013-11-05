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

- (const char *) signatureForReturnValue:(char *)returnValueType;

@end

@implementation VMDInstrumenter

#pragma mark - Private methods

+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToInstrument:(SEL)selectorToInstrument
{
    return [NSStringFromSelector(selectorToInstrument) stringByAppendingFormat:@"_VMInstrumenter_InstrumentedMethod"];
}

+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToSuppress:(SEL)selectorToSuppress
{
    return [NSStringFromSelector(selectorToSuppress) stringByAppendingFormat:@"_VMInstrumenter_SuppressedMethod"];
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
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^(){
                if(beforeBlock)
                    beforeBlock();
                
                objc_msgSend(self, instrumentedSelector);
                
                if(afterBlock)
                    afterBlock();
            }), [self signatureForReturnValue:returnType]);
        }
            break;
        case '@':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock((id)^(){
                if(beforeBlock)
                    beforeBlock();
                
                id result = [self performSelector:instrumentedSelector];
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [self signatureForReturnValue:returnType]);
        }
            break;
        case 'c':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^char(){
                if(beforeBlock)
                    beforeBlock();
                
                char result = (char)[self performSelector:instrumentedSelector];
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [self signatureForReturnValue:returnType]);
        }
            break;
        case 'C':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^unsigned char(){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned char result = (unsigned char)[self performSelector:instrumentedSelector];
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [self signatureForReturnValue:returnType]);
        }
            break;
        case 'i':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^int(){
                if(beforeBlock)
                    beforeBlock();
                
                int result = (int)([self performSelector:instrumentedSelector]);
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [self signatureForReturnValue:returnType]);
        }
            break;
        case 's':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^short(){
                if(beforeBlock)
                    beforeBlock();
                
                short result = (short)[self performSelector:instrumentedSelector];
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [self signatureForReturnValue:returnType]);
        }
            break;
        case 'l':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^long(){
                if(beforeBlock)
                    beforeBlock();
                
                long result = (long)[self performSelector:instrumentedSelector];
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [self signatureForReturnValue:returnType]);
        }
            break;
        case 'q':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^long long(){
                if(beforeBlock)
                    beforeBlock();
                
                long long result = (long long)[self performSelector:instrumentedSelector];
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [self signatureForReturnValue:returnType]);
        }
            break;
        case 'I':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^unsigned int(){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned int result = (unsigned int)[self performSelector:instrumentedSelector];
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [self signatureForReturnValue:returnType]);
        }
            break;
        case 'S':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^unsigned short(){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned short result = (unsigned short)[self performSelector:instrumentedSelector];
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [self signatureForReturnValue:returnType]);
        }
            break;
        case 'L':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^unsigned long(){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned long result = (unsigned long)[self performSelector:instrumentedSelector];
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [self signatureForReturnValue:returnType]);
        }
            break;
        case 'Q':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^unsigned long long(){
                if(beforeBlock)
                    beforeBlock();
                
                unsigned long long result = (unsigned long long)[self performSelector:instrumentedSelector];
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [self signatureForReturnValue:returnType]);
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
            }), [self signatureForReturnValue:returnType]);
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
            }), [self signatureForReturnValue:returnType]);
        }
            break;
        case ':':
            break;
        case '#':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^Class(){
                if(beforeBlock)
                    beforeBlock();
                
                Class result = (Class)[self performSelector:instrumentedSelector];
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [self signatureForReturnValue:returnType]);
        }
            break;
        case 'B':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^BOOL(){
                if(beforeBlock)
                    beforeBlock();
                
                BOOL result = (BOOL)[self performSelector:instrumentedSelector];
                
                if(afterBlock)
                    afterBlock();
                
                return result;
            }), [self signatureForReturnValue:returnType]);
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

- (const char *) signatureForReturnValue:(char *)returnValueType
{
    return strcat(returnValueType, "@:");
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
