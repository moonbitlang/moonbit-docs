# Documentation

## Doc Comments

Doc comments are comments prefix with `///` in each line in the leading of toplevel structure like `fn`, `let`, `enum`, `struct` or `type`. The doc comments are written in markdown.

```moonbit
/// Return a new array with reversed elements.
fn[T] reverse(xs : Array[T]) -> Array[T] {
  ...
}
```

Markdown code block inside docstring will be considered document test,
`moon check` and `moon test` will automatically check and run these tests, so that examples in docstring are always up-to-date.
MoonBit will automatically wrap a test block around document test,
so there is no need to wrap `test { .. }` around document test:

```moonbit
/// Increment an integer by one,
///
/// Example:
/// ```
/// inspect(incr(41), content="42")
/// ```
pub fn incr(x : Int) -> Int {
  x + 1
}
```

If you want to prevent a code snippet from being treated as document test,
mark it with a language id other than `mbt` on the markdown code block:

```moonbit
/// `c_incr(x)` is the same as the following C code:
/// ```c
/// x++
/// ```
pub fn c_incr(x : Ref[Int]) -> Int {
  let old = x.val
  x.val += 1
  old
}
```

Currently, document tests are always [blackbox tests](tests.md#blackbox-tests-and-whitebox-tests).
So private definitions cannot have document test.

## Attribute

Attributes are annotations placed before the top-level structure. They take the form `#attribute(...)`.
An attribute occupies the entire line, and newlines are not allowed within it.
Attributes do not normally affect the meaning of programs. Unused attributes will be reported as warnings.

### The Deprecated Attribute

The `#deprecated` attribute is used to mark a function, type, or trait as deprecated.
MoonBit emits a warning when the deprecated function or type is used in other packages.
You can customize the warning message by passing a string to the attribute.

For example:

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

### The Visibility Attribute

#### NOTE
This topic does not covered the access control. To lean more about `pub`, `pub(all)` and `priv`, see [Access Control](packages.md#access-control).

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

### The Internal Attribute

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

The alert warnings can be turn off by setting the `alert-list` in `moon.pkg.json`.
For more detail, see [Alert](../toolchain/moon/package.md#alert-list).

### The External Attribute

The `#external` attribute is used to mark an abstract type as external type.

- For Wasm(GC) backends, it would be interpreted as `anyref`.
- For JavaScript backend, it would be interpreted as `any`.
- For native backends, it would be interpreted as `void*`.

```moonbit
#external
type Ptr
```

### The Borrow and Owned Attribute

The `#borrow` and `#owned` attribute is used to indicate that a FFI takes ownership of its arguments. For more detail, see [FFI](ffi.md#the-borrow-and-owned-attribute).

### The As Free Function Attribute

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

### The Callsite Attribute

The `#callsite` attribute is used to mark properties that happen at callsite.

It could be `autofill`, which is to autofill the arguments [SourceLoc and ArgLoc](fundamentals.md#autofill-arguments)
at callsite.

It could also be used for migration, letting the downstream user adapt to the new calling convention:

```moonbit
#callsite(migration(y, fill=true, msg="must fill y for migration"), migration(z, fill=false, msg="cannot fill z for migration"))
fn f(x~ : Int, y? : Int = 42, z? : Int) -> Unit {
  ...
}
```

### The Skip Attribute

The `#skip` attribute is used to skip a single test block. The type checking will still be performed.

### The Configuration attribute

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
