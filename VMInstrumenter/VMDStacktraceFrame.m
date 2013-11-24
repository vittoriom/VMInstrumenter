//
//  VMDStacktraceFrame.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 24/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMDStacktraceFrame.h"

@implementation VMDStacktraceFrame

- (instancetype) initWithFrame:(NSString *)frame
{
    self = [super init];
    
    if(self)
    {
        NSScanner *scanner = [NSScanner scannerWithString:frame];
        NSCharacterSet *whitespaceCS = [NSCharacterSet whitespaceCharacterSet];
        
        NSString *frameNo = nil;
        [scanner scanUpToCharactersFromSet:whitespaceCS intoString:&frameNo];
        _frameNumber = [frameNo intValue];
        
        NSString *projectOrLibraryElement = nil;
        [scanner scanUpToCharactersFromSet:whitespaceCS intoString:&projectOrLibraryElement];
        _projectOrLibrary = projectOrLibraryElement;
        
        NSString *pointerString = nil;
        [scanner scanUpToCharactersFromSet:whitespaceCS intoString:&pointerString];
        
        NSString *callingClassElement = nil;
        [scanner scanUpToCharactersFromSet:whitespaceCS intoString:&callingClassElement];
        
        if([callingClassElement hasPrefix:@"__"])
        {
            NSInteger startingLocation = MIN([callingClassElement rangeOfString:@"-"].location, [callingClassElement rangeOfString:@"+"].location);
            if(startingLocation != NSNotFound)
                callingClassElement = [callingClassElement substringFromIndex:startingLocation];
        }
        
        _rawMethodCall = [NSMutableString stringWithString:callingClassElement];
        
        if([callingClassElement hasPrefix:@"-"] || [callingClassElement hasPrefix:@"+"])
        {
            callingClassElement = [callingClassElement substringFromIndex:2];
            NSString *callingSelectorElement = nil;
            [scanner scanUpToCharactersFromSet:whitespaceCS intoString:&callingSelectorElement];
        
            [(NSMutableString *)_rawMethodCall appendFormat:@" %@",callingSelectorElement];
            NSRange closingParenthesisRange = [callingSelectorElement rangeOfString:@"]"];
            if(closingParenthesisRange.location != NSNotFound)
            {
                callingSelectorElement = [callingSelectorElement substringToIndex:closingParenthesisRange.location];
                _callingSelector = NSSelectorFromString(callingSelectorElement);
            }
        }
        
        _callingClass = NSClassFromString(callingClassElement);
        if(!_callingClass)
        {
            NSRange openingParenthesisRange = [callingClassElement rangeOfString:@"("];
            if(openingParenthesisRange.location != NSNotFound)
                _callingClass = NSClassFromString([callingClassElement substringToIndex:openingParenthesisRange.location]);
        }
    }
    
    return self;
}

@end
