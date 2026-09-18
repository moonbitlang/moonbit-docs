# Non-exhaustive Enum Attribute

The `#non_exhaustive` attribute marks an `enum` whose defining package may add
constructors in a future release. It is valid only on enum declarations.

```moonbit
///|
#non_exhaustive
pub(all) enum Response {
  Ok(String)
  NotFound
}
```

Code outside the defining package must handle potential future constructors
with a `Type::..` pattern:

```moonbit
///|
pub fn render(response : @base.Response) -> String {
  match response {
    @base.Ok(body) => body
    @base.NotFound => "not found"
    @base.Response::.. => "unsupported response"
  }
}
```

The `Type::..` pattern is specifically for forward compatibility. It does not
replace the enum's currently known constructors: match those constructors
explicitly before this pattern. A wildcard pattern (`_`) is not a substitute
for `Type::..` when handling constructors added by a future version of the
defining package.

Adding a constructor to a `#non_exhaustive` enum is therefore compatible with
downstream matches that use `Type::..`.
