# Custom Data Types

There are two ways to create new data types: `struct` and `enum`.

## Struct

In MoonBit, structs are similar to tuples, but their fields are indexed by field names. A struct can be constructed using a struct literal, which is composed of a set of labeled values and delimited with curly brackets. The type of a struct literal can be automatically inferred if its fields exactly match the type definition. A field can be accessed using the dot syntax `s.f`. If a field is marked as mutable using the keyword `mut`, it can be assigned a new value.

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start struct 1
:end-before: end struct 1
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start struct 2
:end-before: end struct 2
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/struct_1
:caption: Output
```

### Constructing Struct with Shorthand

If you already have some variable like `name` and `email`, it's redundant to repeat those names when constructing a struct. You can use shorthand instead, it behaves exactly the same:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:dedent:
:start-after: start struct 3
:end-before: end struct 3
```

If there's no other struct that has the same fields, it's redundant to add the struct's name when constructing it:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:dedent:
:start-after: start struct 5
:end-before: end struct 5
```

### Struct Update Syntax

It's useful to create a new struct based on an existing one, but with some fields updated.

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start struct 4
:end-before: end struct 4
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/struct_4
:caption: Output
```

## Enum

Enum types are similar to algebraic data types in functional languages. Users familiar with C/C++ may prefer calling it tagged union.

An enum can have a set of cases (constructors). Constructor names must start with capitalized letter. You can use these names to construct corresponding cases of an enum, or checking which branch an enum value belongs to in pattern matching:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 1
:end-before: end enum 1
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:dedent:
:start-after: start enum 2
:end-before: end enum 2
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 3
:end-before: end enum 3
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/enum_3
:caption: Output
```

Enum cases can also carry payload data. Here's an example of defining an integer list type using enum:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 4
:end-before: end enum 4
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:dedent:
:start-after: start enum 5
:end-before: end enum 5
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 6
:end-before: end enum 6
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/enum_6
:caption: Output
```

### Constructor with labelled arguments

Enum constructors can have labelled argument:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 7
:end-before: end enum 7
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:dedent:
:start-after: start enum 8
:end-before: end enum 8
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 9
:end-before: end enum 9
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/enum_9
:caption: Output
```

It is also possible to access labelled arguments of constructors like accessing struct fields in pattern matching:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 10
:end-before: end enum 10
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 11
:end-before: end enum 11
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/enum_11
:caption: Output
```

### Constructor with mutable fields

It is also possible to define mutable fields for constructor. This is especially useful for defining imperative data structures:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 12
:end-before: end enum 12
```

## Tuple Struct

MoonBit supports a special kind of struct called tuple struct:

```{literalinclude} /sources/language/src/data/tuple_struct.mbt
:language: moonbit
:start-after: simple definition
:end-before: end simple definition
```

Tuple structs are similar to enum with only one constructor (with the same name as the tuple struct itself). So, you can use the constructor to create values, or use pattern matching to extract the underlying representation:

```{literalinclude} /sources/language/src/data/tuple_struct.mbt
:language: moonbit
:start-after: create and destructure tuple struct
:end-before: end create and destructure tuple struct
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/tuple_struct_2
:caption: Output
```

Besides pattern matching, you can also use index to access the elements similar to tuple:

```{literalinclude} /sources/language/src/data/tuple_struct.mbt
:language: moonbit
:start-after: access tuple struct by index
:end-before: end access tuple struct by index
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/tuple_struct_3
:caption: Output
```

## Type alias
MoonBit supports type alias via the syntax `type NewType = OldType`:

```{warning}
The old syntax `typealias OldType as NewType` may be removed in the future.
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start typealias 1
:end-before: end typealias 1
```

Unlike all other kinds of type declaration above, type alias does not define a new type,
it is merely a type macro that behaves exactly the same as its definition.
So for example one cannot define new methods or implement traits for a type alias.

```{tip}
Type alias can be used to perform incremental code refactor.

For example, if you want to move a type `T` from `@pkgA` to `@pkgB`,
you can leave a type alias `type T = @pkgB.T` in `@pkgA`, and **incrementally** port uses of `@pkgA.T` to `@pkgB.T`.
The type alias can be removed after all uses of `@pkgA.T` is migrated to `@pkgB.T`.
```

## Local types

MoonBit supports declaring structs/enums at the top of a toplevel
function, which are only visible within the current toplevel function. These
local types can use the generic parameters of the toplevel function but cannot
introduce additional generic parameters themselves. Local types can derive
methods using derive, but no additional methods can be defined manually. For 
example:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start local-type 1
:end-before: end local-type 1
```

Currently, local types do not support being declared as error types.
