//
//  VMTestsHelper.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VMTestsHelper : NSObject

@property (nonatomic, strong) VMTestsHelper *forwardCalls;

- (void) dontCallMe;

- (void) canSafelyCallMe;

@end
