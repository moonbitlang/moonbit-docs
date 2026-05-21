# Internal Attribute

The `#internal` attribute is used to mark a function, type, or trait as internal.
Any usage of the internal function or type in other modules will emit an alert warning.

```moonbit
#internal(unsafe, "This is an unsafe function")
fn[A] internal_unsafe_get(arr : Array[A], index : Int) -> A {
  arr[index]
}
```

The internal attribute takes a required `category` argument and an optional
`message` argument. `category` is a identifier that indicates the category of
the alert, and `message` is a string that provides additional message for the
alert.

The alert warnings can be turn off by setting the `warn-list` in `moon.pkg`.
For more detail, see [alert warning](../../toolchain/moon/package.md#alert-warning).
