# Must Implement One Attribute

The `#must_implement_one` attribute is used on traits to require that each
implementation explicitly defines at least one method, instead of relying only on
default method implementations.

Without arguments, at least one method of the trait must be explicitly
implemented:

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start must_implement_one any
:end-before: end must_implement_one any
```

With method names, at least one of the listed methods must be explicitly
implemented:

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start must_implement_one selected
:end-before: end must_implement_one selected
```

Multiple `#must_implement_one` attributes can be used on the same trait to
require explicit implementations from multiple method groups.
