# Must Implement One Attribute

The `#must_implement_one` attribute is used on traits to require that each
implementation explicitly defines at least one method, instead of relying only on
default method implementations.

Without arguments, at least one method of the trait must be explicitly
implemented:

```moonbit
#must_implement_one
pub(open) trait RequireAnyMethod {
  f(Self) -> Unit = _
  g(Self) -> Unit = _
}

impl RequireAnyMethod with f(_) {}

impl RequireAnyMethod with g(_) {}

type AnyImpl

impl RequireAnyMethod for AnyImpl with f(_) {}
```

With method names, at least one of the listed methods must be explicitly
implemented:

```moonbit
#must_implement_one(f, g)
pub(open) trait RequireSelectedMethod {
  f(Self) -> Unit = _
  g(Self) -> Unit = _
  h(Self) -> Unit = _
}

impl RequireSelectedMethod with f(_) {}

impl RequireSelectedMethod with g(_) {}

impl RequireSelectedMethod with h(_) {}

type SelectedImpl

impl RequireSelectedMethod for SelectedImpl with g(_) {}
```

Multiple `#must_implement_one` attributes can be used on the same trait to
require explicit implementations from multiple method groups.
