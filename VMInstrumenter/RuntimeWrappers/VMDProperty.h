//
//  VMDProperty.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 12/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface VMDProperty : NSObject

///The name of the property
@property (nonatomic, readonly) NSString *name;

///The backing property pointer
@property (nonatomic, readonly) objc_property_t underlyingProperty;

/**
 @param the object you want to get the value from
 
 @return id the value of the property for the specified object
 */
- (id) valueForObject:(id)object;

/**
 @param property the property you want to create a wrapper for
 
 @return VMDProperty a VMDProperty wrapper for the specified property  
 */
+ (VMDProperty *) propertyWithObjectiveCProperty:(objc_property_t)property;

@end
