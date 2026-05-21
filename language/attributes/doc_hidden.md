# Doc Hidden Attribute

The `#doc(hidden)` attribute hides an API from generated documentation.

```moonbit
#doc(hidden)
pub fn hidden_helper() -> Unit {
  ()
}
```

Use it for public declarations that must remain available to code but should not
be shown as part of the documented API surface.
