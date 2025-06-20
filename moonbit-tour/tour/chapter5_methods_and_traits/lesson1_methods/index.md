# Methods

In MoonBit, methods are toplevel functions associated with a type.
Methods can be declared using the syntax `fn T::method_name(..) -> ..`,
where the method is associated with type `T`.
Within the signature of the method, you can use `Self` to refer to `T`,
this can simplify the syntax if `T` is very long.

There are two ways to invoke a method:

- methods can always be invoked with the syntax `T::method_name(..)`
- methods can also be invoked with the syntax `x.method_name(..)`,
  which is equivalent to `T::method_name(x, ..)`, where `T` is the type of `x`

There are already a lot of methods in previous lessons, such as `Array::make(..)` and `arr.length()`.

Methods support partial application as well, both `x.f(_)` and `_.f(..)` work as expected.
