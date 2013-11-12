//
//  VMDMethod.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 12/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface VMDMethod : NSObject

@property (nonatomic, readonly) SEL selector;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) Method underlyingMethod;
@property (nonatomic, readonly) const char * typeEncoding;
@property (nonatomic, readonly) char returnType;

+ (VMDMethod *) methodWithMethod:(Method)method;

- (void) exchangeImplementationWithMethod:(VMDMethod *)method;

@end
