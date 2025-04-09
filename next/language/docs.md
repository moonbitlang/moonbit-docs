# Documentation

## Doc Comments

Doc comments are comments prefix with `///` in each line in the leading of toplevel structure like `fn` , `let` , `enum` , `struct` , `type` . The doc comments contains a markdown text and several pragmas.

```{literalinclude} /sources/language/src/misc/top.mbt
:language: moonbit
:start-after: start doc string 1
:end-before: end doc string 1

```

## Attribute

Attributes are annotations placed before the top-level structure. They take the form `#attribute ...`. 
An attribute occupies the entire line, and newlines are not allowed within it. Attributes do not normally affect the meaning of programs. Unused attributes will be reported as warnings.

- Deprecated Attribute

The deprecated attribute is used to mark a function, type or trait as deprecated. 
MoonBit will emit a warning when the deprecated function or type is used. The message can be customized by passing a string literal to the attribute.

For example:

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start deprecated
:end-before: end deprecated
```

- Visibility Change Attribute

The `#visibility` attribute is similar to the `#deprecated` attribute, but it is used to hint
that a type will change its visibility in the future. For outside usages, if the usage will 
be invalidated by the visibility change in future, a warning will be emitted. 


```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start visibility
:end-before: end visibility
```

The `visibility` attribute takes two arguments: `change_to` and `message`.

- The `change_to` argument is a string that indicates the new visibility of the type. It can be either `abstract` or `readonly`.

  | `change_to` | Invalidated Usages |
  |-------------|--------------------|
  | `readonly`  | Creating an instance of the type or mutating the fields of the instance. |
  | `abstract`  | Creating an instance of the type, mutating the fields of the instance, pattern matching, or accessing fields by label. |

- The `message` argument is a string that provides additional information about the visibility change.

