VMDInstrumenter
==============

An Objective-C singleton to instrument, trace, and suppress selectors at runtime

Install:
--------------

If you use CocoaPods, this is as simple as

<code>pod 'VMDInstrumenter'</code>

If you don't use CocoaPods, just download the source and copy the content of the folder VMInstrumenter in your project. 
You can <code>#import "VMDInstrumenter.h"</code> and this is all you'll need.

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

There is also a variant of each of the <code>traceSelector</code> methods where you can avoid specifying <code>beforeBlock</code> and <code>afterBlock</code> but still get some nice behavior from it. That's by calling

```
[instr traceSelector:@selector(doFoo) forClass:[self class] withTracingOptions:VMDInstrumenterTracingOptionsAll];
```

The <code>VMDInstrumenterTracingOptions</code> bit field has the following possible values (that you can bitwise OR as you wish to get your preferred combination):

```
VMDInstrumenterTracingOptionsNone       It doesn't do any particular tracing. This is equivalent to just call traceSelector:forClass: or your specific variant
VMDInstrumenterDumpStacktrace           It prints the stacktrace on the console, at the time the traced selector is going to be called
VMDInstrumenterDumpObject               It prints a dump of the object, with its ivars (and values, when possible), properties (with values) and method list
VMDInstrumenterTraceExecutionTime       It records the execution time for the traced selector and prints it on the console
VMDInstrumenterTracingOptionsAll        All of above
```


License:
--------------
This product is released under the BSD license.

Disclaimer:
--------------
This is mainly an experiment. Don't ever ship this into production code.