# Configuration attribute

The `#cfg` attribute controls whether a declaration is included in compilation.
Conditions are evaluated at compile time and can use:

- `true` or `false` to always include or exclude a declaration.
- `target` to select a compilation backend, such as `target="wasm"`.
- `platform` to select an operating system for the native backend, such as
  `platform="windows"`.
- `not(...)`, `all(...)`, or `any(...)` to negate a condition, require all
  conditions, or require at least one condition.

#### WARNING
A `platform` condition currently also restricts the target to `native`. For
example, `platform="windows"` is equivalent to
`all(target="native", platform="windows")`.

This matters under negation: `not(platform="windows")` also matches every
non-native target. To select native builds other than Windows, use
`all(target="native", not(platform="windows"))`.

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

#cfg(platform="windows")
fn cfg_native_windows() -> Unit {
  ()
}

#cfg(not(platform="windows"))
fn cfg_except_native_windows() -> Unit {
  ()
}

#cfg(all(target="native", not(platform="windows")))
fn cfg_native_non_windows() -> Unit {
  ()
}

#cfg(any(target="wasm", target="native"))
fn cfg_any() -> Unit {
  ()
}
```
