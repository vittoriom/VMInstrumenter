//
//  VMTestsHelper.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMTestsHelper.h"

@implementation VMTestsHelper

- (void) dontCallMe
{
    //You did!
}

- (void) canSafelyCallMe
{
    [self.forwardCalls dontCallMe];
}

@end
