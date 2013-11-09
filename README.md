VMDInstrumenter
==============

An Objective-C singleton to instrument, trace, and suppress selectors at runtime

Usage:
--------------

**Retrieve an instance of the instrumenter**

You can get a <code>VMDInstrumenter</code> instance by calling

```
VMDInstrumenter *instrumenter = [VMDInstrumenter sharedInstance];
```

**Suppressing selectors**

Then you can suppress a specific selector of a specific class by calling

```
[instrumenter suppressSelector:@selector(doFoo) forClass:[self class]];
```

Any subsequent call to <code>doFoo</code> in <code>[self class]</code> will be ignored.

You can afterwards restore the suppressed method by calling

```
[instrumenter restoreSelector:@selector(doFoo) forClass:[self class]];
```

**Replacing implementations**

You can also exchange methods implementation with

```
[instrumenter replaceSelector:@selector(doFoo) ofClass:[self class] withSelector:@selector(doBar) ofClass:[self class]];
```

so that every subsequent call to <code>doFoo</code> will in fact execute the code contained in <code>doBar</code>.

**Tracing selectors**

You can trace the execution of a particular selector (this will log start - end of the execution automatically) by calling

```
[instrumenter traceSelector:@selector(doBar) forClass:[self class]];
```

You can also trace the execution of a particular selector only if it's called on a specific instance by calling

```
[instrumenter traceSelector:@selector(doBar) forObject:fooInstance];
```

And you can instrument execution of a method by passing blocks of code to be executed before and after the execution of a particular selector by calling

```
[instrumenter instrumentSelector:@selector(doBar) forClass:[self class] withBeforeBlock:^{
    NSLog(@"Here I am!");
} afterBlock:nil];
```

As for tracing, you can instrument a selector called only on a specific instance with

```
[instrumenter instrumentSelector:@selector(doBar) forObject:fooInstance withBeforeBlock:^{
    NSLog(@"Here I am!");
} afterBlock:nil];
```

If you need to trace the execution of a particular selector on selected instances of the same class, you can't call <code>traceSelector:forObject:</code> multiple times with the same selector, but you can use the method

```
[instrumenter traceSelector:@selector(doBar) forInstancesOfClass:[self class] passingTest:^BOOL(id instance) {
    //Your test goes here, the parameter instance is the object that got the call
    return instance == self;
}];
```

As for tracing, you can instrument a selector called on selected instances of the same class using

```
[instr instrumentSelector:@selector(doFoo) forInstancesOfClass:[self class] passingTest:^BOOL(id instance) {
    //Your test goes here, the parameter instance is the object that got the call
    return instance == self;
} withBeforeBlock:^(id instance) {
    NSLog(@"Here I am!");
} afterBlock:nil];
```

License:
--------------
This product is released under the BSD license.

Disclaimer:
--------------
This is mainly an experiment. Don't ever ship this into production code.