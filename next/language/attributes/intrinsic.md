# Intrinsic Attribute

`#intrinsic("name")` associates a function with a compiler intrinsic while
retaining an ordinary function body.

```{warning}
Intrinsics are not a stable API. They may change without notice and are not
recommended for application code. Prefer ordinary functions and public
standard-library APIs.
```

If the compiler does not recognize the name, it reports
[E0094](/language/error_codes/E0094.md), ignores the attribute, and uses the
ordinary function body. This is different from a direct intrinsic declaration
(`fn f(x : Int32) -> Int32 = "name"`), which has no ordinary body and reports
[E4070](/language/error_codes/E4070.md) for an unknown name.

Specifying multiple intrinsics for one function is not supported; see
[E4071](/language/error_codes/E4071.md).
