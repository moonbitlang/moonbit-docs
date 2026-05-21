# Visibility Attribute

```{note}
This topic does not covered the access control. To learn more about `pub`, `pub(all)` and `priv`, see [Access Control](/language/packages.md#access-control).
```

The `#visibility` attribute is similar to the `#deprecated` attribute, but it is used to hint that a type will change its visibility in the future.
For outside usages, if the usage will be invalidated by the visibility change in future, a warning will be emitted.

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start visibility
:end-before: end visibility
```

The `#visibility` attribute takes a required `change_to` argument and an
optional `message` argument.

- The `change_to` argument is a string that indicates the new visibility of the type. It can be either `"abstract"` or `"readonly"`.

  | `change_to` | Invalidated Usages |
  |-------------|--------------------|
  | `"readonly"`  | Creating an instance of the type or mutating the fields of the instance. |
  | `"abstract"`  | Creating an instance of the type, mutating the fields of the instance, pattern matching, or accessing fields by label. |

- The optional `message` argument is a string that provides additional information about the visibility change.
