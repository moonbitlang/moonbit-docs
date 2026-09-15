# Deriving traits

MoonBit supports deriving a number of builtin traits automatically from the type definition.

To derive a trait `T`, all fields used in the type must implement `T`.
For example, deriving `Show` for a struct `struct A { x: T1; y: T2 }`
requires both `T1 : Show` and `T2 : Show`.

`derive` generates a trait implementation. The examples below also use
[`extend`](https://docs.moonbitlang.com/en/latest/language/methods.html#attaching-trait-methods-with-extend) to state explicitly
which generated trait functions are part of the type's method-style API. This
avoids relying on the deprecated implicit attachment of methods from an
implementation.

## Eq and Compare

`derive(Eq)` and `derive(Compare)` generate the corresponding implementations for testing equality and comparison.
Fields are compared in the same order as their definitions.
For enums, the order between cases ascends in the order of definition.

```moonbit
struct DeriveEqCompare {
  x : Int
  y : Int
} derive(Eq, Compare)

pub extend DeriveEqCompare with Eq::{not_equal, equal}

pub extend DeriveEqCompare with Compare::{op_lt, op_le, op_ge, compare, op_gt}

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

pub extend DeriveEqCompareEnum with Eq::{not_equal, equal}

pub extend DeriveEqCompareEnum with Compare::{op_lt, op_le, op_ge, compare, op_gt}

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

## Debug

`derive(Debug)` generates a structural debugging implementation for the type.
It is useful with `debug_inspect` in tests and `@debug.to_string` when formatting diagnostic messages.

```moonbit
struct DebugPoint {
  x : Int
  y : Int
} derive(Debug)

pub extend DebugPoint with Debug::{to_repr}

test "derive debug struct" {
  let point = DebugPoint::{ x: 1, y: 2 }
  debug_inspect(point, content="{ x: 1, y: 2 }")
}
```

Enums can derive `Debug` as well:

```moonbit
enum DebugShape {
  Circle(radius~ : Int)
  Rect(width~ : Int, height~ : Int)
} derive(Debug)

pub extend DebugShape with Debug::{to_repr}

test "derive debug enum" {
  let shape = DebugShape::Rect(width=3, height=4)
  debug_inspect(shape, content="Rect(width=3, height=4)")
}
```

## Default

`derive(Default)` generates a `Default` implementation for the type. Call
`Default::default()` with the expected type specified so MoonBit can select the
implementation. Use an explicit `extend` declaration if `default` should also
be part of the type's method-style API.

For structs, the default value is the struct with all fields set as their default value.

```moonbit
struct DeriveDefault {
  x : Int
  y : String?
} derive(Default, Eq)

pub extend DeriveDefault with Default::{default}

pub extend DeriveDefault with Eq::{not_equal, equal}

test "derive default struct" {
  let p : DeriveDefault = Default::default()
  assert_true(p == DeriveDefault::{ x: 0, y: None })
}
```

For enums, the default value is the only case that has no parameters.

```moonbit
enum DeriveDefaultEnum {
  Case1(Int)
  Case2(label~ : String)
  Case3
} derive(Default, Eq)

pub extend DeriveDefaultEnum with Default::{default}

pub extend DeriveDefaultEnum with Eq::{not_equal, equal}

test "derive default enum" {
  let value : DeriveDefaultEnum = Default::default()
  assert_true(value == DeriveDefaultEnum::Case3)
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

`derive(Hash)` generates a hash implementation for the type.
This will allow the type to be used in places that expects a `Hash` implementation,
for example `HashMap`s and `HashSet`s.

```moonbit
struct DeriveHash {
  x : Int
  y : String?
} derive(Hash, Eq)

pub extend DeriveHash with Hash::{hash, hash_combine}

pub extend DeriveHash with Eq::{not_equal, equal}

test "derive hash struct" {
  let hs = @hashset.HashSet([])
  hs.add(DeriveHash::{ x: 123, y: None })
  hs.add(DeriveHash::{ x: 123, y: None })
  @test.assert_eq(hs.length(), 1)
  hs.add(DeriveHash::{ x: 123, y: Some("456") })
  @test.assert_eq(hs.length(), 2)
}
```

## Arbitrary

`derive(Arbitrary)` will generate random values of the given type.

## Shrink

`derive(Shrink)` implements `@quickcheck.Shrink` for property-based testing.
Struct fields are shrunk one at a time in source order. Enum values keep their
current constructor while its payload is shrunk; constructors without payloads
produce no candidates. Every field or payload used by the derived
implementation must itself implement `Shrink`.

```moonbit
///|
struct ShrinkPoint {
  x : Int
  y : Int
} derive(Shrink)

///|
pub extend ShrinkPoint with @shrink.Shrink::{shrink}

///|
fn shrink_candidates(point : ShrinkPoint) -> Iter[ShrinkPoint] {
  @quickcheck.Shrink::shrink(point)
}

///|
test "derive shrink struct" {
  let candidates = shrink_candidates(ShrinkPoint::{ x: 10, y: 20, }).collect()
  assert_true(candidates.length() > 0)
}
```

## FromJson and ToJson

`derive(FromJson)` and `derive(ToJson)` automatically generate round-trippable
trait implementations used for serializing the type to and from JSON. Trait
functions can be called with qualified syntax such as `ToJson::to_json(value)`.
The implementation is mainly for debugging and storing the types in a human-readable format.

```moonbit
struct JsonTest1 {
  x : Int
  y : Int
} derive(FromJson, ToJson, Eq)

pub extend JsonTest1 with @moonbitlang/core/json.FromJson::{from_json}

pub extend JsonTest1 with ToJson::{to_json}

pub extend JsonTest1 with Eq::{not_equal, equal}

enum JsonTest2 {
  A(x~ : Int)
  B(x~ : Int, y~ : Int)
} derive(FromJson(style="legacy"), ToJson(style="legacy"), Eq)

pub extend JsonTest2 with @moonbitlang/core/json.FromJson::{from_json}

pub extend JsonTest2 with ToJson::{to_json}

pub extend JsonTest2 with Eq::{not_equal, equal}

test "json basic" {
  let input = JsonTest1::{ x: 123, y: 456 }
  let expected : Json = { "x": 123, "y": 456 }
  @test.assert_eq(ToJson::to_json(input), expected)
  assert_true(@json.from_json(expected) == input)
  let input = JsonTest2::A(x=123)
  let expected : Json = { "$tag": "A", "x": 123 }
  @test.assert_eq(ToJson::to_json(input), expected)
  assert_true(@json.from_json(expected) == input)
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
)

pub extend JsonTest3 with @moonbitlang/core/json.FromJson::{from_json}

pub extend JsonTest3 with ToJson::{to_json}

pub extend JsonTest3 with Eq::{not_equal, equal}

enum JsonTest4 {
  A(x~ : Int)
  B(x~ : Int, y~ : Int)
} derive(FromJson, ToJson, Eq)

pub extend JsonTest4 with @moonbitlang/core/json.FromJson::{from_json}

pub extend JsonTest4 with ToJson::{to_json}

pub extend JsonTest4 with Eq::{not_equal, equal}

test "json args" {
  let input = JsonTest3::{ x: 123, y: 456 }
  let expected : Json = { "renamedX": 123, "y": 456 }
  @test.assert_eq(ToJson::to_json(input), expected)
  assert_true(@json.from_json(expected) == input)
  let input = JsonTest4::A(x=123)
  let expected : Json = ["A", { "x": 123 }]
  @test.assert_eq(ToJson::to_json(input), expected)
  assert_true(@json.from_json(expected) == input)
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

```none
E::One              => { "$tag": "One" }
E::Uniform(2)       => { "$tag": "Uniform", "0": 2 }
E::Axes(x=-1, y=1)  => { "$tag": "Axes", "x": -1, "y": 1 }
```

With `derive(ToJson(style="flat"))`, the enum is formatted into:

```none
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

pub extend A with ToJson::{to_json}

test {
  json_inspect({ x: None, y: None, z: (None, None) }, content={
    "z": [null, null],
  })
  json_inspect({ x: Some(1), y: Some(None), z: (Some(1), Some(None)) }, content={
    "x": 1,
    "y": null,
    "z": [[1], [null]],
  })
  json_inspect({ x: Some(1), y: Some(Some(1)), z: (Some(1), Some(Some(1))) }, content={
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
