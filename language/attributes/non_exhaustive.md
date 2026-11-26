# Non-exhaustive Enum Attribute

The `#non_exhaustive` attribute marks an `enum` or `suberror` whose defining
package may add constructors in a future release.

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

Adding a constructor to a `#non_exhaustive` type is therefore compatible with
downstream matches that use `Type::..`.

When matching a concrete non-exhaustive suberror type, the same `Type::..`
rule applies. When matching or catching the supertype `Error`, use `Type::_`
to cover that suberror type instead: `Type::..` is not supported there. See
[E4238](https://docs.moonbitlang.com/en/latest/language/error_codes/E4238.html).
