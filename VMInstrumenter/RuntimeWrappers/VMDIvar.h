//
//  VMDIvar.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 12/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "NSMethodSignature+VMDInstrumenter.h"

@interface VMDIvar : NSObject

///The name of the ivar
@property (nonatomic, readonly) NSString *name;

///The underlying Ivar pointer if you need to do something manually
@property (nonatomic, readonly) Ivar underlyingIvar;

///The type of the Ivar (see VMDEncodedType in NSMethodSignature+VMDInstrumenter category)
@property (nonatomic, readonly) VMDEncodedType type;

/**
 @param ivar the Ivar pointer
 
 @return VMDIvar the VMDIvar object containing and representing the specified ivar
 */
+ (VMDIvar *) ivarWithIvar:(Ivar)ivar;

/**
 @param object the object you want to get the Ivar value from
 @return id the value of the ivar
 
 @discussion only use this method if the Ivar is some kind of id variable
 */
- (id) valueForObject:(id)object;

/**
 @param object the object you want to get the Ivar value from
 @return char the value of the ivar
 
 @discussion only use this method if the Ivar is a char or unsigned char variable
 */
- (char) charValueForObject:(id)object;

/**
 @param object the object you want to get the Ivar value from
 @return NSInteger the value of the ivar
 
 @discussion only use this method if the Ivar is a short, unsigned short, int or unsigned int variable
 */
- (NSInteger) intValueForObject:(id)object;

/**
 @param object the object you want to get the Ivar value from
 @return Class the value of the ivar
 
 @discussion only use this method if the Ivar is a Class variable
 */
- (Class) classValueForObject:(id)object;

/**
 @param object the object you want to get the Ivar value from
 @return long long the value of the ivar
 
 @discussion only use this method if the Ivar is a long, unsigned long, long long or unsigned long long variable
 */
- (long long) longValueForObject:(id)object;

/**
 @param object the object you want to get the Ivar value from
 @return BOOL the value of the ivar
 
 @discussion only use this method if the Ivar is a BOOL variable
 */
- (BOOL) boolValueForObject:(id)object;

@end
