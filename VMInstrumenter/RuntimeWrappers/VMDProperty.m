//
//  VMDProperty.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 12/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMDProperty.h"
#import "VMDClass.h"

@implementation VMDProperty {
    objc_property_t _property;
}

+ (VMDProperty *) propertyWithObjectiveCProperty:(objc_property_t)property
{
    if(!property)
        return nil;
    
    VMDProperty *propertyToReturn = [VMDProperty new];
    propertyToReturn->_property = property;
    
    return propertyToReturn;
}

+ (VMDProperty *) propertyWithName:(NSString *)propertyNameAsString forClass:(Class)classToInspect
{
    VMDClass *wrapper = [VMDClass classWithClass:classToInspect];
    return [self propertyWithName:propertyNameAsString forVMDClass:wrapper];
}

+ (VMDProperty *) propertyWithName:(NSString *)propertyNameAsString forVMDClass:(VMDClass *)classToInspect
{
    if(!propertyNameAsString || !classToInspect)
        return nil;
    
    NSArray *properties = [classToInspect properties];
    VMDProperty *foundElement = nil;
    
    for(VMDProperty *element in properties)
    {
        if([element.name isEqualToString:propertyNameAsString])
        {
            foundElement = element;
            break;
        }
    }
    
    return [VMDProperty propertyWithObjectiveCProperty:foundElement.underlyingProperty];
}

- (objc_property_t) underlyingProperty
{
    return _property;
}

- (NSString *) name
{
    const char* propertyName = property_getName(_property);
    return [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding];
}

- (id) valueForObject:(id)object
{
    id value = [object valueForKey:self.name];
    return value;
}

@end
