# Generics and Functions

Generics allow you to write one set of code for many different types without 
repeating similar logic.

In the example, separate functions `swap_int` and `swap_bool` are defined for 
`Array[Int]` and `Array[Bool]`. If we also wanted to swap elements in `Array[String]` 
or `Array[Char]`, we have to write two more similar functions. It would be better 
if the type could be chosen and passed by the caller, like a function parameter.

MoonBit provides generics for this. Generic parameters are enclosed in `[]`, and 
you can define multiple of them. For functions, generic parameters appear after 
the keyword `fn`. In the example, the function `swap` defines one generic parameter 
`T`, and `T` is used twice in the function definition:

- As the element type of the parameter `arr`: `arr : Array[T]`
- As the type of the local variable `tmp`: `let tmp : T = arr[0]`

Thus, the elements in the array and the variable `tmp` share the same type `T`, 
and the caller decides what `T` is. When calling in `main`, type inference can 
deduce the concrete type of `T` from the argument `array`, so there is no need 
to pass type arguments explicitly.

## Explicitly specifying generic parameter types

In most function calls, type inference can determine the generic parameter types, 
so MoonBit does not provide a syntax for explicitly passing them like some other 
languages do. If you want to specify them explicitly, you can add additional type 
annotations, for example:

```moonbit
swap(([1, 2] : Array[Int]))
```

or

```moonbit
let arr : Array[Int] = [1, 2]
swap(arr)
```