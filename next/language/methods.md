# Method and Trait

## Method system

MoonBit supports methods in a different way from traditional object-oriented languages. A method in MoonBit is just a toplevel function associated with a type constructor. Methods can be defined using the syntax `fn TypeName::method_name(...) -> ...`:

```{literalinclude} /sources/language/src/method/top.mbt
:language: moonbit
:start-after: start method 1
:end-before: end method 1
```

As a convenient shorthand, when the first parameter of a function is named `self`, MoonBit automatically defines the function as a method of the type of `self`:

```{literalinclude} /sources/language/src/method/top.mbt
:language: moonbit
:start-after: start method 2
:end-before: end method 2
```

is equivalent to:

```{literalinclude} /sources/language/src/method2/top.mbt
:language: moonbit
:start-after: start method 3
:end-before: end method 3
```

Methods are just regular functions owned by a type constructor. So when there is no ambiguity, methods can be called using regular function call syntax directly:

```{literalinclude} /sources/language/src/method/top.mbt
:language: moonbit
:dedent:
:start-after: start method 4
:end-before: end method 4
```

Unlike regular functions, methods support overloading: different types can define methods of the same name. If there are multiple methods of the same name (but for different types) in scope, one can still call them by explicitly adding a `TypeName::` prefix:

```{literalinclude} /sources/language/src/method/top.mbt
:language: moonbit
:dedent:
:start-after: start method 5
:end-before: end method 5
```

When the first parameter of a method is also the type it belongs to, methods can be called using dot syntax `x.method(...)`. MoonBit automatically finds the correct method based on the type of `x`, there is no need to write the type name and even the package name of the method:

```{literalinclude} /sources/language/src/method/top.mbt
:language: moonbit
:start-after: start method 1
:end-before: end method 1
```

```{literalinclude} /sources/language/src/method2/top.mbt
:language: moonbit
:caption: using package with alias list
:start-after: start method 6
:end-before: end method 6
:emphasize-lines: 5
```

The highlighted line is only possible when there is no ambiguity in `@list`.

## Operators

### Operator Overloading

MoonBit supports operator overloading of builtin operators via methods. The method name corresponding to a operator `<op>` is `op_<op>`. For example:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:start-after: start operator 1
:end-before: end operator 1
```

Another example about `op_get` and `op_set`:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:start-after: start operator 2
:end-before: end operator 2
```

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:start-after: start operator 3
:end-before: end operator 3
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/operator/__snapshot__/operator_3
:caption: Output
```

Currently, the following operators can be overloaded:

| Operator Name         | Method Name  |
| --------------------- | ------------ |
| `+`                   | `op_add`     |
| `-`                   | `op_sub`     |
| `*`                   | `op_mul`     |
| `/`                   | `op_div`     |
| `%`                   | `op_mod`     |
| `=`                   | `op_equal`   |
| `<<`                  | `op_shl`     |
| `>>`                  | `op_shr`     |
| `-` (unary)           | `op_neg`     |
| `_[_]` (get item)     | `op_get`     |
| `_[_] = _` (set item) | `op_set`     |
| `_[_:_]` (view)       | `op_as_view` |
| `&`      | `land`  |
| `\|`     | `lor`   |
| `^`      | `lxor`  |
| `<<`     | `op_shl`   |
| `>>`     | `op_shr`   |


By implementing `op_as_view` method, you can create a view for a user-defined type. Here is an example:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:start-after: start view 2
:end-before: end view 2
```

## Trait system

MoonBit features a structural trait system for overloading/ad-hoc polymorphism. Traits declare a list of operations, which must be supplied when a type wants to implement the trait. Traits can be declared as follows:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 1
:end-before: end trait 1
```

In the body of a trait definition, a special type `Self` is used to refer to the type that implements the trait.

To implement a trait, a type must provide all the methods required by the trait.
Implementation for trait methods can be provided via the syntax `impl Trait for Type with method_name(...) { ... }`, for example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 2
:end-before: end trait 2
```

Type annotation can be omitted for trait `impl`: MoonBit will automatically infer the type based on the signature of `Trait::method` and the self type.

The author of the trait can also define default implementations for some methods in the trait, for example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 3
:end-before: end trait 3
```

Implementers of trait `I` don't have to provide an implementation for `f_twice`: to implement `I`, only `f` is necessary.
They can always override the default implementation with an explicit `impl I for Type with f_twice`, if desired, though.

If an explicit `impl` or default implementation is not found, trait method resolution falls back to regular methods.
This allows types to implement a trait implicitly, hence allowing different packages to work together without seeing or depending on each other.
For example, the following trait is automatically implemented for builtin number types such as `Int` and `Double`:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 4
:end-before: end trait 4
```

When declaring a generic function, the type parameters can be annotated with the traits they should implement, allowing the definition of constrained generic functions. For example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 5
:end-before: end trait 5
```

Without the `Number` requirement, the expression `x * x` in `square` will result in a method/operator not found error. Now, the function `square` can be called with any type that implements `Number`, for example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 6
:end-before: end trait 6
```

### Super trait

A trait can depend on other traits, for example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start super trait 1
:end-before: end super trait 1
```

To implement the super trait, one will have to implement the sub traits, 
and the methods defined in the super trait.

### Invoke trait methods directly
Methods of a trait can be called directly via `Trait::method`. MoonBit will infer the type of `Self` and check if `Self` indeed implements `Trait`, for example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 7
:end-before: end trait 7
```

Trait implementations can also be invoked via dot syntax, with the following restrictions:

1. if a regular method is present, the regular method is always favored when using dot syntax
2. only trait implementations that are located in the package of the self type can be invoked via dot syntax
   - if there are multiple trait methods (from different traits) with the same name available, an ambiguity error is reported
3. if neither of the above two rules apply, trait `impl`s in current package will also be searched for dot syntax.
   This allows extending a foreign type locally.
   - these `impl`s can only be called via dot syntax locally, even if they are public.

The above rules ensures that MoonBit's dot syntax enjoys good property while being flexible.
For example, adding a new dependency never break existing code with dot syntax due to ambiguity.
These rules also make name resolution of MoonBit extremely simple:
the method called via dot syntax must always come from current package or the package of the type!

Here's an example of calling trait `impl` with dot syntax:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 8
:end-before: end trait 8
```

## Trait objects

MoonBit supports runtime polymorphism via trait objects.
If `t` is of type `T`, which implements trait `I`,
one can pack the methods of `T` that implements `I`, together with `t`,
into a runtime object via `t as I`.
Trait object erases the concrete type of a value,
so objects created from different concrete types can be put in the same data structure and handled uniformly:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait object 1
:end-before: end trait object 1
```

Not all traits can be used to create objects.
"object-safe" traits' methods must satisfy the following conditions:

- `Self` must be the first parameter of a method
- There must be only one occurrence of `Self` in the type of the method (i.e. the first parameter)

Users can define new methods for trait objects, just like defining new methods for structs and enums:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait object 2
:end-before: end trait object 2
```

## Builtin traits

MoonBit provides the following useful builtin traits:

<!-- MANUAL CHECK https://github.com/moonbitlang/core/blob/80cf250d22a5d5eff4a2a1b9a6720026f2fe8e38/builtin/traits.mbt -->

```moonbit
trait Eq {
  op_equal(Self, Self) -> Bool
}

trait Compare : Eq {
  // `0` for equal, `-1` for smaller, `1` for greater
  compare(Self, Self) -> Int
}

trait Hash {
  hash_combine(Self, Hasher) -> Unit // to be implemented
  hash(Self) -> Int // has default implementation
}

trait Show {
  output(Self, Logger) -> Unit // to be implemented
  to_string(Self) -> String // has default implementation
}

trait Default {
  default() -> Self
}
```

### Deriving builtin traits

MoonBit can automatically derive implementations for some builtin traits:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 9
:end-before: end trait 9
```