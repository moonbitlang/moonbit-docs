# Configuration attribute

The `#cfg` attribute controls whether a declaration is included in compilation.
Conditions are evaluated at compile time and can use:

- `true` or `false` to always include or exclude a declaration.
- `target` to select a compilation backend, such as `target="wasm"`.
- `platform` to select an operating system, such as `platform="windows"`.
- `not(...)`, `all(...)`, or `any(...)` to negate a condition, require all
  conditions, or require at least one condition.

For example, `not(platform="windows")` includes a declaration on non-Windows
platforms, while `all(target="native", platform="windows")` includes it only for
the native backend on Windows.

<!-- MANUAL CHECK -->

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start cfg
:end-before: end cfg
```
