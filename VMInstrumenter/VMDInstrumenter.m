//
//  VMDInstrumenter.m
//  VMDInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMDInstrumenter.h"
#import <objc/runtime.h>

@interface VMDInstrumenter ()

@property (nonatomic, strong) NSMutableArray *suppressedMethods;
@property (nonatomic, strong) NSMutableArray *instrumentedMethods;

+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToSuppress:(SEL)selectorToSuppress;
+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToInstrument:(SEL)selectorToInstrument;

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
        NSLog(@"VMDInstrumenter - Warning: The SEL %@ is not suppressed", selectorName);
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

- (void) instrumentSelector:(SEL)selectorToInstrument forClass:(Class)clazz withBeforeBlock:(void (^)(void))beforeBlock afterBlock:(void (^)(void))afterBlock
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
    
    if(returnType[0] == 'v')
    {
        class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^(){
            if(beforeBlock)
                beforeBlock();
            
            [self performSelector:instrumentedSelector];
            
            if(afterBlock)
                afterBlock();
        }), "v@:");
    } else if (returnType[0] == '@'){
        class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock((id)^(){
            if(beforeBlock)
                beforeBlock();
            
            id result = [self performSelector:instrumentedSelector];
            
            if(afterBlock)
                afterBlock();
            
            return result;
        }), "@@:");
    } else {
        NSLog(@"VMDInstrumenter - Operation not supported at the moment");
        return;
    }
    
    Method instrumentedMethod = class_getInstanceMethod([self class], NSSelectorFromString([VMDInstrumenter generateRandomPlausibleSelectorNameForSelectorToInstrument:selectorToInstrument]));
    
    method_exchangeImplementations(methodToInstrument, instrumentedMethod);
    
    [self.instrumentedMethods addObject:selectorName];
}

#pragma clang diagnostic pop

- (void) traceSelector:(SEL)selectorToTrace forClass:(Class)clazz
{
    [self instrumentSelector:selectorToTrace forClass:clazz withBeforeBlock:^{
        NSLog(@"VMDInstrumenter - Called selector %@", NSStringFromSelector(selectorToTrace));
    } afterBlock:^{
        NSLog(@"VMDInstrumenter - Finished executing selector %@",NSStringFromSelector(selectorToTrace));
    }];
}

- (void) traceSelector:(SEL)selectorToTrace forClass:(Class)clazz dumpingSelfObject:(BOOL)dumpInfo dumpingStackTrace:(BOOL)dumpStack
{
    // -- TO BE DETERMINED --
}

@end
