VMInstrumenter
==============

A simple Objective-C singleton to instrument, trace, and suppress selectors at runtime

Simple usage:

You can get a <code>VMInstrumenter</code> instance by simply calling

<code>VMInstrumenter *instrumenter = [VMInstrumenter sharedInstance];</code>

Then you can suppress a specific selector of a specific class by calling

<code>[instrumenter suppressSelector:@selector(doFoo) forInstancesOfClass:[self class]];</code>

Any subsequent call to <code>doFoo</code> to <code>[self class]</code> will just be suppressed.

You can afterwards restore the suppressed method by calling

<code>[instrumenter restoreSelector:@selector(doFoo) forInstancesOfClass:[self class]];</code>

You can also exchange methods implementation with

<code>[instrumenter replaceSelector:@selector(doFoo) ofClass:[self class] withSelector:@selector(doBar) ofClass:[self class]];</code>

You can trace the execution of a particular selector (this will log start - end of the execution automatically) by calling

<code>[instrumenter traceSelector:@selector(doBar) forClass:[self class]];</code>

And you can instrument execution of a method by passing blocks of code to be executed before and after the execution of a particular selector by calling

<code>[instrumenter instrumentSelector:@selector(doBar) forClass:[self class] withBeforeBlock:^{
        NSLog(@"Here I am!");
    } afterBlock:nil];
</code>

Everything is at a pre-alpha stage and this is just a 3-hours work so I'm not even sure that everything works. :)