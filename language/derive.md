# Deriving traits

MoonBit supports deriving a number of builtin traits automatically from the type definition.

To derive a trait `T`, it is required that all fields used in the type implements `T`.
For example, deriving `Show` for a struct `struct A { x: T1; y: T2 }` requires both `T1: Show` and `T2: Show`

## Show

`derive(Show)` will generate a pretty-printing method for the type.
The derived format is similar to how the type can be constructed in code.

```moonbit
struct MyStruct {
  x : Int
  y : Int
} derive(Show)

test "derive show struct" {
  let p = MyStruct::{ x: 1, y: 2 }
  assert_eq(Show::to_string(p), "{x: 1, y: 2}")
}
```

```moonbit
enum MyEnum {
  Case1(Int)
  Case2(label~ : String)
  Case3
} derive(Show)

test "derive show enum" {
  assert_eq(Show::to_string(MyEnum::Case1(42)), "Case1(42)")
  assert_eq(
    Show::to_string(MyEnum::Case2(label="hello")),
    "Case2(label=\"hello\")",
  )
  assert_eq(Show::to_string(MyEnum::Case3), "Case3")
}
```

## Eq and Compare

`derive(Eq)` and `derive(Compare)` will generate the corresponding method for testing equality and comparison.
Fields are compared in the same order as their definitions.
For enums, the order between cases ascends in the order of definition.

```moonbit
struct DeriveEqCompare {
  x : Int
  y : Int
} derive(Eq, Compare)

test "derive eq_compare struct" {
  let p1 = DeriveEqCompare::{ x: 1, y: 2 }
  let p2 = DeriveEqCompare::{ x: 2, y: 1 }
  let p3 = DeriveEqCompare::{ x: 1, y: 2 }
  let p4 = DeriveEqCompare::{ x: 1, y: 3 }

  // Eq
  assert_eq(p1 == p2, false)
  assert_eq(p1 == p3, true)
  assert_eq(p1 == p4, false)
  assert_eq(p1 != p2, true)
  assert_eq(p1 != p3, false)
  assert_eq(p1 != p4, true)

  // Compare
  assert_eq(p1 < p2, true)
  assert_eq(p1 < p3, false)
  assert_eq(p1 < p4, true)
  assert_eq(p1 > p2, false)
  assert_eq(p1 > p3, false)
  assert_eq(p1 > p4, false)
  assert_eq(p1 <= p2, true)
  assert_eq(p1 >= p2, false)
}
```

```moonbit
enum DeriveEqCompareEnum {
  Case1(Int)
  Case2(label~ : String)
  Case3
} derive(Eq, Compare)

test "derive eq_compare enum" {
  let p1 = DeriveEqCompareEnum::Case1(42)
  let p2 = DeriveEqCompareEnum::Case1(43)
  let p3 = DeriveEqCompareEnum::Case1(42)
  let p4 = DeriveEqCompareEnum::Case2(label="hello")
  let p5 = DeriveEqCompareEnum::Case2(label="world")
  let p6 = DeriveEqCompareEnum::Case2(label="hello")
  let p7 = DeriveEqCompareEnum::Case3

  // Eq
  assert_eq(p1 == p2, false)
  assert_eq(p1 == p3, true)
  assert_eq(p1 == p4, false)
  assert_eq(p1 != p2, true)
  assert_eq(p1 != p3, false)
  assert_eq(p1 != p4, true)

  // Compare
  assert_eq(p1 < p2, true) // 42 < 43
  assert_eq(p1 < p3, false)
  assert_eq(p1 < p4, true) // Case1 < Case2
  assert_eq(p4 < p5, true)
  assert_eq(p4 < p6, false)
  assert_eq(p4 < p7, true) // Case2 < Case3
}
```

## Default

`derive(Default)` will generate a method that returns the default value of the type.

For structs, the default value is the struct with all fields set as their default value.

```moonbit
struct DeriveDefault {
  x : Int
  y : String?
} derive(Default, Eq, Show)

test "derive default struct" {
  let p = DeriveDefault::default()
  assert_eq(p, DeriveDefault::{ x: 0, y: None })
}
```

For enums, the default value is the only case that has no parameters.

```moonbit
enum DeriveDefaultEnum {
  Case1(Int)
  Case2(label~ : String)
  Case3
} derive(Default, Eq, Show)

test "derive default enum" {
  assert_eq(DeriveDefaultEnum::default(), DeriveDefaultEnum::Case3)
}
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

```moonbit
struct DeriveHash {
  x : Int
  y : String?
} derive(Hash, Eq, Show)

test "derive hash struct" {
  let hs = @hashset.new()
  hs.add(DeriveHash::{ x: 123, y: None })
  hs.add(DeriveHash::{ x: 123, y: None })
  assert_eq(hs.size(), 1)
  hs.add(DeriveHash::{ x: 123, y: Some("456") })
  assert_eq(hs.size(), 2)
}
```

## Arbitrary

`derive(Arbitrary)` will generate random values of the given type.

## FromJson and ToJson

`derive(FromJson)` and `derive(ToJson)` automatically derives round-trippable method implementations
used for serializing the type to and from JSON.
The implementation is mainly for debugging and storing the types in a human-readable format.

```moonbit
struct JsonTest1 {
  x : Int
  y : Int
} derive(FromJson, ToJson, Eq, Show)

enum JsonTest2 {
  A(x~ : Int)
  B(x~ : Int, y~ : Int)
} derive(FromJson(style="legacy"), ToJson(style="legacy"), Eq, Show)

test "json basic" {
  let input = JsonTest1::{ x: 123, y: 456 }
  let expected : Json = { "x": 123, "y": 456 }
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
  let input = JsonTest2::A(x=123)
  let expected : Json = { "$tag": "A", "x": 123 }
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
}
```

Both derive directives accept a number of arguments to configure the exact behavior of serialization and deserialization.

#### WARNING
The actual behavior of JSON serialization arguments is unstable.

#### WARNING
JSON derivation arguments are only for coarse-grained control of the derived format.
If you need to precisely control how the types are laid out,
consider **directly implementing the two traits instead**.

We have recently deprecated a large number of advanced layout tweaking arguments.
For such usage and future usage of them, please manually implement the traits.
The arguments include: `repr`, `case_repr`, `default`, `rename_all`, etc.

```moonbit
struct JsonTest3 {
  x : Int
  y : Int
} derive (
  FromJson(fields(x(rename="renamedX"))),
  ToJson(fields(x(rename="renamedX"))),
  Eq,
  Show,
)

enum JsonTest4 {
  A(x~ : Int)
  B(x~ : Int, y~ : Int)
} derive (
  FromJson(style="flat"),
  ToJson(style="flat"),
  Eq,
  Show,
)

test "json args" {
  let input = JsonTest3::{ x: 123, y: 456 }
  let expected : Json = { "renamedX": 123, "y": 456 }
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
  let input = JsonTest4::A(x=123)
  let expected : Json = [ "A", { "x": 123 } ]
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
}
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

```default
E::One              => { "$tag": "One" }
E::Uniform(2)       => { "$tag": "Uniform", "0": 2 }
E::Axes(x=-1, y=1)  => { "$tag": "Axes", "x": -1, "y": 1 }
```

With `derive(ToJson(style="flat"))`, the enum is formatted into:

```default
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

```moonbit
struct A {
  x : Int?
  y : Int??
  z : (Int?, Int??)
} derive(ToJson)

test {
  @json.inspect({ x: None, y: None, z: (None, None) }, content={
    "z": [null, null],
  })
  @json.inspect({ x: Some(1), y: Some(None), z: (Some(1), Some(None)) }, content={
    "x": 1,
    "y": null,
    "z": [[1], [null]],
  })
  @json.inspect({ x: Some(1), y: Some(Some(1)), z: (Some(1), Some(Some(1))) }, content={
    "x": 1,
    "y": [1],
    "z": [[1], [[1]]],
  })
}
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

  #### WARNING
  This might be replaced with case attributes in the future.

  For example, for an enum
  ```moonbit
  enum E {
    A(...)
    B(...)
  }
  ```

  you are able to control each case using `cases(A(...), B(...))`.

  See [Case arguments]() below for details.
- `fields(...)` (struct only) controls the layout of struct fields.

  #### WARNING
  This might be replaced with field attributes in the future.

  For example, for a struct
  ```moonbit
  struct S {
    x: Int
    y: Int
  }
  ```

  you are able to control each field using `fields(x(...), y(...))`

  See [Field arguments]() below for details.

### Case arguments

- `rename = "..."` renames this specific case,
  overriding existing container-wide rename directive if any.
- `fields(...)` controls the layout of the payload of this case.
  Note that renaming positional fields are not possible currently.

  See [Field arguments]() below for details.

### Field arguments

- `rename = "..."` renames this specific field,
  overriding existing container-wide rename directives if any.
