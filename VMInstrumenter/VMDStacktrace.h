//
//  VMDStacktrace.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 24/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VMDStacktrace : NSObject

@property (nonatomic, strong, readonly) NSArray *frames;

@end
