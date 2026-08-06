# Unsafe Cycle-Free Attribute

The `#unsafe_cycle_free` attribute is an advanced optimization assertion for a
struct, enum, or newtype declaration. It tells the compiler that no value of
the annotated type will ever participate in a reference cycle. The compiler
trusts this assertion during cycle-capability analysis and does not verify it.

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start unsafe cycle free
:end-before: end unsafe cycle free
```

```{danger}
Use this attribute only when the cycle-free invariant is guaranteed by the
program. An incorrect assertion can cause reference cycles involving the type
to be treated as impossible and therefore not reclaimed.
```
