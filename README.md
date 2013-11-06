VMDInstrumenter
==============

An Objective-C singleton to instrument, trace, and suppress selectors at runtime

Usage:
--------------

**Retrieve an instance of the instrumenter**

You can get a <code>VMDInstrumenter</code> instance by calling

<code>VMDInstrumenter *instrumenter = [VMDInstrumenter sharedInstance];</code>

**Suppressing selectors**

Then you can suppress a specific selector of a specific class by calling

<code>[instrumenter suppressSelector:@selector(doFoo) forClass:[self class]];</code>

Any subsequent call to <code>doFoo</code> in <code>[self class]</code> will be ignored.

You can afterwards restore the suppressed method by calling

<code>[instrumenter restoreSelector:@selector(doFoo) forClass:[self class]];</code>

**Replacing implementations**

You can also exchange methods implementation with

<code>[instrumenter replaceSelector:@selector(doFoo) ofClass:[self class] withSelector:@selector(doBar) ofClass:[self class]];</code>

so that every subsequent call to <code>doFoo</code> will in fact execute the code contained in <code>doBar</code>.

**Tracing selectors**

You can trace the execution of a particular selector (this will log start - end of the execution automatically) by calling

<code>[instrumenter traceSelector:@selector(doBar) forClass:[self class]];</code>

And you can instrument execution of a method by passing blocks of code to be executed before and after the execution of a particular selector by calling

<code>[instrumenter instrumentSelector:@selector(doBar) forClass:[self class] withBeforeBlock:^{
        NSLog(@"Here I am!");
    } afterBlock:nil];
</code>

License:
--------------
This product is released under the BSD license.

ToDo:
--------------
- Dump self object
- Create ObjC wrappers for class_, method_ and so on
- Write tests for all the cases
- Create podspec

Disclaimer:
--------------
This is mainly an experiment. Don't ever ship this into production code.