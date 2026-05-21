# Alert Attribute

The `#alert` attribute attaches a category and message to an API. When code uses
the API, MoonBit emits an alert warning.

```moonbit
#alert(unsafe, "This function is unsafe.")
fn[A] alert_unsafe_get(arr : Array[A], index : Int) -> A {
  arr[index]
}
```

The first argument is the alert category, and the second argument is the message
shown to users. The warning can be configured through warning names such as
`alert` and `alert_unsafe`.

For more detail, see [alert warning](../../toolchain/moon/package.md#alert-warning).
