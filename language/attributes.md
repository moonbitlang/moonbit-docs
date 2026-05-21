# Attribute

Attributes are annotations placed before structures in source code. They take the form `#attribute(...)`.
An attribute occupies the entire line, and newlines are not allowed within it.
Attributes do not normally affect the meaning of programs. Unused attributes will be reported as warnings.

The syntax of attributes is defined as follows:

```text
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

Common forms include:

- `#deprecated`

  Marks the item as deprecated with a default warning message.
- `#deprecated("Use new_function instead")`

  Marks the item as deprecated with a custom warning message. Every time the deprecated API is used, the provided message will be displayed as a warning.
- `#deprecated("Use new_function instead", skip_current_package=true)`

  Marks the item as deprecated with a custom warning message, but skips emitting warnings when the deprecated API is used within the same package.
- `#deprecated(skip_current_package=true)`

  Marks the item as deprecated with a default warning message, but skips emitting warnings within the same package. When both a message and `skip_current_package` are present, either argument order is accepted.

## Alert Attribute

The `#alert` attribute attaches a category and message to an API. When code uses
the API, MoonBit emits an alert warning.

```moonbit
#alert(unsafe, "This function is unsafe.")
fn[A] alert_unsafe_get(arr : Array[A], index : Int) -> A {
  arr[index]
}
```

The first argument is the alert category, and the second argument is the message
shown to users. The warning can be configured through warning names such as
`alert` and `alert_unsafe`.

For more detail, see [alert warning](../toolchain/moon/package.md#alert-warning).

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
#alias(old_name, deprecated)
fn new_name() -> Unit {
  ()
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
  fn label_migration_fill(x? : Int = 0, y? : Int = 1) -> Int {
    x + y
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
  fn label_migration_allow_positional(x~ : Int) -> Int {
    x
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
  fn label_migration_alias(x~ : Int) -> Int {
    x
  }
  ```

## Visibility Attribute

#### NOTE
This topic does not covered the access control. To learn more about `pub`, `pub(all)` and `priv`, see [Access Control](packages.md#id1).

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

The `#visibility` attribute takes a required `change_to` argument and an
optional `message` argument.

- The `change_to` argument is a string that indicates the new visibility of the type. It can be either `"abstract"` or `"readonly"`.

  | `change_to`   | Invalidated Usages                                                                                                     |
  |---------------|------------------------------------------------------------------------------------------------------------------------|
  | `"readonly"`  | Creating an instance of the type or mutating the fields of the instance.                                               |
  | `"abstract"`  | Creating an instance of the type, mutating the fields of the instance, pattern matching, or accessing fields by label. |
- The optional `message` argument is a string that provides additional information about the visibility change.

## Internal Attribute

The `#internal` attribute is used to mark a function, type, or trait as internal.
Any usage of the internal function or type in other modules will emit an alert warning.

```moonbit
#internal(unsafe, "This is an unsafe function")
fn[A] internal_unsafe_get(arr : Array[A], index : Int) -> A {
  arr[index]
}
```

The internal attribute takes a required `category` argument and an optional
`message` argument. `category` is a identifier that indicates the category of
the alert, and `message` is a string that provides additional message for the
alert.

The alert warnings can be turn off by setting the `warn-list` in `moon.pkg`.
For more detail, see [alert warning](../toolchain/moon/package.md#alert-warning).

## Doc Hidden Attribute

The `#doc(hidden)` attribute hides an API from generated documentation.

```moonbit
#doc(hidden)
pub fn hidden_helper() -> Unit {
  ()
}
```

Use it for public declarations that must remain available to code but should not
be shown as part of the documented API surface.

## Warnings Attribute

The `#warnings` attribute is used to configure warning settings for a specific
top-level declaration. It can enable, disable or treat an enabled warning as error
for specific warnings in that declaration.

The argument is a string that specifies the warning list. It can contain multiple
warning names, each prefixed with a sign:

```moonbit
#warnings("-unused_value")
fn warnings_example() -> Unit {
  let x = 42
}
```

The prefixes have the following meanings:

- `+warning_name`: enable the warning
- `-warning_name`: disable the warning
- `@warning_name`: treat a enabled warning as an error

Currently this attribute only works with some specific warnings.

To learn more about warning names, see [warning list](../toolchain/moon/package.md#warnings-list).

## Must Implement One Attribute

The `#must_implement_one` attribute is used on traits to require that each
implementation explicitly defines at least one method, instead of relying only on
default method implementations.

Without arguments, at least one method of the trait must be explicitly
implemented:

```moonbit
#must_implement_one
pub(open) trait RequireAnyMethod {
  f(Self) -> Unit = _
  g(Self) -> Unit = _
}

impl RequireAnyMethod with f(_) {}

impl RequireAnyMethod with g(_) {}

type AnyImpl

impl RequireAnyMethod for AnyImpl with f(_) {}
```

With method names, at least one of the listed methods must be explicitly
implemented:

```moonbit
#must_implement_one(f, g)
pub(open) trait RequireSelectedMethod {
  f(Self) -> Unit = _
  g(Self) -> Unit = _
  h(Self) -> Unit = _
}

impl RequireSelectedMethod with f(_) {}

impl RequireSelectedMethod with g(_) {}

impl RequireSelectedMethod with h(_) {}

type SelectedImpl

impl RequireSelectedMethod for SelectedImpl with g(_) {}
```

Multiple `#must_implement_one` attributes can be used on the same trait to
require explicit implementations from multiple method groups.

## Inline Attribute

The `#inline` attribute is an optimization hint for a function. It asks the
compiler to inline the function when possible:

```moonbit
#inline
fn add_one(x : Int) -> Int {
  x + 1
}
```

Use `#inline(never)` to ask the compiler not to inline a function:

```moonbit
#inline(never)
fn keep_stack_frame(x : Int) -> Int {
  x + 1
}
```

These attributes are hints. They do not change the source-level behavior of the
function.

## External Attribute

The `#external` attribute is used to mark an abstract type as external type.

- For Wasm and Wasm GC backends, it would be interpreted as `externref`.
- For JavaScript backend, it would be interpreted as `any`.
- For native backends, it would be interpreted as `void*`.

```moonbit
#external
type AttrPtr
```

## Borrow and Owned Attribute

The `#borrow` and `#owned` attribute is used to indicate that a FFI takes ownership of its arguments. For more detail, see [FFI](ffi.md#the-borrow-and-owned-attribute).

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

It could be `autofill`, which is to autofill the arguments [SourceLoc and ArgLoc](fundamentals.md#id1)
at callsite.

## Skip Attribute

The `#skip` attribute is used to skip a single test block. It can be written as
`#skip` or with a reason, such as `#skip("blocked by external service")`. The
type checking will still be performed.

## Coverage Skip Attribute

The `#coverage.skip` attribute skips coverage operations within a function.

```moonbit
#coverage.skip
fn platform_specific_helper() -> Unit {
  ()
}
```

Use it for functions that should not affect coverage reports, such as
platform-specific fallback code or code paths that are intentionally excluded
from coverage measurement. For more detail, see
[Skipping coverage](../toolchain/moon/coverage.md#skipping-coverage).

## Configuration attribute

The `#cfg` attribute is used to perform conditional compilation. Examples are:

<!-- MANUAL CHECK -->
```moonbit
#cfg(true)
fn cfg_true() -> Unit {
  ()
}

#cfg(false)
fn cfg_false() -> Unit {
  ()
}

#cfg(target="wasm")
fn cfg_wasm() -> Unit {
  ()
}

#cfg(not(target="wasm"))
fn cfg_not_wasm() -> Unit {
  ()
}

#cfg(all(target="wasm", true))
fn cfg_all() -> Unit {
  ()
}

#cfg(any(target="wasm", target="native"))
fn cfg_any() -> Unit {
  ()
}
```

## Module attribute

The `module` attribute is used to declare the module dependency for JavaScript backend.

In `cjs` format, it is interpreted as `require`, and in `esm` format, it is interpreted as `import`.

<!-- MANUAL CHECK -->
```moonbit
#module("math-utils")
pub extern "js" fn add_from_module(x : Int, y : Int) -> Int = "add"
```
