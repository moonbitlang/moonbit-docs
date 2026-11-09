# Derive Attribute

Use `#derive(...)` before a type definition to generate implementations of
supported traits. Each field must satisfy the requirements of the derived
trait.

```{literalinclude} /sources/language/src/derive/debug.mbt
:language: moonbit
:start-after: start derive debug struct
:end-before: end derive debug struct
```

See [Deriving traits](/language/derive.md) for supported traits and their
options. `moon fmt` migrates the older trailing `derive(...)` syntax.
