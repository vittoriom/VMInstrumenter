//
//  NSObject+DumpInfo.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 06/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (VMDInstrumenter)

- (void) dumpInfo;

- (NSString *) stacktrace;

@end
