# Proof External Attribute

The `#proof_external(module, symbol)` attribute tells verification lowering to
represent an abstract MoonBit type with a type from a Why3 module.

```moonbit
///|
#proof_external("set.Fset", "fset")
pub type ProofSet[T]
```

In this example, occurrences of `ProofSet[T]` in proof-oriented logic are
lowered to the Why3 type `set.Fset.fset T`. The attribute does not implement the
MoonBit type, provide runtime values, or connect the type to an FFI ABI.

The module and symbol mapping is part of the trusted verification boundary. For
the corresponding operation imports and proof example, see
[Formal Verification](https://docs.moonbitlang.com/en/latest/language/verification.html#proof-specific-annotations).
