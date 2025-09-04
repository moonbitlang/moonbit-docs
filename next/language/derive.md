# Deriving traits

MoonBit supports deriving a number of builtin traits automatically from the type definition.

To derive a trait `T`, it is required that all fields used in the type implements `T`.
For example, deriving `Show` for a struct `struct A { x: T1; y: T2 }` requires both `T1: Show` and `T2: Show`

## Show

`derive(Show)` will generate a pretty-printing method for the type.
The derived format is similar to how the type can be constructed in code.

```{literalinclude} /sources/language/src/derive/show.mbt
:language: moonbit
:start-after: start derive show struct
:end-before: end derive show struct
```

```{literalinclude} /sources/language/src/derive/show.mbt
:language: moonbit
:start-after: start derive show enum
:end-before: end derive show enum
```

## Eq and Compare

`derive(Eq)` and `derive(Compare)` will generate the corresponding method for testing equality and comparison.
Fields are compared in the same order as their definitions.
For enums, the order between cases ascends in the order of definition.

```{literalinclude} /sources/language/src/derive/eq_compare.mbt
:language: moonbit
:start-after: start derive eq_compare struct
:end-before: end derive eq_compare struct
```

```{literalinclude} /sources/language/src/derive/eq_compare.mbt
:language: moonbit
:start-after: start derive eq_compare enum
:end-before: end derive eq_compare enum
```

## Default

`derive(Default)` will generate a method that returns the default value of the type.

For structs, the default value is the struct with all fields set as their default value.

```{literalinclude} /sources/language/src/derive/default.mbt
:language: moonbit
:start-after: start derive default struct
:end-before: end derive default struct
```

For enums, the default value is the only case that has no parameters.

```{literalinclude} /sources/language/src/derive/default.mbt
:language: moonbit
:start-after: start derive default enum
:end-before: end derive default enum
```

Enums that has no cases or more than one cases without parameters cannot derive `Default`.

<!-- MANUAL CHECK  should not compile -->

```moonbit
enum CannotDerive1 {
    Case1(String)
    Case2(Int)
} derive(Default) // cannot find a constant constructor as default

enum CannotDerive2 {
    Case1
    Case2
} derive(Default) // Case1 and Case2 are both candidates as default constructor
```

## Hash

`derive(Hash)` will generate a hash implementation for the type.
This will allow the type to be used in places that expects a `Hash` implementation,
for example `HashMap`s and `HashSet`s.

```{literalinclude} /sources/language/src/derive/hash.mbt
:language: moonbit
:start-after: start derive hash struct
:end-before: end derive hash struct
```

## Arbitrary

`derive(Arbitrary)` will generate random values of the given type.

## FromJson and ToJson

`derive(FromJson)` and `derive(ToJson)` automatically derives round-trippable method implementations
used for serializing the type to and from JSON.
The implementation is mainly for debugging and storing the types in a human-readable format.

```{literalinclude} /sources/language/src/derive/json.mbt
:language: moonbit
:start-after: start json basic
:end-before: end json basic
```

Both derive directives accept a number of arguments to configure the exact behavior of serialization and deserialization.

```{warning}
The actual behavior of JSON serialization arguments is unstable.
```

```{warning}
JSON derivation arguments are only for coarse-grained control of the derived format.
If you need to precisely control how the types are laid out,
consider **directly implementing the two traits instead**.

We have recently deprecated a large number of advanced layout tweaking arguments.
For such usage and future usage of them, please manually implement the traits.
The arguments include: `repr`, `case_repr`, `default`, `rename_all`, etc.
```

```{literalinclude} /sources/language/src/derive/json.mbt
:language: moonbit
:start-after: start json args
:end-before: end json args
```

### Enum styles

There are currently two styles of enum serialization: `legacy` and `flat`,
which the user must select one using the `style` argument.
Considering the following enum definition:

```moonbit
enum E {
  One
  Uniform(Int)
  Axes(x~: Int, y~: Int)
}
```

With `derive(ToJson(style="legacy"))`, the enum is formatted into:

```
E::One              => { "$tag": "One" }
E::Uniform(2)       => { "$tag": "Uniform", "0": 2 }
E::Axes(x=-1, y=1)  => { "$tag": "Axes", "x": -1, "y": 1 }
```

With `derive(ToJson(style="flat"))`, the enum is formatted into:

```
E::One              => "One"
E::Uniform(2)       => [ "Uniform", 2 ]
E::Axes(x=-1, y=1)  => [ "Axes", -1, 1 ]
```

#### Deriving `Option`

A notable exception is the builtin type `Option[T]`.
Ideally, it would be interpreted as `T | undefined`, but the issue is that it would be 
impossible to distinguish `Some(None)` and `None` for `Option[Option[T]]`.

As a result, it interpreted as `T | undefined` iff it is a direct field
of a struct, and `[T] | null` otherwise:

```{literalinclude} /sources/language/src/derive/json.mbt
:language: moonbit
:start-after: start json optional
:end-before: end json optional
```

### Container arguments

- `rename_fields` and `rename_cases` (enum only)
  batch renames fields (for enums and structs) and enum cases to the given format.
  Available parameters are:

  - `lowercase`
  - `UPPERCASE`
  - `camelCase`
  - `PascalCase`
  - `snake_case`
  - `SCREAMING_SNAKE_CASE`
  - `kebab-case`
  - `SCREAMING-KEBAB-CASE`

  Example: `rename_fields = "PascalCase"`
  for a field named `my_long_field_name`
  results in `MyLongFieldName`.

  Renaming assumes the name of fields in `snake_case`
  and the name of structs/enum cases in `PascalCase`.

- `cases(...)` (enum only) controls the layout of enum cases.

  ```{warning}
  This might be replaced with case attributes in the future.
  ```

  For example, for an enum

  ```moonbit
  enum E {
    A(...)
    B(...)
  }
  ```

  you are able to control each case using `cases(A(...), B(...))`.

  See [Case arguments](#case-arguments) below for details.

- `fields(...)` (struct only) controls the layout of struct fields.

  ```{warning}
  This might be replaced with field attributes in the future.
  ```

  For example, for a struct

  ```moonbit
  struct S {
    x: Int
    y: Int
  }
  ```

  you are able to control each field using `fields(x(...), y(...))`

  See [Field arguments](#field-arguments) below for details.

### Case arguments

- `rename = "..."` renames this specific case,
  overriding existing container-wide rename directive if any.

- `fields(...)` controls the layout of the payload of this case.
  Note that renaming positional fields are not possible currently.

  See [Field arguments](#field-arguments) below for details.

### Field arguments

- `rename = "..."` renames this specific field,
  overriding existing container-wide rename directives if any.
