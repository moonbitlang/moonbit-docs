# Coverage Skip Attribute

The `#coverage.skip` attribute skips coverage operations within a function.

```moonbit
#coverage.skip
fn platform_specific_helper() -> Unit {
  ()
}
```

Use it for functions that should not affect coverage reports, such as
platform-specific fallback code or code paths that are intentionally excluded
from coverage measurement. For more detail, see
[Skipping coverage](../../toolchain/moon/coverage.md#skipping-coverage).
