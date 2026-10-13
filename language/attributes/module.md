# Module attribute

The `module` attribute is used to declare the module dependency for JavaScript backend.

In `cjs` format, it is interpreted as `require`, and in `esm` format, it is interpreted as `import`.

<!-- MANUAL CHECK -->
```moonbit
#module("math-utils")
pub extern "js" fn add_from_module(x : Int32, y : Int32) -> Int32 = "add"
```
