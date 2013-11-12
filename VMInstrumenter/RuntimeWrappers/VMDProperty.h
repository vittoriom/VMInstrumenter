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

@property (nonatomic, readonly) NSString *name;

- (id) valueForObject:(id)object;

+ (VMDProperty *) propertyWithObjectiveCProperty:(objc_property_t)property;

@end
