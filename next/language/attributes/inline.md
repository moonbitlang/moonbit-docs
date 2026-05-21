# Inline Attribute

The `#inline` attribute is an optimization hint for a function. It asks the
compiler to inline the function when possible:

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start inline default
:end-before: end inline default
```

Use `#inline(never)` to ask the compiler not to inline a function:

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start inline never
:end-before: end inline never
```

These attributes are hints. They do not change the source-level behavior of the
function.
