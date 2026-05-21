# Warnings Attribute

The `#warnings` attribute is used to configure warning settings for a specific
top-level declaration. It can enable, disable or treat an enabled warning as error
for specific warnings in that declaration.

The argument is a string that specifies the warning list. It can contain multiple
warning names, each prefixed with a sign:

```moonbit
#warnings("-unused_value")
fn warnings_example() -> Unit {
  let x = 42
}
```

The prefixes have the following meanings:

- `+warning_name`: enable the warning
- `-warning_name`: disable the warning
- `@warning_name`: treat a enabled warning as an error

Currently this attribute only works with some specific warnings.

To learn more about warning names, see [warning list](../../toolchain/moon/package.md#warnings-list).
