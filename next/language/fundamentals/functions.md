# Functions

Functions take arguments and produce a result. In MoonBit, functions are first-class, which means that functions can be arguments or return values of other functions. MoonBit's naming convention requires that function names should not begin with uppercase letters (A-Z). Compare for constructors in the `enum` section below.

## Top-Level Functions

Functions can be defined as top-level or local. We can use the `fn` keyword to define a top-level function that sums three integers and returns the result, as follows:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start top-level functions
:end-before: end top-level functions
```

Note that the arguments and return value of top-level functions require **explicit** type annotations.

## Local Functions

Local functions can be named or anonymous. Type annotations can be omitted for local function definitions: they can be automatically inferred in most cases. For example:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start local functions 1
:end-before: end local functions 1
```

For simple anonymous function, MoonBit provides a very concise syntax called arrow function:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start local functions 3
:end-before: end local functions 3
```

Functions, whether named or anonymous, are _lexical closures_: any identifiers without a local binding must refer to bindings from a surrounding lexical scope. For example:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start local functions 2
:end-before: end local functions 2
```

A local function can only refer to itself and other previously defined local functions.
To define  mutually recursive local functions, use the syntax `letrec f = .. and g = ..` instead:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start local functions 4
:end-before: end local functions 4
```

## Function Applications

A function can be applied to a list of arguments in parentheses:

```moonbit
add3(1, 2, 7)
```

This works whether `add3` is a function defined with a name (as in the previous example), or a variable bound to a function value, as shown below:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start function application 1
:end-before: end function application 1
```

The expression `add3(1, 2, 7)` returns `10`. Any expression that evaluates to a function value is applicable:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:dedent:
:start-after: start function application 2
:end-before: end function application 2
```

## Partial Applications

Partial application is a technique of applying a function to some of its arguments, resulting in a new function that takes the remaining arguments. In MoonBit, partial application is achieved by using the `_` operator in function application:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:dedent:
:start-after: start partial application 1
:end-before: end partial application 1
```

The `_` operator represents the missing argument in parentheses. The partial application allows multiple `_` in the same parentheses.
For example, `Array::fold(_, _, init=5)` is equivalent to `fn(x, y) { Array::fold(x, y, init=5) }`.

The `_` operator can also be used in enum creation, dot style function calls and in the pipelines.

## Labelled arguments

**Top-level** functions can declare labelled argument with the syntax `label~ : Type`. `label` will also serve as parameter name inside function body:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start labelled arguments 1
:end-before: end labelled arguments 1
```

Labelled arguments can be supplied via the syntax `label=arg`. `label=label` can be abbreviated as `label~`:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start labelled arguments 2
:end-before: end labelled arguments 2
```

Labelled function can be supplied in any order. The evaluation order of arguments is the same as the order of parameters in function declaration.

## Optional arguments

An argument can be made optional by supplying a default expression with the syntax `label?: Type = default_expr`, where the `default_expr` may be omitted. If this argument is not supplied at call site, the default expression will be used:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start optional arguments 1
:end-before: end optional arguments 1
```

The default expression will be evaluated every time it is used. And the side effect in the default expression, if any, will also be triggered. For example:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start optional arguments 2
:end-before: end optional arguments 2
```

If you want to share the result of default expression between different function calls, you can lift the default expression to a toplevel `let` declaration:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start optional arguments 3
:end-before: end optional arguments 3
```

The default expression can depend on previous arguments, such as:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start optional arguments 4
:end-before: end optional arguments 4
```

### Optional arguments without default values

It is quite common to have different semantics when a user does not provide a value.
Optional arguments without default values have type `T?` and `None` as the default value.
When supplying this kind of optional argument directly, MoonBit will automatically wrap the value with `Some`:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start optional arguments 6
:end-before: end optional arguments 6
```

Sometimes, it is also useful to pass a value of type `T?` directly,
for example when forwarding optional argument.
MoonBit provides a syntax `label?=value` for this, with `label?` being an abbreviation of `label?=label`:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start optional arguments 7
:end-before: end optional arguments 7
```

## Autofill arguments

MoonBit supports filling specific types of arguments automatically at different call site, such as the source location of a function call.
To declare an autofill argument, simply declare a labelled argument, and add a function attribute `#callsite(autofill(param_a, param_b))`.
Now if the argument is not explicitly supplied, MoonBit will automatically fill it at the call site.

Currently MoonBit supports two types of autofill arguments, `SourceLoc`, which is the source location of the whole function call,
and `ArgsLoc`, which is an array containing the source location of each argument, if any:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start autofill arguments
:end-before: end autofill arguments
```

Autofill arguments are very useful for writing debugging and testing utilities.

## Function alias
MoonBit allows calling functions with alternative names via function alias. Function alias can be declared as follows:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start function alias
:end-before: end function alias
```

You can also create function alias that has different visibility with the field `visibility`.
