# Method and Trait

## Method system

MoonBit supports methods in a different way from traditional object-oriented languages. A method in MoonBit is just a toplevel function associated with a type constructor.
To define a method, prepend `SelfTypeName::` in front of the function name, such as `fn SelfTypeName::method_name(...)`, and the method belongs to `SelfTypeName`.
Within the signature of the method declaration, you can use `Self` to refer to `SelfTypeName`.

``````{warning}
Currently, there is a shorthand syntax for defining methods.
When the name of the first parameter is `self`, a function declaration will be considered a method for the type of `self`.
This syntax may be deprecated in the future, and we do not recommend using it in new code.

```{code-block} moonbit
:class: top-level
fn method_name(self : SelfType) -> Unit { ... }
```
``````

```{literalinclude} /sources/language/src/method2/top.mbt
:language: moonbit
:start-after: start method declaration example
:end-before: end method declaration example
```

To call a method, you can either invoke using qualified syntax `T::method_name(..)`, or using dot syntax where the first argument is the type of `T`:

```{literalinclude} /sources/language/src/method2/top.mbt
:language: moonbit
:dedent:
:start-after: start method call syntax example
:end-before: end method call syntax example
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
:dedent:
:start-after: start dot syntax example
:end-before: end dot syntax example
```

Unlike regular functions, methods defined using the `TypeName::method_name` syntax support overloading:
different types can define methods of the same name, because each method lives in a different name space:

```{literalinclude} /sources/language/src/method/top.mbt
:language: moonbit
:dedent:
:start-after: start method overload example
:end-before: end method overload example
```

### Local method
To ensure single source of truth in method resolution and avoid ambiguity,
[methods can only be defined in the same package as its type](/language/packages.md#trait-implementations).
However, there is one exception to this rule: MoonBit allows defining *private* methods for foreign types locally.
These local methods can override methods from the type's own package (MoonBit will emit a warning in this case),
and provide extension/complementary to upstream API:

```{literalinclude} /sources/language/src/method/top.mbt
:language: moonbit
:dedent:
:start-after: start local method
:end-before: end local method
```

### Alias methods as functions

MoonBit allows calling methods with alternative names via alias.

The method alias will create a method with the corresponding name.
You can also choose to create a function with the corresponding name.
The visibility can also be controlled.

```{literalinclude} /sources/language/src/method/top.mbt
:language: moonbit
:start-after: start method alias
:end-before: end method alias
```

## Operator Overloading

MoonBit supports overloading infix operators of builtin operators via several builtin traits. For example:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:start-after: start operator 1
:end-before: end operator 1
```

Other operators are overloaded via methods with annotations, for example `_[_]` and `_[_]=_`:

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

| Operator Name         | overloading mechanism   |
| --------------------- | ----------------------- |
| `+`                   | trait `Add`             |
| `-`                   | trait `Sub`             |
| `*`                   | trait `Mul`             |
| `/`                   | trait `Div`             |
| `%`                   | trait `Mod`             |
| `==`                  | trait `Eq`              |
| `<<`                  | trait `Shl`             |
| `>>`                  | trait `Shr`             |
| `-` (unary)           | trait `Neg`             |
| `_[_]` (get item)     | method + alias `_[_]`   |
| `_[_] = _` (set item) | method + alias `_[_]=_` |
| `_[_:_]` (view)       | method + alias `_[_:_]` |
| `&`                   | trait `BitAnd`          |
| `\|`                  | trait `BitOr`           |
| `^`                   | trait `BitXOr`          |

When overloading `_[_]`/`_[_] = _`/`_[_:_]`, the method must have a correcnt signature:

- `_[_]` should have signature `(Self, Index) -> Result`, used as `let result = self[index]`
- `_[_]=_` should have signature `(Self, Index, Value) -> Unit`, used as `self[index] = value`
- `_[_:_]` should have signature `(Self, start? : Index, end? : Index) -> Result`, used as `let result = self[start:end]`

By implementing `_[_:_]` method, you can create a view for a user-defined type. Here is an example:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:start-after: start view 2
:end-before: end view 2
```

## Trait system

MoonBit provides a trait system for overloading/ad-hoc polymorphism. Traits declare a list of operations, which must be supplied when a type wants to implement the trait. Traits can be declared as follows:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 1
:end-before: end trait 1
```

In the body of a trait definition, a special type `Self` is used to refer to the type that implements the trait.

### Extending traits

A trait can depend on other traits, for example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start super trait 1
:end-before: end super trait 1
```

### Implementing traits

To implement a trait, a type must explicitly provide all the methods required by the trait
using the syntax `impl Trait for Type with method_name(...) { ... }`. For example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 2
:end-before: end trait 2
```

Type annotation can be omitted for trait `impl`: MoonBit will automatically infer the type based on the signature of `Trait::method` and the self type.

The author of the trait can also define **default implementations** for some methods in the trait, for example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 3
:end-before: end trait 3
```

Note that in addition to the actual default implementation `impl J with f_twice`,
a mark `= _` is also required in the declaration of `f_twice` in `J`.
The `= _` mark is an indicator that this method has default implementation,
it enhances readability by allowing readers to know which methods have default implementation at first glance.

Implementers of trait `J` don't have to provide an implementation for `f_twice`: to implement `J`, only `f` is necessary.
They can always override the default implementation with an explicit `impl J for Type with f_twice`, if desired, though.

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 4
:end-before: end trait 4
```

To implement the sub trait, one will have to implement the super traits,
and the methods defined in the sub trait. For example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start super trait 2
:end-before: end super trait 2
```

For traits where all methods have default implementation,
it is still necessary to explicitly implement them,
in order to support features such as [abstract trait](/language/packages.md#traits).
For this purpose, MoonBit provides the syntax `impl Trait for Type` (i.e. without the method part).
`impl Trait for Type` ensures that `Type` implements `Trait`,
MoonBit will automatically check if every method in `Trait` has corresponding implementation (custom or default).

In addition to handling traits where every methods has a default implementation,
the `impl Trait for Type` can also serve as documentation, or a TODO mark before filling actual implementation.

```{warning}
Currently, an empty trait without any method is implemented automatically.
```

### Using traits

When declaring a generic function, the type parameters can be annotated with the traits they should implement, allowing the definition of constrained generic functions. For example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 5
:end-before: end trait 5
```

Without the `Eq` requirement, the expression `x == elem` in `contains` will result in a type error. Now, the function `contains` can be called with any type that implements `Eq`, for example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 6
:end-before: end trait 6
```

#### Invoke trait methods directly

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

### Trait alias

MoonBit allows using traits with alternative names via trait alias.

```{warning}
This feature may be removed in the future.
```

Trait alias can be declared as follows:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait alias
:end-before: end trait alias
```

## Trait objects

MoonBit supports runtime polymorphism via trait objects.
If `t` is of type `T`, which implements trait `I`,
one can pack the methods of `T` that implements `I`, together with `t`,
into a runtime object via `t as &I`.
When the expected type of an expression is known to be a trait object type, `as &I` can be omitted.
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

See [Deriving](./derive.md) for more information about deriving traits.
