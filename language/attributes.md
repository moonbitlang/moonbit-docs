# Attribute

Attributes are annotations placed before structures in source code. They take the form `#attribute(...)`.
An attribute occupies the entire line, and newlines are not allowed within it.
Attributes do not normally affect the meaning of programs. Unused attributes will be reported as warnings.

The syntax of attributes is defined as follows:

```plaintext
attribute ::= '#' attribute-name
            | '#' attribute-name '(' attribute-arguments ')' 

attribute-name ::= LIDENT | LIDENT '.' LIDENT

attribute-arguments ::= attribute-argument (',' attribute-argument )*

attribute-argument ::= expr | LIDENT '=' expr 

expr ::= LIDENT | UIDENT | STRING | 'true' | 'false'
       | LIDENT '.' LIDENT
       | LIDENT '(' attribute-arguments ')'
       | LIDENT '.' LIDENT '(' attribute-arguments ')'
```

Attributes have two categories: the built-in attributes and user-defined attributes. For example:

```default
#deprecated("message")
#custom.attribute(key="value", flag=true)
```

The first attribute is a built-in attribute; it does not have a namespace prefix in the attribute name. Built-in attributes are recognized by the MoonBit compiler and have specific meanings.

The second attribute is a user-defined attribute; it has a namespace prefix `custom.` in the attribute name. User-defined attributes are ignored by the compiler, but can be used by external tools via parsing the source code.

#### NOTE
MoonBit is designed not to support runtime reflection. It's easy to abuse, making it impossible for toolchains (e.g., the compiler) to catch errors at compile time, which makes code harder to maintain. It also negatively impacts performance optimization.

We perfer to use compile-time code generation, keeping the benefits of static typing and performance (should also be used judiciously to avoid unnecessary complexity).

## Deprecated Attribute

The `#deprecated` attribute is used to mark an API as deprecated. MoonBit emits
a warning when the deprecated API is used, and if the API is listed in completion,
it will be shown with a strikethrough style. For example:

```moonbit
#deprecated
pub fn foo() -> Unit {
  ...
}

#deprecated("Use Bar2 instead")
pub(all) enum Bar {
  Ctor1
  Ctor2
}
```

The `#deprecated` attribute can be used in the following contexts:

- Top-level value declarations (including `fn`, `let`, and `const`)
- Top-level type declarations (including `type`, `struct`, and `enum`)
- Trait method declarations
- Trait default implementations

It has three forms:

- `#deprecated`

  Marks the item as deprecated with a default warning message.
- `#deprecated("Use new_function instead")`

  Marks the item as deprecated with a custom warning message. Every time the deprecated API is used, the provided message will be displayed as a warning.
- `#deprecated("Use new_function instead", skip_current_package=true)`

  Marks the item as deprecated with a custom warning message, but skips emitting warnings when the deprecated API is used within the same package.

## Alias Attribute

The `alias` attribute is used to overload operators related to indexing, or to create an alias name for a top-level function or variable. It has two forms:

- `#alias("op")`: where `op` is one of the following strings representing the indexing operators:
  - `_[_]`: for the indexing operator
  - `_[_]=_`: for the indexing assignment operator
  - `_[_:_]`: for the as view operator
- `#alias(id)`: where `id` is a identifier representing the alias name.

Both forms allowed additional arguments:

- `visibility="modifier"`

  A labeled argument, changes the visibility of the alias. The `modifier` can be `pub` or `priv`. If not specified, the alias will have the same visibility as the original function or variable.
- `deprecated` or `deprecated="message"`

  Marks the alias as deprecated. If a message is provided, it will be displayed as a warning when the alias is used.

To graceful migration from old API to new API, you can rename the old API directly, and create an alias with the old name, mark it as deprecated. For
example:

```moonbit
#alias("old_name", deprecated)
fn new_name() -> Unit {
  ...
}
```

## `label_migration` Attribute

The `#label_migration` attribute is used to help you safely evolve your API
by warning users during the transition period.

It has three following forms:

- `#label_migration(id, fill=true, msg="message")`

  The `fill` argument is used when you want to refactor an optional parameter.
  You can use `fill=true` when you want to eventually make an optional
  parameter required. You can use `fill=false` when you want to eventually
  remove an optional parameter.

  The `msg` argument is an string that provides additional information about the migration.
  ```moonbit
  #label_migration(x, fill=true)
  #label_migration(y, fill=false)
  fn f(x?: Int = 0, y?: Int = 1) -> Unit { ... }
  fn main {
    f(x=1, y=1) // warn on y being filled
    f()         // warn on x not being filled
  }
  ```
- `#label_migration(id, allow_positional=true, msg="message")`

  The `allow_positional` argument is used when you want a labelled parameter to be
  used without its label being provided. When the parameter is used positionally
  (without a label), the compiler reports a warning. This is useful when you want to change a positional parameter
  to a labelled parameter without breaking the downstream code.

  The `msg` argument is an string that provides additional information about the migration.
  ```moonbit
  #label_migration(x, allow_positional=true)
  fn f(x~: Int) -> Unit { ... }

  fn main {
    f(42) // warn on positional argument 42 used without label
  }
  ```
- `#label_migration(id, alias=new_id, msg="message")`

  The alias argument allows you to provide an alternative name to a labelled
  parameter. This is useful when renaming a parameter to maintain backward
  compatibility. If a warning message is provided, the compiler warns when
  using the alias; otherwise, the alias can be used without warnings.

  The `msg` argument is an string that provides additional information about the migration.
  ```moonbit
  #label_migration(x, alias=xx)
  #label_migration(x, alias=y, msg="warning")
  fn f(x~: Int) -> Unit { ... }

  fn main {
    f(xx=42) // no warning
    f(y=42)  // warning
  }
  ```

## Visibility Attribute

#### NOTE
This topic does not covered the access control. To learn more about `pub`, `pub(all)` and `priv`, see [Access Control](packages.md#access-control).

The `#visibility` attribute is similar to the `#deprecated` attribute, but it is used to hint that a type will change its visibility in the future.
For outside usages, if the usage will be invalidated by the visibility change in future, a warning will be emitted.

```moonbit
// in @util package
#visibility(change_to="readonly", "Point will be readonly in the future.")
pub(all) struct Point {
  x : Int
  y : Int
}

#visibility(change_to="abstract", "Use new_text and new_binary instead.")
pub(all) enum Resource {
  Text(String)
  Binary(Bytes)
}

pub fn new_text(str : String) -> Resource {
  ...
}

pub fn new_binary(bytes : Bytes) -> Resource {
  ...
}

// in another package
fn main {
  let p = Point::{ x: 1, y: 2 } // warning 
  let { x, y } = p // ok
  println(p.x) // ok
  match Resource::Text("") { // warning
    Text(s) => ... // waning
    Binary(b) => ... // warning
  }
}

```

The `#visibility` attribute takes two arguments: `change_to` and `message`.

- The `change_to` argument is a string that indicates the new visibility of the type. It can be either `"abstract"` or `"readonly"`.

  | `change_to`   | Invalidated Usages                                                                                                     |
  |---------------|------------------------------------------------------------------------------------------------------------------------|
  | `"readonly"`  | Creating an instance of the type or mutating the fields of the instance.                                               |
  | `"abstract"`  | Creating an instance of the type, mutating the fields of the instance, pattern matching, or accessing fields by label. |
- The `message` argument is a string that provides additional information about the visibility change.

## Internal Attribute

The `#internal` attribute is used to mark a function, type, or trait as internal.
Any usage of the internal function or type in other modules will emit an alert warning.

```moonbit
#internal(unsafe, "This is an unsafe function")
fn unsafe_get[A](arr : Array[A]) -> A {
  ...
}
```

The internal attribute takes two arguments: `category` and `message`.
`category` is a identifier that indicates the category of the alert, and `message` is a string that provides additional message for the alert.

The alert warnings can be turn off by setting the `warn-list` in `moon.pkg.json`.
For more detail, see [alert warning](../toolchain/moon/package.md#alert-warning).

## Warnings Attribute

The `#warnings` attribute is used to configure warning settings for a specific
top-level declaration. It can enable, disable or treat an enabled warning as error
for specific warnings in that declaration.

The argument is a string that specifies the warning list. It can contain multiple
warning names, each prefixed with a sign:

```moonbit
#warning("-unused_value@deprecated")
fn f() -> Unit {
  let x = 42 
}
```

The prefixes have the following meanings:

- `+warning_name`: enable the warning
- `-warning_name`: disable the warning
- `@warning_name`: treat a enabled warning as an error

Currently this attribute only works with some specific warnings.

To learn more about warning names, see [warning list](../toolchain/moon/package.md#warning-list).

## External Attribute

The `#external` attribute is used to mark an abstract type as external type.

- For Wasm(GC) backends, it would be interpreted as `anyref`.
- For JavaScript backend, it would be interpreted as `any`.
- For native backends, it would be interpreted as `void*`.

```moonbit
#external
type Ptr
```

## Borrow and Owned Attribute

The `#borrow` and `#owned` attribute is used to indicate that a FFI takes ownership of its arguments. For more detail, see [FFI](ffi.md#the-borrow-attribute).

## `as_free_fn` Attribute

The `#as_free_fn` attribute is used to mark a method that it is declared as a free function as well.
It can also change the visibility of the free function, the name of the free function, and provide separate deprecation warning.

```moonbit
#as_free_fn(dec, visibility="pub", deprecated="use `Int::decrement` instead")
#as_free_fn(visibility="pub")
fn Int::decrement(i : Self) -> Self {
  i - 1
}

test {
  let _ = decrement(10)
  let _ = (10).decrement()
}
```

## Callsite Attribute

The `#callsite` attribute is used to mark properties that happen at callsite.

It could be `autofill`, which is to autofill the arguments [SourceLoc and ArgLoc](fundamentals.md#autofill-arguments)
at callsite.

## Skip Attribute

The `#skip` attribute is used to skip a single test block. The type checking will still be performed.

## Configuration attribute

The `#cfg` attribute is used to perform conditional compilation. Examples are:

<!-- MANUAL CHECK -->
```moonbit
#cfg(true)
#cfg(false)
#cfg(target="wasm")
#cfg(not(target="wasm"))
#cfg(all(target="wasm", true))
#cfg(any(target="wasm", target="native"))
```

## Module attribute

The `module` attribute is used to declare the module dependency for JavaScript backend.

In `cjs` format, it is interpreted as `require`, and in `esm` format, it is interpreted as `import`.

<!-- MANUAL CHECK -->
```moonbit
#module("node:fs")
pub fn write_file_sync(file : String, data : String) = "writeFileSync"
```
