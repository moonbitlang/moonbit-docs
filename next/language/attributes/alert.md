# Alert Attribute

The `#alert` attribute attaches a category and message to an API. When code uses
the API, MoonBit emits an alert warning.

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start alert
:end-before: end alert
```

The first argument is the alert category, and the second argument is the message
shown to users. The warning can be configured through warning names such as
`alert` and `alert_unsafe`.

For more detail, see [alert warning](/toolchain/moon/package.md#alert-warning).
