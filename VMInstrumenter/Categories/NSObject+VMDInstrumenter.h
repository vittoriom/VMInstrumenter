//
//  NSObject+DumpInfo.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 06/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (VMDInstrumenter)

/**
 This method prints all the ivars, selectors and properties (with value) of self
 */
- (NSString *) dumpInfo;

/**
 @return the stacktrace
 */
- (NSString *) stacktrace;

@end
