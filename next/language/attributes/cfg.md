# Configuration attribute

The `#cfg` attribute controls whether a declaration is included in compilation.
Conditions are evaluated at compile time and can use:

- `true` or `false` to always include or exclude a declaration.
- `target` to select a compilation backend, such as `target="wasm"`.
- `platform` to select an operating system for the native backend, such as
  `platform="windows"`.
- `not(...)`, `all(...)`, or `any(...)` to negate a condition, require all
  conditions, or require at least one condition.

```{warning}
A `platform` condition currently also restricts the target to `native`. For
example, `platform="windows"` is equivalent to
`all(target="native", platform="windows")`.

This matters under negation: `not(platform="windows")` also matches every
non-native target. To select native builds other than Windows, use
`all(target="native", not(platform="windows"))`.
```

<!-- MANUAL CHECK -->

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start cfg
:end-before: end cfg
```
