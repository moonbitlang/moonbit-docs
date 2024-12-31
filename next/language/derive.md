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

`derive(FromJson)` and `derive(ToJson)` will generate methods that deserializes/serializes the given type from/to
JSON files correspondingly.

```{literalinclude} /sources/language/src/derive/json.mbt
:language: moonbit
:start-after: start json basic
:end-before: end json basic
```

Both derive directives accept a number of arguments to configure the exact behavior of serialization and deserialization.

```{warning}
The actual behavior of JSON serialization arguments is unstable.
```

```{literalinclude} /sources/language/src/derive/json.mbt
:language: moonbit
:start-after: start json args
:end-before: end json args
```

### Enum representations

Enums can be represented in JSON in a number of styles.
There are two aspects of the representation:

- **Tag position** determines where the name of the enum tag (i.e. case or constructor name) is stored.
- **Case representation** determines how to represent the payload of the enum.

Let's consider the following enum definition:

```moonbit
enum E {
    Uniform(Int)
    Axes(x~: Int, y~: Int)
}
```

For tag position, there are 4 variants:

- **Internally tagged** puts the tag alongside the payload values:

  `{ "$tag": "Uniform", "0": 1 }`, `{ "$tag": "Axes", "x": 2, "y": 3 }`

- **Externally tagged** puts the tag as the JSON object key outside the payload values:

  `{ "Uniform": { "0": 1 } }`, `{ "Axes": { "x": 2, "y": 3 } }`

- **Adjacently tagged** puts the tag payload in two adjacent keys in a JSON object:

  `{ "t": "Uniform", "c": { "0": 1 } }`, `{ "t": "Axes", "c": { "x": 2, "y": 3 } }`

- **Untagged** has no explicit tag identifying which case the data is:

  `{ "0": 1 }`, `{ "x": 2, "y": 3 }`.

  The JSON deserializer will try to deserialize each case in order and return the first one succeeding.

For case representation, there are 2 variants:

- **Object-like** representation serializes enum payloads into a JSON object,
  whose key is either the tag name or the string of the positional index within the struct.

  `{ "0": 1 }`, `{ "x": 2, "y": 3 }`

- **Tuple-like** representation serializes enum payloads into a tuple (jSON array),
  in the same order as the type declaration.
  Labels are omitted in tuple-like representations.

  `[1]`, `[2, 3]`

The two aspects can be combined freely, except one case:
_internally tagged_ enums cannot use _tuple-like_ representation.

### Container arguments

- `repr(...)` configures the representation of the container.
  This controls the tag position of enums.
  For structs, the tag is assumed to be the type of the type.

  There are 4 representations available for selection:

  - `repr(tag = "tag")` –
    Use internally tagged representation,
    with the tag's object key name as specified.
  - `repr(untagged)` –
    Use untagged representation.
  - `repr(ext_tagged)` –
    Use externally tagged representation.
  - `repr(tag = "tag", contents = "contents")` –
    Use adjacently tagged representation,
    with the tag and contents key names as specified.

  The default representation for struct is `repr(untagged)`.

  The default representation for enums is `repr(tag = "$tag")`

- `case_repr(...)` (enum only) configures the case representation of the container.
  This option is only available on enums.

  - `case_repr(struct)` –
    Use struct-like representation of enums.

  - `case_repr(tuple)` –
    Use tuple-like representation of enums.

- `rename_fields`, `rename_cases` (enum only), `rename_struct` (struct only), `rename_all`
  renames fields, case names, struct name and all names correspondingly,
  into a specific style.

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
