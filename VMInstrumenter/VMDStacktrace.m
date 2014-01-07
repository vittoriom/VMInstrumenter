//
//  VMDStacktrace.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 24/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMDStacktrace.h"
#import "NSObject+VMDInstrumenter.h"
#import "VMDStacktraceFrame.h"

@implementation VMDStacktrace {
    NSMutableArray *_framesArray;
}

- (VMDStacktrace *) init
{
    self = [super init];
    if(self)
    {
        _framesArray = [NSMutableArray array];
        NSArray *stacktraceFrames = [[self stacktrace] componentsSeparatedByString:@"\n"];
        for(NSString *frameString in stacktraceFrames)
        {
            if(frameString.length == 0)
                continue;
            
            VMDStacktraceFrame *frame = [[VMDStacktraceFrame alloc] initWithFrame:frameString];
            [_framesArray addObject:frame];
        }
    }
    
    return self;
}

- (NSArray *) frames
{
    return _framesArray;
}

@end
