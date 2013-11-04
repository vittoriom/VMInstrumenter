//
//  VMInstrumenter.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMInstrumenter.h"
#import <objc/runtime.h>

@interface VMInstrumenter ()

@property (nonatomic, strong) NSMutableArray *suppressedMethods;

+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToSuppress:(SEL)selectorToSuppress;
+ (NSString *) generateRandomPlausibleSelectorNameForSelectorToInstrument:(SEL)selectorToInstrument;

- (const char *) signatureForReturnValue:(char *)returnValueType;

@end

@implementation VMInstrumenter

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
        //Private properties etc.
        self.suppressedMethods = [@[] mutableCopy];
    }
    
    return self;
}

+ (instancetype) sharedInstance
{
    static VMInstrumenter *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[VMInstrumenter alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark - Public API

- (void) suppressSelector:(SEL)selectorToSuppress forInstancesOfClass:(Class)clazz
{
    NSString *selectorName = NSStringFromSelector(selectorToSuppress);
    NSString *plausibleSuppressedSelectorName = [VMInstrumenter generateRandomPlausibleSelectorNameForSelectorToSuppress:selectorToSuppress];
    
    if([self.suppressedMethods containsObject:plausibleSuppressedSelectorName])
    {
        //log or crash
        NSLog(@"VMInstrumenter - Warning: The SEL %@ is already suppressed", selectorName);
        //NSAssert(false);
        
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
    NSString *plausibleSuppressedSelectorName = [VMInstrumenter generateRandomPlausibleSelectorNameForSelectorToSuppress:selectorToRestore];
    
    if(![self.suppressedMethods containsObject:plausibleSuppressedSelectorName])
    {
        //log or crash
        NSLog(@"VMInstrumenter - Warning: The SEL %@ is not suppressed", selectorName);
        //NSAssert(false);
        
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
    Method methodToInstrument = class_getInstanceMethod(clazz, selectorToInstrument);
    SEL instrumentedSelector = NSSelectorFromString([VMInstrumenter generateRandomPlausibleSelectorNameForSelectorToInstrument:selectorToInstrument]);
    
    char returnType[1];
    method_getReturnType(methodToInstrument, returnType, 1);
    
    switch (returnType[0]) {
        case 'v':
        {
            class_addMethod([self class], instrumentedSelector, imp_implementationWithBlock(^(){
                if(beforeBlock)
                    beforeBlock();
                
                [self performSelector:instrumentedSelector];
                
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
                
                void * fakeR = (__bridge void *)([self performSelector:instrumentedSelector]);
                    
                char result = *(char *)fakeR;
                
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
                
                void * fakeR = (__bridge void *)([self performSelector:instrumentedSelector]);
                
                unsigned char result = *(unsigned char *)fakeR;
                
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
                
                void * fakeR = (__bridge void *)([self performSelector:instrumentedSelector]);
                
                int result = *(int *)fakeR;
                
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
                
                void * fakeR = (__bridge void *)([self performSelector:instrumentedSelector]);
                
                short result = *(short *)fakeR;
                
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
                
                void * fakeR = (__bridge void *)([self performSelector:instrumentedSelector]);
                
                long result = *(long *)fakeR;
                
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
                
                void * fakeR = (__bridge void *)([self performSelector:instrumentedSelector]);
                
                long long result = *(long long *)fakeR;
                
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
                
                void * fakeR = (__bridge void *)([self performSelector:instrumentedSelector]);
                
                unsigned int result = *(unsigned int *)fakeR;
                
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
                
                void * fakeR = (__bridge void *)([self performSelector:instrumentedSelector]);
                
                unsigned short result = *(unsigned short *)fakeR;
                
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
                
                void * fakeR = (__bridge void *)([self performSelector:instrumentedSelector]);
                
                unsigned long result = *(unsigned long *)fakeR;
                
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
                
                void * fakeR = (__bridge void *)([self performSelector:instrumentedSelector]);
                
                unsigned long long result = *(unsigned long long *)fakeR;
                
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
                
                void * fakeR = (__bridge void *)([self performSelector:instrumentedSelector]);
                
                float result = *(float *)fakeR;
                
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
                
                void * fakeR = (__bridge void *)([self performSelector:instrumentedSelector]);
                
                double result = *(double *)fakeR;
                
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
                
                void * fakeR = (__bridge void *)([self performSelector:instrumentedSelector]);
                
                Class result = *(Class *)fakeR;
                
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
                
                void * fakeR = (__bridge void *)([self performSelector:instrumentedSelector]);
                
                BOOL result = *(BOOL *)fakeR;
                
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
    
    Method instrumentedMethod = class_getInstanceMethod([self class], NSSelectorFromString([VMInstrumenter generateRandomPlausibleSelectorNameForSelectorToInstrument:selectorToInstrument]));
    
    method_exchangeImplementations(methodToInstrument, instrumentedMethod);
}

- (const char *) signatureForReturnValue:(char *)returnValueType
{
    return strcat(returnValueType, "@:");
}

#pragma clang diagnostic pop

- (void) traceSelector:(SEL)selectorToTrace forClass:(Class)clazz
{
    [self instrumentSelector:selectorToTrace forClass:clazz withBeforeBlock:^{
        NSLog(@"VMInstrumenter - Called selector %@", NSStringFromSelector(selectorToTrace));
    } afterBlock:^{
        NSLog(@"VMInstrumenter - Finished executing selector %@",NSStringFromSelector(selectorToTrace));
    }];
}

- (void) traceSelector:(SEL)selectorToTrace forClass:(Class)clazz dumpingSelfObject:(BOOL)dumpInfo dumpingStackTrace:(BOOL)dumpStack
{
    // -- TO BE DETERMINED --
}

@end
