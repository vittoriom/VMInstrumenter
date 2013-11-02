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
	// Do any additional setup after loading the view, typically from a nib.

    VMDInstrumenter *instrumenter = [VMDInstrumenter sharedInstance];
    
    [self doFoo];
    
    [instrumenter suppressSelector:@selector(doFoo) forInstancesOfClass:[self class]];
    
    [instrumenter suppressSelector:@selector(doFoo) forInstancesOfClass:[self class]];
    
    [self doFoo];
    
    [self doBar];
    
    [instrumenter suppressSelector:@selector(doBar) forInstancesOfClass:[self class]];
    
    [self doBar];
    
    NSLog(@"Restoring selector doBar");
    
    [instrumenter restoreSelector:@selector(doBar) forInstancesOfClass:[self class]];
    
    [self doBar];
    
    [instrumenter traceSelector:@selector(doBar) forClass:[self class]];
    
    [self doBar];
    
    [instrumenter traceSelector:@selector(doCalculations:) forClass:[self class]];
    
    NSNumber *result = [self doCalculations:@2];
    
    NSLog(@"RESULT: %@",result);
    
    [instrumenter restoreSelector:@selector(doFoo) forInstancesOfClass:[self class]];
    [instrumenter replaceSelector:@selector(doFoo) ofClass:[self class] withSelector:@selector(doBar) ofClass:[self class]];
    [self doFoo];
    [self doBar];
    
    [instrumenter replaceSelector:@selector(doFoo) ofClass:[self class] withSelector:@selector(doBar) ofClass:[self class]];
    [self doFoo];
    [self doBar];
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

- (NSNumber *) doCalculations:(NSNumber *)dummy
{
    return @1;
}

@end
