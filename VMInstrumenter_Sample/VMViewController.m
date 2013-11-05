//
//  VMViewController.m
//  VMInstrumenter_Sample
//
//  Created by Vittorio Monaco on 28/08/13.
//  Copyright (c) 2013 Vittorio Monaco. All rights reserved.
//

#import "VMViewController.h"
#import "VMDInstrumenter.h"

@interface VMViewController ()

@end

@implementation VMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    //Get an instance of the Instrumenter
    VMDInstrumenter *instrumenter = [VMDInstrumenter sharedInstance];
    
    //This will execute doFoo
    [self doFoo];
    
    //From now on doFoo won't get executed anymore
    [instrumenter suppressSelector:@selector(doFoo) forInstancesOfClass:[self class]];
    
    //Nothing happens if we suppress a selector twice, just a log in the console
    [instrumenter suppressSelector:@selector(doFoo) forInstancesOfClass:[self class]];
    
    //This will do nothing
    [self doFoo];
    
    //This will execute doBar
    [self doBar];
    
    //From now on every call to doBar will get a pre and post NSLog
    [instrumenter traceSelector:@selector(doBar) forClass:[self class]];
    
    //Here you can see
    [self doBar];
    
    //The same as before, but with a method that takes a parameter
    [instrumenter traceSelector:@selector(doCalculations:) forClass:[self class]];
    
    //The tracing won't impact the normal return
    NSNumber *result = [self doCalculations:@2];
    
    NSLog(@"RESULT: %@",result);
    
    //From now on every call to doFoo will execute doFoo again
    [instrumenter restoreSelector:@selector(doFoo) forInstancesOfClass:[self class]];
    
    //This swaps the implementations of doFoo and doBar
    [instrumenter replaceSelector:@selector(doFoo) ofClass:[self class] withSelector:@selector(doBar) ofClass:[self class]];
    [self doFoo];
    [self doBar];
    
    //This swaps the implementations again (i.e. it restores them to their original state)
    [instrumenter replaceSelector:@selector(doFoo) ofClass:[self class] withSelector:@selector(doBar) ofClass:[self class]];
    [self doFoo];
    [self doBar];
    
    //This shows how to trace a selector dumping the stack trace
    [instrumenter traceSelector:@selector(doFoo) forClass:[self class] dumpingStackTrace:YES];
    [self doFoo];
    
    //This shows that you can get primitive values as well
    [instrumenter traceSelector:@selector(primitiveTest) forClass:[self class]];
    NSInteger test = [self primitiveTest];
    NSLog(@"PRIMITIVE TEST: %d",test);
    
    [instrumenter traceSelector:@selector(booleanTest) forClass:[self class]];
    NSLog([self booleanTest] ? @"BOOLEAN TEST OK " : @"BOOLEAN TEST FAILED");
    
    //This shows another object method
    [instrumenter instrumentSelector:@selector(objectTest) forClass:[self class] withBeforeBlock:^{
        NSLog(@"Whoopy do");
    } afterBlock:nil];
    NSString *strResult = [self objectTest];
    NSLog(@"STRING RESULT: %@",strResult);
}

- (void) doFoo
{
    NSLog(@"DOING FOO!");
}

- (void) doFooWithMoreParameters:(NSNumber *)number andDate:(NSDate *)date
{
    NSLog(@"DO A LOT OF STUFF");
}

- (void) doBar
{
    NSLog(@"DOING BAR!");
}

- (NSInteger) primitiveTest
{
    return 5;
}

- (BOOL) booleanTest
{
    return YES;
}

- (NSString *) objectTest
{
    return @"test";
}

- (NSNumber *) doCalculations:(NSNumber *)dummy
{
    return dummy;
}

@end
