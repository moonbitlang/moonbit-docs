# Deprecated Attribute

The `#deprecated` attribute is used to mark an API as deprecated. MoonBit emits
a warning when the deprecated API is used, and if the API is listed in completion,
it will be shown with a strikethrough style. For example:

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start deprecated
:end-before: end deprecated
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
