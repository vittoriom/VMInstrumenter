//
//  VMDIvar.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 12/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMDIvar.h"
#import "VMDClass.h"

@implementation VMDIvar {
    Ivar _ivar;
}

+ (VMDIvar *) ivarWithIvar:(Ivar)ivar
{
    if(!ivar)
        return nil;
    
    VMDIvar *ivarObject = [VMDIvar new];
    
    ivarObject->_ivar = ivar;
    
    return ivarObject;
}

+ (VMDIvar *) ivarWithName:(NSString *)ivarNameAsString fromClass:(Class)classToInspect
{
    VMDClass *classWrapper = [VMDClass classWithClass:classToInspect];
    return [self ivarWithName:ivarNameAsString fromVMDClass:classWrapper];
}

+ (VMDIvar *) ivarWithName:(NSString *)ivarNameAsString fromVMDClass:(VMDClass *)classToInspect
{
    if(!ivarNameAsString || !classToInspect)
        return nil;
 
    NSArray *ivars = [classToInspect ivars];
    VMDIvar *foundElement = nil;
    for(VMDIvar *element in ivars)
    {
        if([element.name isEqualToString:ivarNameAsString])
        {
            foundElement = element;
            break;
        }
    }
    
    if(!foundElement)
        return nil;
    
    return [VMDIvar ivarWithIvar:foundElement.underlyingIvar];
}

- (NSString *) name
{
    const char* ivarName = ivar_getName(_ivar);
    return [NSString stringWithCString:ivarName encoding:NSUTF8StringEncoding];
}

- (Ivar) underlyingIvar
{
    return _ivar;
}

- (id) valueForObject:(id)object
{
    return object_getIvar(object, _ivar);
}

- (char) charValueForObject:(id)object
{
    return ((char (*)(id, Ivar))object_getIvar)(object, _ivar);
}

- (NSInteger) intValueForObject:(id)object
{
    return ((NSInteger (*)(id, Ivar))object_getIvar)(object, _ivar);
}

- (Class) classValueForObject:(id)object
{
    return ((Class (*)(id, Ivar))object_getIvar)(object, _ivar);
}

- (long long) longValueForObject:(id)object
{
    return ((long long (*)(id, Ivar))object_getIvar)(object, _ivar);
}

- (BOOL) boolValueForObject:(id)object
{
    return ((BOOL (*)(id, Ivar))object_getIvar)(object, _ivar);
}

- (VMDEncodedType) type
{
    return ivar_getTypeEncoding(_ivar)[0];
}

@end
