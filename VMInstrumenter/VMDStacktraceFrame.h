//
//  VMDStacktraceFrame.h
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 24/11/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VMDStacktraceFrame : NSObject

@property (nonatomic, strong, readonly) NSString *projectOrLibrary;
@property (nonatomic, readonly) Class callingClass;
@property (nonatomic, assign, readonly) NSInteger frameNumber;
@property (nonatomic, readonly) SEL callingSelector;
@property (nonatomic, strong, readonly) NSString *rawMethodCall;

- (instancetype) initWithFrame:(NSString *)frame;

@end
