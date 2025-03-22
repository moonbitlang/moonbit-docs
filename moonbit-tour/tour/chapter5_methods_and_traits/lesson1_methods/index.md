# Methods

In MoonBit, methods are toplevel functions associated with a type.

There are two ways to declare a method:

- `fn method_name(self : T, ..) -> ..`. The name of the first parameter must be `self` here.
  The declared method will be associated with the type `T`
- `fn T::method_name(..) -> ..`, where the method is associated with type `T`

Methods allow more flexible call syntax compared to regular functions:

- methods can always be invoked with the syntax `T::method_name(..)`
- methods can also be invoked with the syntax `x.method_name(..)`,
  which is equivalent to `T::method_name(x, ..)`, where `T` is the type of `x`
- methods declared with `fn method_name(self : T, ..)` can be invoked using `method_name(..)`, just like regular function

There are already a lot of methods in previous lessons, such as `Array::make(..)` and `arr.length()`.

The difference between two ways to declare method, and guideline for choosing between them is:

- the `fn method_name(self : T, ..)` syntax declares a method in toplevel name space,
  just like regular function.
  So this kind of method can be called via `method_name(..)` directly,
  and cannot have name clash with other regular functions.
  if the method is for a primary type of your package,
  and has no name clash with other regular functions,
  use the `fn method_name(..)` syntax
- the `fn T::method_name(..)` syntax declares a method in a small namespace `T`,
  so this kind of method can only be called via `T::method_name(..)` or `x.method_name(..)`.
  But the benefit is, you can have multiple methods with the same name in this way,
  provided that the types of the methods are different.
  So, this syntax can be used to resolve ambiguity or make the scope of your package cleaner.
