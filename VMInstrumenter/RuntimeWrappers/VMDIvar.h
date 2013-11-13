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

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) Ivar underlyingIvar;
@property (nonatomic, readonly) VMDEncodedType type;

+ (VMDIvar *) ivarWithIvar:(Ivar)ivar;

- (id) valueForObject:(id)object;
- (char) charValueForObject:(id)object;
- (NSInteger) intValueForObject:(id)object;
- (Class) classValueForObject:(id)object;
- (long long) longValueForObject:(id)object;
- (BOOL) boolValueForObject:(id)object;

@end
