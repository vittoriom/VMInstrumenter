//
//  VMDProperty.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 12/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMDProperty.h"

@implementation VMDProperty {
    objc_property_t _property;
}

+ (VMDProperty *) propertyWithObjectiveCProperty:(objc_property_t)property
{
    VMDProperty *propertyToReturn = [VMDProperty new];
    propertyToReturn->_property = property;
    
    return propertyToReturn;
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
