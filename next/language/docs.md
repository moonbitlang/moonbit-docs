# Documentation

## Doc Comments

Doc comments are comments prefix with `///` in each line in the leading of toplevel structure like `fn`, `let`, `enum`, `struct` or `type`. The doc comments are written in markdown.

```{literalinclude} /sources/language/src/misc/top.mbt
:language: moonbit
:start-after: start doc string 1
:end-before: end doc string 1

```

## Attribute

Attributes are annotations placed before the top-level structure. They take the form `#attribute(...)`. 
An attribute occupies the entire line, and newlines are not allowed within it. 
Attributes do not normally affect the meaning of programs. Unused attributes will be reported as warnings.

### The Deprecated Attribute

The `#deprecated` attribute is used to mark a function, type, or trait as deprecated. 
MoonBit emits a warning when the deprecated function or type is used in other packages. 
You can customize the warning message by passing a string to the attribute.

For example:

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start deprecated
:end-before: end deprecated
  ```

### The Visibility Attribute

```{note}
This topic does not covered the access control. To lean more about `pub`, `pub(all)` and `priv`, see [Access Control](./packages.md#access-control).
```

The `#visibility` attribute is similar to the `#deprecated` attribute, but it is used to hint that a type will change its visibility in the future. 
For outside usages, if the usage will be invalidated by the visibility change in future, a warning will be emitted. 

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start visibility
:end-before: end visibility
```

The `#visibility` attribute takes two arguments: `change_to` and `message`.

- The `change_to` argument is a string that indicates the new visibility of the type. It can be either `"abstract"` or `"readonly"`.

  | `change_to` | Invalidated Usages |
  |-------------|--------------------|
  | `"readonly"`  | Creating an instance of the type or mutating the fields of the instance. |
  | `"abstract"`  | Creating an instance of the type, mutating the fields of the instance, pattern matching, or accessing fields by label. |

- The `message` argument is a string that provides additional information about the visibility change.

### The Internal Attribute

The `#internal` attribute is used to mark a function, type, or trait as internal. 
Any usage of the internal function or type in other modules will emit an alert warning.

```{code-block} moonbit
:class: top-level
#internal(unsafe, "This is an unsafe function")
fn unsafe_get[A](arr : Array[A]) -> A {
  ...
}
```

The internal attribute takes two arguments: `category` and `message`. 
`category` is a identifier that indicates the category of the alert, and `message` is a string that provides additional message for the alert.

The alert warnings can be turn off by setting the `alert-list` in `moon.pkg.json`.
For more detail, see [Alert](../toolchain/moon/package.md#alert-list).

### The Borrow Attribute

The `#borrow` attribute is used to indicate that a FFI takes ownership of its arguments. For more detail, see [FFI](./ffi.md#The-borrow-attribute).


