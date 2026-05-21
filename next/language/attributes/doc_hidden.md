# Doc Hidden Attribute

The `#doc(hidden)` attribute hides an API from generated documentation.

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start doc hidden
:end-before: end doc hidden
```

Use it for public declarations that must remain available to code but should not
be shown as part of the documented API surface.
